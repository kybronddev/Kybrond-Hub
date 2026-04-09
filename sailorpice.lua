-- [[ KYBROND HUB V5.2: NINJA FOCUS ]]
-- Chỉ đánh Ninja | Lướt mượt 100% | Tự động quay lại khi quái hồi sinh

_G.AutoFarm = true
_G.Distance = 10 -- Độ cao an toàn 10 studs
_G.FarmSpeed = 100 -- Tốc độ đã tăng để không còn bị chậm

local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local NPCs = workspace:WaitForChild("NPCs")

local CurrentTween = nil

-- [[ GIỮ NGUYÊN LOGIC V5: TỐI ƯU NHÂN VẬT ]]
local function OptimizeCharacter()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = true 
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end

-- [[ GIỮ NGUYÊN LOGIC V5: ELITE GLIDE ]]
local function EliteGlide(TargetCFrame)
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    local Distance = (Root.Position - TargetCFrame.Position).Magnitude
    if Distance < 2 then return end 

    local Time = Distance / _G.FarmSpeed
    local Info = TweenInfo.new(Time, Enum.EasingStyle.Linear) 
    
    if CurrentTween then CurrentTween:Cancel() end
    CurrentTween = TweenService:Create(Root, Info, {CFrame = TargetCFrame})
    CurrentTween:Play()
    CurrentTween.Completed:Wait()
end

-- [[ VÒNG LẶP LOGIC CHÍNH ]]
task.spawn(function()
    print("--- KYBROND V5.2: NINJA FARM ACTIVE ---")
    
    -- Kết nối Noclip liên tục
    RunService.Stepped:Connect(function()
        if _G.AutoFarm then OptimizeCharacter() end
    end)

    while _G.AutoFarm do
        task.wait()
        
        -- TÌM MỤC TIÊU: Chỉ lọc những quái có tên chứa chữ "Ninja"
        local Target = nil
        local MinDist = math.huge
        
        for _, n in pairs(NPCs:GetChildren()) do
            -- Kiểm tra tên phải có chữ Ninja và còn sống
            if n.Name:find("Ninja") and n:FindFirstChild("Humanoid") and n.Humanoid.Health > 0 and n:FindFirstChild("HumanoidRootPart") then
                local dist = (Player.Character.HumanoidRootPart.Position - n.HumanoidRootPart.Position).Magnitude
                if dist < MinDist then
                    MinDist = dist
                    Target = n
                end
            end
        end

        if Target and Target:FindFirstChild("HumanoidRootPart") then
            local TRoot = Target.HumanoidRootPart
            local GoalCFrame = TRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            
            -- Lướt tới Ninja mục tiêu
            EliteGlide(GoalCFrame)
            
            -- Đánh cho đến khi quái chết
            while _G.AutoFarm and Target.Parent and Target.Humanoid.Health > 0 do
                -- Khóa vị trí 10 studs
                Player.Character.HumanoidRootPart.CFrame = TRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                Player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)

                pcall(function()
                    local r1 = RS:FindFirstChild("CombatRemote", true)
                    local r2 = RS:FindFirstChild("RequestHit", true)
                    if r1 then r1:FireServer() end
                    if r2 then r2:FireServer(Target) end
                end)
                task.wait(0.1)
            end
            -- Sau khi quái chết, vòng lặp 'while _G.AutoFarm' sẽ tự động quét đợt tiếp theo
        end
    end
end)
