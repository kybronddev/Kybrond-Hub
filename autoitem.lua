-- [[ KYBROND CORE V31.3 - PURE MOB - MAX SPEED - IMMORTAL LOOP ]]

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

-- [[ 2. LOGIC ANTI-AFK (CHỐNG KICK 20 PHÚT) ]]
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)



-- [[ 4. DANH SÁCH QUÁI & MAPPING (CHỈ GIỮ LẠI MOB) ]]
local MobList = {"Swordsman4", "ArenaFighter2", "Ninja4", "Slime3", "Quincy4"}

-- Sử dụng bảng tĩnh (Static List) để đạt tốc độ truy xuất cao nhất
local StaticPriorityList = {}
for _, m in ipairs(MobList) do 
    table.insert(StaticPriorityList, {name = m}) 
end

local LocationMapping = {
    ["Swordsman4"]    = "Judgement",
    ["ArenaFighter2"] = "Lawless",
    ["Ninja4"]        = "Ninja",
    ["Slime3"]        = "Slime",
    ["Quincy4"]       = "SoulDominion"
    ["Bunny2"]       = "Easter"
}

-- [[ 5. CẤU HÌNH CHIẾN ĐẤU ]]
local HeightOffset = 7 
local SkillDelay = 0.1   
local MyCurrentLocation = ""

local AbilityRemote = ReplicatedStorage:FindFirstChild("AbilitySystem") 
    and ReplicatedStorage.AbilitySystem:FindFirstChild("Remotes") 
    and ReplicatedStorage.AbilitySystem.Remotes:FindFirstChild("RequestAbility")
local TeleportRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TeleportToPortal")

-- [[ 6. MODULES ]]
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

-- [[ 7. VÒNG LẶP CHÍNH - IMMORTAL PURE MOB ]]
task.spawn(function()
    warn("!!! KYBROND V31.3 - PURE MOB PERFORMANCE ACTIVE !!!")
    
    while true do
        task.wait(0.1) -- Tốc độ Radar cao nhất
        
        -- Luôn cập nhật nhân vật (Immortal Logic)
        local char = Player.Character or Player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        local root = char:WaitForChild("HumanoidRootPart")
        
        if humanoid.Health <= 0 then 
            MyCurrentLocation = "" 
            continue 
        end

        for _, entry in ipairs(StaticPriorityList) do
            local name = entry.name
            local target = workspace.NPCs:FindFirstChild(name) or workspace:FindFirstChild(name, true)
            
            if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
                local targetIsland = LocationMapping[name]
                
                -- Teleport đảo giữ nguyên logic ổn định của bản Boss
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

                local hover = root:FindFirstChild("KybrondHover") or Instance.new("BodyVelocity")
                hover.Name = "KybrondHover"; hover.MaxForce = Vector3.new(9e9, 9e9, 9e9); hover.Parent = root
                hover.Velocity = Vector3.new(0,0,0)

                -- Vòng lặp chiến đấu thuần túy (Đã xóa bỏ mọi logic check Boss)
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
                    -- KHÔNG CÒN LOGIC BOSS CHECK Ở ĐÂY - TỐI ƯU TỐC ĐOẠN ĐÁNH
                end
                break 
            end
        end
    end
end)
