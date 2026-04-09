local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "KYBROND HUB V9 | STEALTH QA EDITION", HidePremium = false, SaveConfig = true, ConfigFolder = "KybrondTest"})

-- [[ BIẾN CẤU HÌNH ]]
_G.AutoFarm = false
_G.Distance = 10
_G.FarmSpeed = 80
_G.IsTweening = false -- Biến kiểm soát để tránh xung đột vật lý khi đang lướt

local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local NPCs = workspace:WaitForChild("NPCs")

local LastCFrame = nil
local SteppedConnection = nil

-- [[ 1. ANTI-AFK ]]
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- [[ 2. HÀM TIỆN ÍCH ]]
local function SetHoverState(state)
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.PlatformStand = state
    end
end

-- QUẢN LÝ VẬT LÝ (NOCLIP + GOM QUÁI + HOVER)
local function StartPhysicsLoop()
    if SteppedConnection then SteppedConnection:Disconnect() end
    SteppedConnection = RunService.Stepped:Connect(function()
        if _G.AutoFarm and Player.Character then
            local Root = Player.Character:FindFirstChild("HumanoidRootPart")
            if not Root then return end

            -- Noclip: Luôn bật để không bị kẹt địa hình khi lướt
            for _, v in pairs(Player.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            
            -- KHÓA VỊ TRÍ: Chỉ khóa khi KHÔNG trong quá trình bay lướt (Tweening)
            if not _G.IsTweening and LastCFrame then
                Root.CFrame = LastCFrame
                Root.Velocity = Vector3.new(0, 0, 0)
            end

            -- GOM QUÁI (Chỉ gom các Ninja thường về Ninja 1)
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

-- HÀM BAY LƯỚT CHUYÊN NGHIỆP (CHỐNG BAN)
local function GlideTo(TargetCFrame)
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    
    local Distance = (Root.Position - TargetCFrame.Position).Magnitude
    if Distance < 5 then -- Nếu quá gần thì không cần lướt
        LastCFrame = TargetCFrame
        return 
    end

    _G.IsTweening = true
    local Time = Distance / _G.FarmSpeed
    local Info = TweenInfo.new(Time, Enum.EasingStyle.Linear)
    local Tween = TweenService:Create(Root, Info, {CFrame = TargetCFrame})
    
    Tween:Play()
    Tween.Completed:Wait()
    
    LastCFrame = TargetCFrame
    _G.IsTweening = false
end

-- [[ 3. GIAO DIỆN ]]
local FarmTab = Window:MakeTab({
	Name = "Stealth Farm",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local StatusLabel = FarmTab:AddLabel("Trạng thái: Đang nghỉ")

FarmTab:AddToggle({
	Name = "Kích Hoạt Auto Farm (Bao gồm Boss)",
	Default = false,
	Callback = function(Value)
		_G.AutoFarm = Value
        if Value then
            SetHoverState(true)
            StartPhysicsLoop()
            ExecuteFarm()
        else
            StatusLabel:Set("Trạng thái: Đang nghỉ")
            SetHoverState(false)
            if SteppedConnection then SteppedConnection:Disconnect() end
            _G.IsTweening = false
            LastCFrame = nil
        end
	end    
})

FarmTab:AddSlider({
	Name = "Tốc Độ Bay Lướt",
	Min = 20,
	Max = 150,
	Default = 80,
	Color = Color3.fromRGB(0,255,0),
	Increment = 5,
	ValueName = "Speed",
	Callback = function(Value) _G.FarmSpeed = Value end    
})

-- [[ 4. LOGIC FARM CHÍNH ]]
function ExecuteFarm()
    task.spawn(function()
        while _G.AutoFarm do
            task.wait()
            
            -- HỆ THỐNG TÌM MỤC TIÊU: Ưu tiên Boss, sau đó đến Ninja 1
            local Target = NPCs:FindFirstChild("Boss") or NPCs:FindFirstChild("Boss1") -- Thay tên Boss chính xác của game vào đây
            
            if not (Target and Target:FindFirstChild("Humanoid") and Target.Humanoid.Health > 0) then
                Target = NPCs:FindFirstChild("Ninja1")
            end
            
            -- Nếu Ninja 1 cũng chết, tìm Ninja 2-5
            if not (Target and Target:FindFirstChild("Humanoid") and Target.Humanoid.Health > 0) then
                for i = 2, 5 do
                    local t = NPCs:FindFirstChild("Ninja" .. i)
                    if t and t.Humanoid.Health > 0 then Target = t break end
                end
            end

            if Target and Target:FindFirstChild("HumanoidRootPart") then
                local TRoot = Target.HumanoidRootPart
                local GoalCFrame = TRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                
                -- Thực hiện bay lướt đến mục tiêu thay vì teleport
                StatusLabel:Set("Trạng thái: Đang bay tới " .. Target.Name)
                GlideTo(GoalCFrame)
                
                -- Vòng lặp tấn công
                while _G.AutoFarm and Target.Parent and Target.Humanoid.Health > 0 do
                    StatusLabel:Set("Trạng thái: Đang tiêu diệt " .. Target.Name)
                    LastCFrame = TRoot.CFrame * CFrame.new(0, _G.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    
                    pcall(function()
                        local RS = game:GetService("ReplicatedStorage")
                        local req = RS:FindFirstChild("RequestHit", true)
                        local combat = RS:FindFirstChild("CombatRemote", true) or RS:FindFirstChild("KatanaCombatRemote", true)
                        
                        if combat then combat:FireServer() end
                        
                        -- Multi Damage (Đánh lan toàn bộ quái trong đống gom)
                        for i = 1, 5 do
                            local m = NPCs:FindFirstChild("Ninja" .. i)
                            if m and m.Humanoid.Health > 0 and req then req:FireServer(m) end
                        end
                        -- Đánh thêm Boss nếu có
                        if Target.Name:find("Boss") and req then req:FireServer(Target) end
                    end)
                    task.wait(0.1)
                end
            else
                StatusLabel:Set("Trạng thái: Đang đợi mục tiêu hồi sinh...")
            end
        end
    end)
end

OrionLib:Init()
--cập nhật v9--