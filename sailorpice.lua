-- [[ SAILORPICE.LUA - VERSION 5.2 ELITE ]]
-- Tích hợp Orion UI với nút gạt bật/tắt Auto Farm

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "KYBROND HUB | SAILOR PIECE", HidePremium = false, SaveConfig = true, ConfigFolder = "SailorPiceConfig"})

-- [[ BIẾN CẤU HÌNH CỐ ĐỊNH ]]
_G.AutoFarm = false -- Mặc định tắt để bạn chủ động gạt nút
_G.Distance = 10 
_G.FarmSpeed = 100 

local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local NPCs = workspace:WaitForChild("NPCs")

local CurrentTween = nil

-- [[ HÀM TỐI ƯU HÓA NHÂN VẬT (GIỮ NGUYÊN V5) ]]
local function OptimizeCharacter()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = true 
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end

-- [[ HÀM BAY LƯỚT ELITE GLIDE (GIỮ NGUYÊN V5) ]]
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

-- [[ LOGIC FARM CHÍNH ]]
function StartFarm()
    task.spawn(function()
        -- Kết nối Noclip
        local noclipConnect = RunService.Stepped:Connect(function()
            if _G.AutoFarm then OptimizeCharacter() end
        end)

        while _G.AutoFarm do
            task.wait()
            
            local Target = nil
            local MinDist = math.huge
            
            for _, n in pairs(NPCs:GetChildren()) do
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
                
                EliteGlide(GoalCFrame)
                
                while _G.AutoFarm and Target.Parent and Target.Humanoid.Health > 0 do
                    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                        Player.Character.HumanoidRootPart.CFrame = TRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        Player.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                    end

                    pcall(function()
                        local r1 = RS:FindFirstChild("CombatRemote", true)
                        local r2 = RS:FindFirstChild("RequestHit", true)
                        if r1 then r1:FireServer() end
                        if r2 then r2:FireServer(Target) end
                    end)
                    task.wait(0.1)
                end
            end
        end
        noclipConnect:Disconnect()
    end)
end

-- [[ GIAO DIỆN ĐIỀU KHIỂN ]]
local MainTab = Window:MakeTab({
	Name = "Main Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

MainTab:AddToggle({
	Name = "Auto Farm Ninja",
	Default = false,
	Callback = function(Value)
		_G.AutoFarm = Value
        if Value then
            StartFarm()
        else
            -- Khi tắt, trả lại trạng thái bình thường cho nhân vật
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid.PlatformStand = false
            end
        end
	end    
})

OrionLib:Init()
