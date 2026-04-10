-- [[ KYBROND CORE V31.1 - MOB ONLY - PERMANENT BLACKOUT - IMMORTAL LOOP ]]

-- 1. KIỂM TRA TRẠNG THÁI LOAD GAME
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

-- Chờ PlayerGui sẵn sàng
Player:WaitForChild("PlayerGui")
task.wait(2) 

-- [[ 3. LOGIC ANTI-AFK ]]
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- [[ 0. TẠO MÀN HÌNH ĐEN VĨNH VIỄN (FIX RESET ON SPAWN) ]]
local function CreateBlackScreen()
    local oldGui = Player.PlayerGui:FindFirstChild("KybrondBlackout")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    local BlackFrame = Instance.new("Frame")

    ScreenGui.Name = "KybrondBlackout"
    ScreenGui.Parent = Player.PlayerGui
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.DisplayOrder = 9999 
    ScreenGui.ResetOnSpawn = false 

    BlackFrame.Name = "MainOverlay"
    BlackFrame.Size = UDim2.new(1, 0, 1, 0)
    BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
    BlackFrame.BackgroundTransparency = 0 -- Giữ nguyên độ đen theo ý bạn
    BlackFrame.BorderSizePixel = 0
    BlackFrame.Parent = ScreenGui

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Text = "May nhin hong moc mat may ra gio"
    StatusLabel.Size = UDim2.new(1, 0, 0, 50)
    StatusLabel.Position = UDim2.new(0, 0, 0.45, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0) 
    StatusLabel.Font = Enum.Font.SourceSansBold
    StatusLabel.TextSize = 30 
    StatusLabel.Parent = BlackFrame
end

CreateBlackScreen()

-- [[ 1. DANH SÁCH QUÁI (Đã loại bỏ Boss) ]]
local MobList = {"Swordsman4", "ArenaFighter2", "Ninja4", "Slime3", "Quincy4"}

-- [[ 2. MAPPING ĐẢO ]]
local LocationMapping = {
    ["Swordsman4"]           = "Judgement",
    ["ArenaFighter2"]        = "Lawless",
    ["Ninja4"]               = "Ninja",
    ["Slime3"]               = "Slime",
    ["Quincy4"]              = "SoulDominion"
}

-- [[ CẤU HÌNH ]]
local HeightOffset = 7 
local SkillDelay = 0.1   
local MyCurrentLocation = ""

local AbilityRemote = ReplicatedStorage:FindFirstChild("AbilitySystem") 
    and ReplicatedStorage.AbilitySystem:FindFirstChild("Remotes") 
    and ReplicatedStorage.AbilitySystem.Remotes:FindFirstChild("RequestAbility")
local TeleportRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TeleportToPortal")

-- [[ MODULES ]]
local function CheckAndEquipTool()
    local char = Player.Character
    if char and not char:FindFirstChildOfClass("Tool") then
        local bp = Player:FindFirstChild("Backpack")
        local tool = bp and bp:FindFirstChildOfClass("Tool")
        if tool then char.Humanoid:EquipTool(tool) end
    end
end

RunService.Stepped:Connect(function()
    local char = Player.Character
    if char then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- [[ VÒNG LẶP CHÍNH - MOB ONLY ]]
task.spawn(function()
    warn("!!! KYBROND V31.1 - MOB ONLY FARMING ACTIVE !!!")
    
    while true do
        task.wait(0.2)
        
        local char = Player.Character or Player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local root = char:WaitForChild("HumanoidRootPart")
        
        if humanoid.Health <= 0 then 
            MyCurrentLocation = "" 
            continue 
        end

        -- Chỉ duyệt qua danh sách quái
        for _, mobName in ipairs(MobList) do
            local target = workspace.NPCs:FindFirstChild(mobName) or workspace:FindFirstChild(mobName, true)
            
            if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
                local targetIsland = LocationMapping[mobName]
                
                -- Teleport đảo
                if targetIsland and targetIsland ~= MyCurrentLocation then
                    if TeleportRemote then
                        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        TeleportRemote:FireServer(targetIsland)
                        MyCurrentLocation = targetIsland
                        task.wait(0.5) 
                    end
                end

                local tRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                if not tRoot then continue end

                CheckAndEquipTool()

                local hover = root:FindFirstChild("KybrondHover") or Instance.new("BodyVelocity")
                hover.Name = "KybrondHover"; hover.MaxForce = Vector3.new(9e9, 9e9, 9e9); hover.Parent = root
                hover.Velocity = Vector3.new(0,0,0)

                -- Vòng lặp chiến đấu với quái
                while target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
                    if humanoid.Health <= 0 then break end
                    
                    local currentTRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                    if currentTRoot then
                        root.CFrame = currentTRoot.CFrame * CFrame.new(0, HeightOffset, 0)
                        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        CheckAndEquipTool()
                        if AbilityRemote then AbilityRemote:FireServer(2) end
                    else
                        break 
                    end
                    task.wait(SkillDelay)
                    -- Đã loại bỏ logic check Boss (BossCheck) ở đây để tập trung farm quái
                end
                break 
            end
        end
    end
end)
