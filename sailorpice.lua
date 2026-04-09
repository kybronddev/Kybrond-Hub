-- [[ KYBROND CORE V30.8 - ANTI-KICK - AUTOEXEC - STABLE LOAD ]]

-- 1. KIỂM TRA TRẠNG THÁI LOAD GAME
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

-- 2. LOGIC CHỜ PLAYER VÀ THỜI GIAN ĐỆM (Safety Buffer)
local Player = Players.LocalPlayer
while not Player do
    task.wait(0.5) -- Tăng thời gian chờ check Player lên 0.5s để giảm tải CPU lúc đầu
    Player = Players.LocalPlayer
end

Player:WaitForChild("PlayerGui")
task.wait(3) -- TĂNG THÊM 3 GIÂY chờ ổn định toàn bộ dữ liệu map và NPCs

-- [[ 3. LOGIC ANTI-AFK (CHỐNG KICK 20 PHÚT) ]]
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    warn("!!! KYBROND ANTI-AFK: DISCONNECT PREVENTED !!!")
end)

-- [[ 0. TẠO MÀN HÌNH ĐEN TUYỀN VỚI LỜI CẢNH BÁO ]]
local function CreateBlackScreen()
    local oldGui = Player.PlayerGui:FindFirstChild("KybrondBlackout")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    local BlackFrame = Instance.new("Frame")

    ScreenGui.Name = "KybrondBlackout"
    ScreenGui.Parent = Player.PlayerGui
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.DisplayOrder = 9999 

    BlackFrame.Name = "MainOverlay"
    BlackFrame.Size = UDim2.new(1, 0, 1, 0)
    BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
    BlackFrame.BackgroundTransparency = 0.4 
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

-- [[ 1 & 2. DANH SÁCH MỤC TIÊU ]]
local BossList = {"StrongestShinobiBoss", "AizenBoss", "YujiBoss", "GojoBoss", "SukunaBoss", "JinwooBoss", "YamatoBoss"}
local MobList = {"Swordsman4", "ArenaFighter2", "Ninja4", "Slime3", "Quincy4"}

local StaticPriorityList = {}
for _, b in ipairs(BossList) do table.insert(StaticPriorityList, {name = b, type = "Boss"}) end
for _, m in ipairs(MobList) do table.insert(StaticPriorityList, {name = m, type = "Mob"}) end

local LocationMapping = {
    ["StrongestShinobiBoss"] = "Ninja", ["AizenBoss"] = "HollowIsland", ["YujiBoss"] = "Shibuya",
    ["GojoBoss"] = "Shibuya", ["SukunaBoss"] = "Shibuya", ["JinwooBoss"] = "Sailor",
    ["YamatoBoss"] = "Judgement", ["Swordsman4"] = "Judgement", ["ArenaFighter2"] = "Lawless",
    ["Ninja4"] = "Ninja", ["Slime3"] = "Slime", ["Quincy4"] = "SoulDominion"
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
    if Player.Character then
        for _, part in ipairs(Player.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- [[ VÒNG LẶP CHÍNH ]]
task.spawn(function()
    warn("!!! KYBROND V30.8 - STABLE LOAD ACTIVE !!!")
    
    while true do
        task.wait(0.2)
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        for _, entry in ipairs(StaticPriorityList) do
            local name = entry.name
            local target = workspace.NPCs:FindFirstChild(name) or workspace:FindFirstChild(name, true)
            
            if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
                local targetIsland = LocationMapping[name]
                
                if targetIsland and targetIsland ~= MyCurrentLocation then
                    if TeleportRemote then
                        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        TeleportRemote:FireServer(targetIsland)
                        MyCurrentLocation = targetIsland
                        task.wait(0.3) 
                    end
                end

                local tRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                if not tRoot then continue end

                CheckAndEquipTool()

                local hover = root:FindFirstChild("KybrondHover")
                if not hover then
                    hover = Instance.new("BodyVelocity")
                    hover.Name = "KybrondHover"; hover.MaxForce = Vector3.new(9e9, 9e9, 9e9); hover.Parent = root
                end
                hover.Velocity = Vector3.new(0,0,0)

                while target and target.Parent and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 do
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

                    if entry.type == "Mob" then
                        local hasBoss = false
                        for _, bName in ipairs(BossList) do
                            local b = workspace.NPCs:FindFirstChild(bName)
                            if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then
                                hasBoss = true; break
                            end
                        end
                        if hasBoss then break end 
                    end
                end
                break 
            end
        end
    end
end)
