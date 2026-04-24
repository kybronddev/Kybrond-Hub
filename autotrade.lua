-- [[ KYBROND AUTO-TRADE V2.2 - FULL AUTOMATION HOTFIX ]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- [[ 1. CẤU HÌNH (CONFIG) ]]
local MainAccountName = "TenAccChinhCuaBan123" -- ĐIỀN TÊN ACC CHÍNH VÀO ĐÂY
local MaxSlotsPerTrade = 4 -- Số ô đồ tối đa game cho phép nhét vào trong 1 lần trade

-- Cấu trúc: {Danh mục, Tên đồ}. Số lượng đã được tự động ép max 999999.
local ItemsToTrade = {
    {"Items", "Aura Crate"},
    {"Items", "Sword Crate"},
    -- Cứ rải tên các món đồ bạn muốn vét sạch vào đây
}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TradeRemotes = Remotes:WaitForChild("TradeRemotes")

-- [[ 2. VÒNG LẶP CHÍNH ]]
task.spawn(function()
    warn("!!! KYBROND AUTO-TRADE V2.2 ĐÃ KHỞI ĐỘNG !!!")
    
    -- ==========================================
    -- LOGIC CỦA ACC CHÍNH (THỦ KHO)
    -- ==========================================
    if Player.Name == MainAccountName then
        warn("!!! ĐÂY LÀ ACC CHÍNH - TREO MÁY NHẬN ĐỒ !!!")
        
        while true do
            task.wait(2)
            pcall(function()
                -- CHÚ Ý: BẠN CẦN THÊM REMOTE "CHẤP NHẬN LỜI MỜI" VÀO ĐÂY SAU KHI LẤY ĐƯỢC TỪ SIMPLESPY
                -- Ví dụ: TradeRemotes.AcceptRequest:FireServer()
                
                TradeRemotes.SetReady:FireServer(true)
                task.wait(1)
                TradeRemotes.ConfirmTrade:FireServer()
            end)
        end
        return 
    end

    -- ==========================================
    -- LOGIC CỦA ACC PHỤ (GOM ĐỒ)
    -- ==========================================
    warn("!!! ĐÂY LÀ ACC PHỤ - BẮT ĐẦU VÉT SẠCH KHO ĐỒ !!!")
    task.wait(5) -- Chờ game load ổn định

    local MainPlayer = Players:WaitForChild(MainAccountName, 30)
    if not MainPlayer then
        warn("Lỗi: Không tìm thấy Acc Chính trong server này!")
        return
    end

    -- 1. FIX KẸT SCRIPT: Dùng task.spawn để khởi tạo dữ liệu không bị chặn đứng code
    task.spawn(function()
        pcall(function()
            Remotes.RequestInventory:FireServer()
            TradeRemotes.GetTradablePlayers:InvokeServer()
        end)
    end)
    task.wait(2)

    -- 2. FIX KHOẢNG CÁCH: Bay thẳng đến trước mặt Acc Chính để gửi lệnh không bị hụt
    local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local mainRoot = MainPlayer.Character and MainPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if myRoot and mainRoot then
        myRoot.CFrame = mainRoot.CFrame * CFrame.new(0, 0, -3)
        warn("-> Đã bay đến vị trí Acc Chính!")
        task.wait(1.5) -- Chờ server đồng bộ tọa độ
    else
        warn("Lỗi: Nhân vật chưa load xong RootPart!")
        return
    end

    -- 3. VÒNG LẶP CHIA MẺ VÀ GIAO DỊCH
    while #ItemsToTrade > 0 do
        
        warn("-> Đang gửi yêu cầu Trade tới Acc Chính...")
        TradeRemotes.SendTradeRequest:FireServer(MainPlayer.UserId)
        
        task.wait(5) -- Chờ bảng Trade hiện lên

        local itemsThisRound = math.min(MaxSlotsPerTrade, #ItemsToTrade)
        
        warn("-> Bắt đầu vét sạch " .. itemsThisRound .. " loại đồ vào khung...")
        for i = 1, itemsThisRound do
            local itemData = ItemsToTrade[i]
            local category = itemData[1]
            local itemName = itemData[2]
            
            -- ÉP SỐ LƯỢNG 999999 TRỰC TIẾP VÀO REMOTE
            TradeRemotes.AddItemToTrade:FireServer(category, itemName, 999999)
            task.wait(0.3) -- Chống nghẽn mạng
        end

        warn("-> Đã nhét xong, chuẩn bị khóa giao dịch (Set Ready)...")
        task.wait(1)
        TradeRemotes.SetReady:FireServer(true)

        warn("-> Chờ đếm ngược hệ thống...")
        task.wait(4) 

        warn("-> Bấm Xác nhận cuối cùng (Confirm Trade)!")
        TradeRemotes.ConfirmTrade:FireServer()

        task.wait(4) -- Chờ giao dịch chuyển đồ vào kho

        -- Xóa các món đồ đã trade thành công khỏi danh sách để đẩy danh sách lên
        for i = 1, itemsThisRound do
            table.remove(ItemsToTrade, 1) 
        end

        warn("✅ Đã trade xong 1 đợt! Số loại vật phẩm cần trade còn lại: " .. #ItemsToTrade)
        task.wait(3) -- Nghỉ ngơi giữa 2 vòng lặp
    end

    warn("🏆 HOÀN THÀNH VÉT SẠCH TOÀN BỘ ĐỒ TỪ ACC NÀY! 🏆")
    -- game:Shutdown() -- Tự động tắt game sau khi xong việc
end)
