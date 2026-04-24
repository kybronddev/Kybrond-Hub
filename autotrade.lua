-- [[ KYBROND AUTO-TRADE V2.1 - MAX CAPACITY (999999) ]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- [[ 1. CẤU HÌNH (CONFIG) ]]
local MainAccountName = "TenAccChinhCuaBan123" -- ĐIỀN TÊN ACC CHÍNH VÀO ĐÂY
local MaxSlotsPerTrade = 4 

-- Cấu trúc mới: Chỉ cần {Danh mục, Tên đồ}. Số lượng đã được auto set là 999999.
local ItemsToTrade = {
    {"Items", "Aura Crate"},
    {"Items", "Sword Crate"},
    -- Cứ rải tên các món đồ bạn muốn vét sạch vào đây
}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TradeRemotes = Remotes:WaitForChild("TradeRemotes")

-- [[ 2. VÒNG LẶP GIAO HÀNG (BATCH LOOP) ]]
task.spawn(function()
    warn("!!! KYBROND AUTO-TRADE V2.1 ĐÃ KHỞI ĐỘNG !!!")
    
    if Player.Name == MainAccountName then
        warn("!!! ĐÂY LÀ ACC CHÍNH - TREO MÁY NHẬN ĐỒ !!!")
        
        while true do
            task.wait(2)
            pcall(function()
                TradeRemotes.SetReady:FireServer(true)
                task.wait(1)
                TradeRemotes.ConfirmTrade:FireServer()
            end)
        end
        return 
    end

    warn("!!! ĐÂY LÀ ACC PHỤ - BẮT ĐẦU VÉT SẠCH KHO ĐỒ !!!")
    task.wait(5) 

    local MainPlayer = Players:WaitForChild(MainAccountName, 30)
    if not MainPlayer then
        warn("Lỗi: Không tìm thấy Acc Chính trong server này!")
        return
    end

    pcall(function()
        Remotes.RequestInventory:FireServer()
        TradeRemotes.GetTradablePlayers:InvokeServer()
    end)
    task.wait(2)

    while #ItemsToTrade > 0 do
        
        warn("-> Đang gửi yêu cầu Trade tới Acc Chính...")
        TradeRemotes.SendTradeRequest:FireServer(MainPlayer.UserId)
        
        task.wait(5) 

        local itemsThisRound = math.min(MaxSlotsPerTrade, #ItemsToTrade)
        
        warn("-> Bắt đầu vét sạch " .. itemsThisRound .. " loại đồ vào khung...")
        for i = 1, itemsThisRound do
            local itemData = ItemsToTrade[i]
            local category = itemData[1]
            local itemName = itemData[2]
            
            -- ÉP SỐ LƯỢNG 999999 TRỰC TIẾP VÀO REMOTE
            TradeRemotes.AddItemToTrade:FireServer(category, itemName, 999999)
            task.wait(0.3) 
        end

        warn("-> Đã nhét xong, chuẩn bị khóa giao dịch (Set Ready)...")
        task.wait(1)
        TradeRemotes.SetReady:FireServer(true)

        warn("-> Chờ đếm ngược hệ thống...")
        task.wait(4) 

        warn("-> Bấm Xác nhận cuối cùng (Confirm Trade)!")
        TradeRemotes.ConfirmTrade:FireServer()

        task.wait(4) 

        for i = 1, itemsThisRound do
            table.remove(ItemsToTrade, 1) 
        end

        warn("✅ Đã trade xong 1 đợt! Số loại vật phẩm cần trade còn lại: " .. #ItemsToTrade)
        task.wait(3) 
    end

    warn("🏆 HOÀN THÀNH VÉT SẠCH TOÀN BỘ ĐỒ TỪ ACC NÀY! 🏆")
    -- game:Shutdown() 
end)
