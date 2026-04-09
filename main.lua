local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "KYBROND HUB V7 | QA TESTING EDITION", HidePremium = false, SaveConfig = true, ConfigFolder = "KybrondTest"})

-- [[ BIẾN CẤU HÌNH ]]
_G.AutoFarm = false
_G.Distance = 10
_G.FarmSpeed = 80
_G.MultiDamage = true

local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local NPCs = workspace:WaitForChild("NPCs")
local LastCFrame = nil
local SteppedConnection = nil

-- [[ HÀM TIỆN ÍCH ]]
local function SetHoverState(state)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = state
    end
end

-- QUẢN LÝ VẬT LÝ (NOCLIP + GOM QUÁI)
local function StartPhysicsLoop()
    if SteppedConnection then SteppedConnection:Disconnect() end
    SteppedConnection = RunService.Stepped:Connect(function()
        if _G.AutoFarm and Player.Character then
            -- Noclip
            for _, v in pairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            
            -- Khóa vị trí (Hover)
            local Root = Player.Character:FindFirstChild("HumanoidRootPart")
            if Root and LastCFrame then
                Root.CFrame = LastCFrame
                Root.Velocity = Vector3.new(0, 0, 0)
            end

            -- Gom quái về Ninja 1
            local Ninja1 = NPCs:FindFirstChild("Ninja1")
            if Ninja1 and Ninja1:FindFirstChild("HumanoidRootPart") and Ninja1.Humanoid.Health > 0 then
                for i = 2, 5 do
                    local Other = NPCs:FindFirstChild("Ninja" .. i)
                    if Other and Other:FindFirstChild("HumanoidRootPart") and Other.Humanoid.Health > 0 then
                        Other.HumanoidRootPart.CFrame = Ninja1.HumanoidRootPart.CFrame
                        Other.HumanoidRootPart.CanCollide = false
                    end
                end
            end
        end
    end)
end

-- [[ GIAO DIỆN ĐIỀU KHIỂN ]]
local FarmTab = Window:MakeTab({
	Name = "Auto Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

FarmTab:AddToggle({
	Name = "Kích Hoạt Auto Farm",
	Default = false,
	Callback = function(Value)
		_G.AutoFarm = Value
        if Value then
            SetHoverState(true)
            StartPhysicsLoop()
            ExecuteFarm() -- Gọi hàm vòng lặp chính
        else
            SetHoverState(false)
            if SteppedConnection then SteppedConnection:Disconnect() end
            LastCFrame = nil
        end
	end    
})

FarmTab:AddSlider({
	Name = "Khoảng Cách (Distance)",
	Min = 5,
	Max = 20,
	Default = 10,
	Color = Color3.fromRGB(255,255,255),
	Increment = 1,
	ValueName = "Studs",
	Callback = function(Value)
		_G.Distance = Value
	end    
})

FarmTab:AddSlider({
	Name = "Tốc Độ Bay (Farm Speed)",
	Min = 20,
	Max = 200,
	Default = 80,
	Color = Color3.fromRGB(0,255,0),
	Increment = 10,
	ValueName = "Speed",
	Callback = function(Value)
		_G.FarmSpeed = Value
	end    
})

-- [[ LOGIC FARM CHÍNH ]]
function ExecuteFarm()
    task.spawn(function()
        while _G.AutoFarm do
            task.wait()
            local MainTarget = NPCs:FindFirstChild("Ninja1")
            -- Logic tìm mục tiêu thay thế nếu Ninja 1 chết
            if not (MainTarget and MainTarget.Humanoid.Health > 0) then
                for i = 2, 5 do
                    local t = NPCs:FindFirstChild("Ninja" .. i)
                    if t and t.Humanoid.Health > 0 then MainTarget = t break end
                end
            end

            if MainTarget and MainTarget:FindFirstChild("HumanoidRootPart") then
                local TRoot = MainTarget.HumanoidRootPart
                LastCFrame = TRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                
                -- Tấn công Multi-Hit
                pcall(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local req = RS:FindFirstChild("RequestHit", true)
                    -- Gọi Combat effect
                    local combat = RS:FindFirstChild("CombatRemote", true) or RS:FindFirstChild("KatanaCombatRemote", true)
                    if combat then combat:FireServer() end
                    
                    -- Đánh toàn bộ đám gom
                    for i = 1, 5 do
                        local m = NPCs:FindFirstChild("Ninja" .. i)
                        if m and m.Humanoid.Health > 0 and req then
                            req:FireServer(m)
                        end
                    end
                end)
            end
        end
    end)
end

OrionLib:Init()
