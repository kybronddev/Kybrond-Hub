-- [[ KYBROND CORE V30.1 - NO ANTI-PAUSE - FULL TARGETS ]]
local Player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. DANH SÁCH BOSS
local BossList = {
    "StrongestShinobiBoss", "AizenBoss", "YujiBoss", 
    "GojoBoss", "SukunaBoss", "JinwooBoss", "YamatoBoss"
}

-- 2. DANH SÁCH QUÁI (Update V29.4)
local MobList = {
    "Swordsman4", "ArenaFighter2", "Ninja4", "Slime3", "Quincy4"
}

-- 3. MAPPING ĐẢO CHUẨN (SoulDominion, No Academy)
local LocationMapping = {
    ["StrongestShinobiBoss"] = "Ninja",
    ["AizenBoss"]            = "HollowIsland",
    ["YujiBoss"]             = "Shibuya",
    ["GojoBoss"]             = "Shibuya",
    ["SukunaBoss"]           = "Shibuya",
    ["JinwooBoss"]           = "Sailor",
    ["YamatoBoss"]           = "Judgement",
    ["Swordsman4"]           = "Judgement",
    ["ArenaFighter2"]        = "Lawless",
    ["Ninja4"]               = "Ninja",
    ["Slime3"]               = "Slime",
    ["Quincy4"]              = "SoulDominion"
}

-- 4. CẤU HÌNH CHIẾN ĐẤU
local HeightOffset = 10 
local SkillDelay = 0.1   
local MyCurrentLocation = ""

-- [[ 5. MODULE TỰ ĐỘNG TRANG BỊ VŨ KHÍ (V29.5) ]]
local function CheckAndEquipTool()
    local Character = Player.Character
    if Character and not Character:FindFirstChildOfClass("Tool") then
        local Backpack = Player:FindFirstChild("Backpack")
        if Backpack then
            local Items = Backpack:GetChildren()
            if Items[1] and Items[1]:IsA("Tool") then
                Character.Humanoid:EquipTool(Items[1])
            end
        end
    end
end

-- [[ 6. LOGIC NOCLIP ]]
RunService.Stepped:Connect(function()
    if Player.Character then
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

-- [[ 7. HÀM SỬ DỤNG SKILL ]]
local function UseSkillRemote()
    local skillRemote = ReplicatedStorage:FindFirstChild("AbilitySystem") 
        and ReplicatedStorage.AbilitySystem:FindFirstChild("Remotes") 
        and ReplicatedStorage.AbilitySystem.Remotes:FindFirstChild("RequestAbility")
    if skillRemote then skillRemote:FireServer(2) end
end

-- [[ 8. VÒNG LẶP CHÍNH - NO ANTI-PAUSE ]]
task.spawn(function()
    warn("!!! KYBROND V30.1 - ANTI-PAUSE REMOVED - FULL SPEED !!!")
    
    while true do
        task.wait(0.2)
        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        -- Danh sách ưu tiên
        local PriorityList = {}
        for _, b in pairs(BossList) do table.insert(PriorityList, {name = b, type = "Boss"}) end
        for _, m in pairs(MobList) do table.insert(PriorityList, {name = m, type = "Mob"}) end

        for _, entry in pairs(PriorityList) do
            local name = entry.name
            local targetType = entry.type
            local target = workspace.NPCs:FindFirstChild(name) or workspace:FindFirstChild(name, true)
            
            if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
                local targetIsland = LocationMapping[name]
                
                -- Nhảy đảo (Bỏ qua kiểm tra Pause, bay thẳng)
                if targetIsland and targetIsland ~= MyCurrentLocation then
                    local remoteTele = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TeleportToPortal")
                    if remoteTele then
                        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        remoteTele:FireServer(targetIsland)
                        MyCurrentLocation = targetIsland
                        task.wait(0.3) -- Đợi ngắn để Server nhận tọa độ
                    end
                end

                local tRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                if not tRoot then continue end

                CheckAndEquipTool()

                local hover = root:FindFirstChild("KybrondHover") or Instance.new("BodyVelocity")
                hover.Name = "KybrondHover"; hover.MaxForce = Vector3.new(9e9, 9e9, 9e9); hover.Parent = root
                hover.Velocity = Vector3.new(0,0,0)

                while target and target.Parent and target.Humanoid.Health > 0 do
                    local currentTRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
                    if currentTRoot then
                        root.CFrame = currentTRoot.CFrame * CFrame.new(0, HeightOffset, 0)
                        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        CheckAndEquipTool()
                        UseSkillRemote()
                    else
                        break 
                    end
                    task.wait(SkillDelay)

                    -- Săn Boss quay xe
                    if targetType == "Mob" then
                        local bossCheck = false
                        for _, bName in pairs(BossList) do
                            local b = workspace.NPCs:FindFirstChild(bName)
                            if b and b:FindFirstChild("Humanoid") and b.Humanoid.Health > 0 then
                                bossCheck = true; break
                            end
                        end
                        if bossCheck then break end 
                    end
                end
                break 
            end
        end
    end
end)
