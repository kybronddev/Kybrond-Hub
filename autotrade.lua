-- [[ KYBROND AUTO-TRADE V3.5 - SPEED RUN EDITION (SMART POLLING) ]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- [[ 1. CẤU HÌNH (CONFIG) ]]
local MainAccountName = "kybrond" 
local MaxSlotsPerTrade = 25 

-- ĐIỀN TÊN CỦA BẢNG TRADE (TÌM BẰNG DARK DEX) VÀO ĐÂY:
-- Ví dụ: "TradeUI", "TradePanel", "TradeMenu", v.v.
local TradeGuiName = "ĐIỀN_TÊN_UI_TRADE_VÀO_ĐÂY" 

local ItemsToTrade = {
    {"Items", "Aura Crate"}, 
    {"Items", "Cosmetic Crate"},
    {"Items", "Easter Egg"},
    {"Items", "Easter Egg"},
    {"Items", "Easter Key"},
    {"Items", "Mythical Chest"},
    {"Items", "Clan Reroll"},
    {"Items", "Power Shard"},
    {"Items", "Frost Relic"},
    {"Items", "Relic Part #1"},
    {"Items", "Relic Part #2"},
    {"Items", "Relic Part #3"},
    {"Items", "Relic Part #4"},
    {"Items", "Relic Part #5"},
    {"Items", "Relic Part #6"},
    {"Items", "Relic Part #7"},
    {"Items", "Relic Part #8"},
    {"Items", "Upper Seal"},
    {"Items", "Race Reroll"},
    {"Items", "Trait Reroll"},
    {"Items", "Dominion Brand"},
    {"Items", "Abyss Sigil"},
    {"Items", "Chrysalis Sigil"},
}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TradeRemotes = Remotes:WaitForChild("TradeRemotes")

if Player.Name == MainAccountName then
    warn("!!! ĐÂY LÀ ACC CHÍNH. SCRIPT TỰ ĐỘNG NGẮT ĐỂ BẢO VỆ TÀI KHOẢN !!!")
    return 
end

-- [[ 2. HÀM TỰ ĐỘNG ĐẾM ĐỒ TỪ UI (Giữ nguyên độ mượt từ V3.4) ]]
local function GetItemAmount(itemName)
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local InventoryUI = PlayerGui:FindFirstChild("InventoryPanelUI")
    if not InventoryUI then return 0 end
    
    local MainFrame = InventoryUI:FindFirstChild("MainFrame")
    local Frame = MainFrame and MainFrame:FindFirstChild("Frame")
    local Content = Frame and Frame:FindFirstChild("Content")
    local Holder = Content and Content:FindFirstChild("Holder")
    local StorageHolder = Holder and Holder:FindFirstChild("StorageHolder")
    local Storage = StorageHolder and StorageHolder:FindFirstChild("Storage")
    
    if not Storage then return 0 end
    
    local itemFrame = Storage:FindFirstChild("Item_" .. itemName)
    if itemFrame then
        for _, child in ipairs(itemFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                local numberMatch = string.match(child.Text, "%d+")
                if numberMatch then return tonumber(numberMatch) end
            end
        end
        return 1
    end
    return 0
end

-- [[ 3. LOGIC CỦA ACC PHỤ ]]
task.spawn(function()
    warn("!!! ĐÂY LÀ ACC PHỤ - BẮT ĐẦU VÉT SẠCH KHO ĐỒ TỐC ĐỘ CAO !!!")
    task.wait(5) 

    local MainPlayer = Players:WaitForChild(MainAccountName, 30)
    if not MainPlayer then return warn("Lỗi: Không tìm thấy Acc Chính!") end

    local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local mainRoot = MainPlayer.Character and MainPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if myRoot and mainRoot then
        myRoot.CFrame = mainRoot.CFrame * CFrame.new(0, 0, -3)
        warn("-> Đã bay đến vị trí Acc Chính!")
        task.wait(1.5) 
    else
        return warn("Lỗi: Nhân vật chưa load xong RootPart!")
    end

    while #ItemsToTrade > 0 do
        warn("-> Đang khởi tạo dữ liệu với Server...")
        pcall(function()
            Remotes.RequestInventory:FireServer()
            TradeRemotes.GetTradablePlayers:InvokeServer()
        end)
        task.wait(1) 

        warn("-> Đang gửi yêu cầu Trade tới Acc Chính...")
        TradeRemotes.SendTradeRequest:FireServer(MainPlayer.UserId)
        
        -- KỸ THUẬT SMART POLLING (CHỜ THÔNG MINH)
        warn("⏳ BẠN CÓ THỂ BẤM 'ACCEPT' BẤT CỨ LÚC NÀO...")
        local waitTime = 0
        local tradeOpened = false
        while waitTime < 15 do
            if Player.PlayerGui:FindFirstChild(TradeGuiName) then
                tradeOpened = true
                warn("⚡ Đã phát hiện Bảng Trade! Vào việc ngay!")
                break -- Phá vòng lặp chờ, chạy tiếp ngay lập tức
            end
            task.wait(0.2) -- Check mỗi 0.2s để phản ứng cực nhanh
            waitTime = waitTime + 0.2
        end

        if not tradeOpened then
            warn("⚠️ Quá thời gian chờ hoặc sai tên TradeGuiName. Tiếp tục chạy dự phòng!")
        end

        local itemsThisRound = math.min(MaxSlotsPerTrade, #ItemsToTrade)
        local hasItemsToPut = false
        
        warn("-> Bắt đầu nhét đồ (TỐC ĐỘ ÉP XUNG)...")
        for i = 1, itemsThisRound do
            local itemData = ItemsToTrade[i]
            local realAmount = GetItemAmount(itemData[2])
            
            if realAmount > 0 then
                hasItemsToPut = true
                pcall(function()
                    TradeRemotes.AddItemToTrade:FireServer(itemData[1], itemData[2], realAmount)
                end)
                task.wait(0.1) -- ÉP XUNG TỐC ĐỘ TỪ 0.5 XUỐNG 0.1s
            end
        end

        if not hasItemsToPut then
            for i = 1, itemsThisRound do table.remove(ItemsToTrade, 1) end
            continue 
        end

        warn("-> Đã nhét xong, chuẩn bị khóa giao dịch (Set Ready)...")
        pcall(function()
            TradeRemotes.SetReady:FireServer(true)
            Remotes.RequestInventory:FireServer()
        end)

        -- Thời gian cho Acc Chính chốt đơn
        warn("⏳ ACC PHỤ ĐÃ READY! BẠN CÓ 10 GIÂY ĐỂ CHỐT ĐƠN BÊN ACC CHÍNH!")
        task.wait(10) -- Bạn có thể hạ số 10 này xuống 7 hoặc 5 nếu tay bạn thao tác nhanh

        warn("-> Acc Phụ tự động Xác nhận cuối cùng (Confirm Trade)!")
        pcall(function()
            TradeRemotes.ConfirmTrade:FireServer()
            Remotes.RequestInventory:FireServer()
        end)

        task.wait(2) -- Chờ game xử lý chuyển đồ (Hạ từ 4s xuống 2s)

        for i = 1, itemsThisRound do
            table.remove(ItemsToTrade, 1) 
        end

        warn("✅ Đã trade xong 1 đợt! Số loại vật phẩm cần trade còn lại: " .. #ItemsToTrade)
        task.wait(1) -- Rút ngắn thời gian nghỉ giữa các đợt
    end

    warn("🏆 HOÀN THÀNH VÉT SẠCH TOÀN BỘ ĐỒ TỪ ACC NÀY TỐC ĐỘ BÀN THỜ! 🏆")
end)
