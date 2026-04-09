-- [[ KYBROND CORE V30.4 - TOTAL BLACKOUT - CUSTOM WARNING ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- [[ 0. TẠO MÀN HÌNH ĐEN TUYỀN VỚI LỜI CẢNH BÁO "GẮT" ]]
local function CreateBlackScreen()
    local oldGui = Player:WaitForChild("PlayerGui"):FindFirstChild("KybrondBlackout")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    local BlackFrame = Instance.new("Frame")

    ScreenGui.Name = "KybrondBlackout"
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.DisplayOrder = 9999 

    BlackFrame.Name = "MainOverlay"
    BlackFrame.Size = UDim2.new(1, 0, 1, 0)
    BlackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
    BlackFrame.BackgroundTransparency = 0 
    BlackFrame.BorderSizePixel = 0
    BlackFrame.Parent = ScreenGui

    -- Dòng chữ cảnh báo theo yêu cầu của bạn
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Text = "May nhin hong moc mat may ra gio"
    StatusLabel.Size = UDim2.new(1, 0, 0, 50)
    StatusLabel.Position = UDim2.new(0, 0, 0.45, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ cảnh báo
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 30 -- Tăng kích thước chữ cho dễ đọc
    StatusLabel.Parent = BlackFrame
end

-- Kích hoạt màn hình đen
CreateBlackScreen()

-- [[ 1 & 2. DANH SÁCH MỤC TIÊU (Giữ nguyên logic gốc) ]]
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

-- [[ CẤU HÌNH CHIẾN ĐẤU ]]
local HeightOffset = 10 
local SkillDelay = 0.1   
local MyCurrentLocation = ""

local AbilityRemote = ReplicatedStorage:FindFirstChild("AbilitySystem") 
    and ReplicatedStorage.AbilitySystem:FindFirstChild("Remotes") 
    and ReplicatedStorage.AbilitySystem.Remotes:FindFirstChild("RequestAbility")
local TeleportRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TeleportToPortal")

-- [[ MODULES TỐI ƯU ]]
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
    warn("!!! KYBROND V30.4 - CUSTOM ALERT ACTIVE !!!")
    
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
