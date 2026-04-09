_G.AutoFarm = true 
_G.Distance = 10
_G.FarmSpeed = 80

local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local NPCs = workspace.NPCs

local LastCFrame = nil 

-- 1. HÀM CHỐNG RUNG & GIỮ TRẠNG THÁI LƠ LỬNG
local function SetHoverState(state)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = state
    end
end

-- 2. VÒNG LẶP VẬT LÝ (Noclip + Gom Quái + Khóa Vị Trí)
RunService.Stepped:Connect(function()
    if _G.AutoFarm then
        if Player.Character then
            for _, v in pairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            
            local Root = Player.Character:FindFirstChild("HumanoidRootPart")
            if Root and LastCFrame then
                Root.CFrame = LastCFrame
                Root.Velocity = Vector3.new(0, 0, 0)
            end
        end

        -- GOM QUÁI VỀ NINJA 1
        local Ninja1 = NPCs:FindFirstChild("Ninja1")
        if Ninja1 and Ninja1:FindFirstChild("HumanoidRootPart") and Ninja1.Humanoid.Health > 0 then
            for i = 2, 5 do
                local Other = NPCs:FindFirstChild("Ninja" .. i)
                if Other and Other:FindFirstChild("HumanoidRootPart") and Other.Humanoid.Health > 0 then
                    Other.HumanoidRootPart.CFrame = Ninja1.HumanoidRootPart.CFrame
                    Other.HumanoidRootPart.CanCollide = false
                    Other.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

-- 3. HÀM BAY TỚI MỤC TIÊU
local function TweenTo(TargetCFrame)
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    local Distance = (Root.Position - TargetCFrame.Position).Magnitude
    local Time = Distance / _G.FarmSpeed
    
    SetHoverState(true)
    local Tween = TweenService:Create(Root, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = TargetCFrame})
    Tween:Play()
    return Tween
end

-- 4. VÒNG LẶP LOGIC FARM + MULTI DAMAGE
task.spawn(function()
    while _G.AutoFarm do
        task.wait()
        
        -- Tìm mục tiêu gốc (Ninja 1)
        local MainTarget = NPCs:FindFirstChild("Ninja1")
        if not (MainTarget and MainTarget.Humanoid.Health > 0) then
            for i = 2, 5 do
                local temp = NPCs:FindFirstChild("Ninja" .. i)
                if temp and temp.Humanoid.Health > 0 then
                    MainTarget = temp
                    break
                end
            end
        end

        if MainTarget then
            local TargetRoot = MainTarget:FindFirstChild("HumanoidRootPart")
            if TargetRoot then
                LastCFrame = TargetRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                
                local Root = Player.Character:FindFirstChild("HumanoidRootPart")
                if Root and (Root.Position - TargetRoot.Position).Magnitude > 20 then
                    local t = TweenTo(LastCFrame)
                    if t then t.Completed:Wait() end
                end

                -- VÒNG LẶP TẤN CÔNG MULTI-HIT
                while _G.AutoFarm and MainTarget.Parent and MainTarget.Humanoid.Health > 0 do
                    LastCFrame = TargetRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    
                    pcall(function()
                        local RS = game:GetService("ReplicatedStorage")
                        local combatRemotes = {RS:FindFirstChild("CombatRemote", true), RS:FindFirstChild("KatanaCombatRemote", true)}
                        local requestHit = RS:FindFirstChild("RequestHit", true)

                        -- 1. Kích hoạt hiệu ứng đánh (Chỉ cần gọi 1 lần mỗi đợt)
                        for _, r in pairs(combatRemotes) do
                            if r then r:FireServer() end
                        end

                        -- 2. MULTI DAMAGE: Quét và gây sát thương lên TẤT CẢ quái đang đứng trong đống gom
                        for i = 1, 5 do
                            local monster = NPCs:FindFirstChild("Ninja" .. i)
                            if monster and monster:FindFirstChild("Humanoid") and monster.Humanoid.Health > 0 then
                                if requestHit then
                                    -- Gửi lệnh gây sát thương lên từng con Ninja một lúc
                                    requestHit:FireServer(monster)
                                end
                            end
                        end
                    end)
                    task.wait(0.1) -- Tốc độ đánh
                end
            end
        else
            -- Khi quái chết sạch, giữ nguyên tọa độ cũ để không bị rơi
            warn("Đang đợi Ninja hồi sinh, đang giữ vị trí...")
            task.wait(0.5)
        end
    end
end)

warn("--- PHONG HUB V6: MULTI-DAMAGE + CHỐNG RƠI ĐÃ SẴN SÀNG ---")
