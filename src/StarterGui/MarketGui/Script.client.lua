-- StarterGui/MarketGui/Script.client.lua
-- Player market / auction house interface.
-- Shows current listings, allows listing items for sale and buying from others.

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local screenGui = script.Parent
screenGui.Enabled = false

local ItemData     = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemData"))
local EconomyModule= require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EconomyModule"))

local RemoteEvents      = ReplicatedStorage:WaitForChild("RemoteEvents")
local ListMarketItem    = RemoteEvents:WaitForChild("ListMarketItem")
local BuyMarketItem     = RemoteEvents:WaitForChild("BuyMarketItem")
local UpdateMarketPrices= RemoteEvents:WaitForChild("UpdateMarketPrices")
local UpdateInventory   = RemoteEvents:WaitForChild("UpdateInventory")
local NotifyPlayer      = RemoteEvents:WaitForChild("NotifyPlayer")

local currentListings = {}
local currentPrices   = {}
local playerInventory = {}

UpdateInventory.OnClientEvent:Connect(function(inv) playerInventory = inv end)
UpdateMarketPrices.OnClientEvent:Connect(function(prices, listings)
    currentPrices   = prices
    currentListings = listings or {}
    -- Refresh if open
    if screenGui.Enabled then
        -- will be called by the open handler
    end
end)

-- ─── Build UI ─────────────────────────────────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name                = "MarketFrame"
mainFrame.Size                = UDim2.new(0, 720, 0, 520)
mainFrame.Position            = UDim2.new(0.5, -360, 0.5, -260)
mainFrame.BackgroundColor3    = Color3.fromRGB(18, 25, 35)
mainFrame.BorderSizePixel     = 0
mainFrame.Parent              = screenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 70, 120)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size            = UDim2.new(1, -60, 1, 0)
titleLabel.Position        = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3      = Color3.new(1, 1, 1)
titleLabel.Font            = Enum.Font.GothamBold
titleLabel.TextScaled      = true
titleLabel.TextXAlignment  = Enum.TextXAlignment.Left
titleLabel.Text            = "📦 Central Market & Auction"
titleLabel.Parent          = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size              = UDim2.new(0, 40, 0, 40)
closeBtn.Position          = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3  = Color3.fromRGB(200, 60, 60)
closeBtn.BorderSizePixel   = 0
closeBtn.TextColor3        = Color3.new(1, 1, 1)
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.TextScaled        = true
closeBtn.Text              = "✕"
closeBtn.Parent            = titleBar
local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

-- Tab bar (Browse / Sell)
local tabBar = Instance.new("Frame")
tabBar.Size            = UDim2.new(1, 0, 0, 36)
tabBar.Position        = UDim2.new(0, 0, 0, 50)
tabBar.BackgroundColor3= Color3.fromRGB(12, 18, 28)
tabBar.BorderSizePixel = 0
tabBar.Parent          = mainFrame

local browseTab = Instance.new("TextButton")
browseTab.Size             = UDim2.new(0.5, 0, 1, 0)
browseTab.BackgroundColor3 = Color3.fromRGB(30, 80, 150)
browseTab.BorderSizePixel  = 0
browseTab.TextColor3       = Color3.new(1, 1, 1)
browseTab.Font             = Enum.Font.GothamBold
browseTab.TextScaled       = true
browseTab.Text             = "🔍 Browse Listings"
browseTab.Parent           = tabBar

local sellTab = Instance.new("TextButton")
sellTab.Size               = UDim2.new(0.5, 0, 1, 0)
sellTab.Position           = UDim2.new(0.5, 0, 0, 0)
sellTab.BackgroundColor3   = Color3.fromRGB(20, 20, 30)
sellTab.BorderSizePixel    = 0
sellTab.TextColor3         = Color3.fromRGB(180, 180, 180)
sellTab.Font               = Enum.Font.GothamBold
sellTab.TextScaled         = true
sellTab.Text               = "🏷️ List Item"
sellTab.Parent             = tabBar

-- Scroll frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size             = UDim2.new(1, -10, 1, -100)
scrollFrame.Position         = UDim2.new(0, 5, 0, 90)
scrollFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
scrollFrame.BorderSizePixel  = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize       = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent           = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent  = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingAll = UDim.new(0, 8)
listPadding.Parent     = scrollFrame

-- ─── Sell Panel (hidden by default) ─────────────────────────────────────────
local sellPanel = Instance.new("Frame")
sellPanel.Name               = "SellPanel"
sellPanel.Size               = UDim2.new(1, -10, 1, -100)
sellPanel.Position           = UDim2.new(0, 5, 0, 90)
sellPanel.BackgroundColor3   = Color3.fromRGB(12, 18, 28)
sellPanel.BorderSizePixel    = 0
sellPanel.Visible            = false
sellPanel.Parent             = mainFrame

-- Item dropdown label
local itemSelectLabel = Instance.new("TextLabel")
itemSelectLabel.Size          = UDim2.new(0, 200, 0, 36)
itemSelectLabel.Position      = UDim2.new(0, 10, 0, 20)
itemSelectLabel.BackgroundTransparency = 1
itemSelectLabel.TextColor3    = Color3.new(1, 1, 1)
itemSelectLabel.Font          = Enum.Font.GothamBold
itemSelectLabel.TextScaled    = true
itemSelectLabel.TextXAlignment= Enum.TextXAlignment.Left
itemSelectLabel.Text          = "Item: (select below)"
itemSelectLabel.Parent        = sellPanel

-- Item scroll (inventory items)
local invScroll = Instance.new("ScrollingFrame")
invScroll.Size             = UDim2.new(0.45, 0, 0.6, 0)
invScroll.Position         = UDim2.new(0, 10, 0, 60)
invScroll.BackgroundColor3 = Color3.fromRGB(18, 25, 40)
invScroll.BorderSizePixel  = 0
invScroll.ScrollBarThickness = 4
invScroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
invScroll.Parent           = sellPanel
local invLayout = Instance.new("UIListLayout")
invLayout.Padding = UDim.new(0, 3)
invLayout.Parent  = invScroll

local selectedSellItem = nil
local selectedSellQty  = 1

local function populateInvScroll()
    for _, c in ipairs(invScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local count = 0
    for _, slot in ipairs(playerInventory) do
        if slot.qty > 0 then
            count = count + 1
            local btn = Instance.new("TextButton")
            btn.Size             = UDim2.new(1, 0, 0, 36)
            btn.BackgroundColor3 = selectedSellItem == slot.id
                and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(25, 35, 55)
            btn.BorderSizePixel  = 0
            btn.TextColor3       = Color3.new(1, 1, 1)
            btn.Font             = Enum.Font.Gotham
            btn.TextScaled       = true
            btn.TextXAlignment   = Enum.TextXAlignment.Left
            local item = ItemData.ById[slot.id]
            btn.Text             = "  " .. (item and item.name or slot.id) .. " x" .. slot.qty
            btn.Parent           = invScroll
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn
            btn.MouseButton1Click:Connect(function()
                selectedSellItem = slot.id
                itemSelectLabel.Text = "Item: " .. (item and item.name or slot.id)
                populateInvScroll()
            end)
        end
    end
    invScroll.CanvasSize = UDim2.new(0, 0, 0, count * 40)
end

-- Quantity + Price inputs
local qtyLabel = Instance.new("TextLabel")
qtyLabel.Size    = UDim2.new(0, 80, 0, 30)
qtyLabel.Position= UDim2.new(0.5, 10, 0, 60)
qtyLabel.BackgroundTransparency = 1
qtyLabel.TextColor3 = Color3.new(1,1,1)
qtyLabel.Font    = Enum.Font.GothamBold
qtyLabel.TextScaled = true
qtyLabel.Text    = "Quantity:"
qtyLabel.Parent  = sellPanel

local qtyBox = Instance.new("TextBox")
qtyBox.Size           = UDim2.new(0, 100, 0, 36)
qtyBox.Position       = UDim2.new(0.5, 10, 0, 94)
qtyBox.BackgroundColor3= Color3.fromRGB(30, 40, 60)
qtyBox.BorderSizePixel= 0
qtyBox.TextColor3     = Color3.new(1,1,1)
qtyBox.Font           = Enum.Font.GothamBold
qtyBox.TextScaled     = true
qtyBox.PlaceholderText= "1"
qtyBox.Text           = "1"
qtyBox.Parent         = sellPanel
local qtyCorner = Instance.new("UICorner")
qtyCorner.CornerRadius = UDim.new(0, 6)
qtyCorner.Parent = qtyBox

local priceLabel = Instance.new("TextLabel")
priceLabel.Size    = UDim2.new(0, 80, 0, 30)
priceLabel.Position= UDim2.new(0.5, 10, 0, 136)
priceLabel.BackgroundTransparency = 1
priceLabel.TextColor3 = Color3.new(1,1,1)
priceLabel.Font    = Enum.Font.GothamBold
priceLabel.TextScaled = true
priceLabel.Text    = "Price ea:"
priceLabel.Parent  = sellPanel

local priceBox = Instance.new("TextBox")
priceBox.Size           = UDim2.new(0, 100, 0, 36)
priceBox.Position       = UDim2.new(0.5, 10, 0, 170)
priceBox.BackgroundColor3= Color3.fromRGB(30, 40, 60)
priceBox.BorderSizePixel= 0
priceBox.TextColor3     = Color3.new(1,1,1)
priceBox.Font           = Enum.Font.GothamBold
priceBox.TextScaled     = true
priceBox.PlaceholderText= "100"
priceBox.Text           = "100"
priceBox.Parent         = sellPanel
local priceCorner = Instance.new("UICorner")
priceCorner.CornerRadius = UDim.new(0, 6)
priceCorner.Parent = priceBox

-- Suggested price
local suggestedLabel = Instance.new("TextLabel")
suggestedLabel.Size    = UDim2.new(0.45, 0, 0, 30)
suggestedLabel.Position= UDim2.new(0.5, 10, 0, 210)
suggestedLabel.BackgroundTransparency = 1
suggestedLabel.TextColor3 = Color3.fromRGB(180, 200, 100)
suggestedLabel.Font    = Enum.Font.Gotham
suggestedLabel.TextScaled = true
suggestedLabel.Text    = "Market price: $?"
suggestedLabel.Parent  = sellPanel

local listBtn = Instance.new("TextButton")
listBtn.Size             = UDim2.new(0.45, 0, 0, 44)
listBtn.Position         = UDim2.new(0.5, 10, 0, 250)
listBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 200)
listBtn.BorderSizePixel  = 0
listBtn.TextColor3       = Color3.new(1,1,1)
listBtn.Font             = Enum.Font.GothamBold
listBtn.TextScaled       = true
listBtn.Text             = "🏷️ List for Sale"
listBtn.Parent           = sellPanel
local listBtnCorner = Instance.new("UICorner")
listBtnCorner.CornerRadius = UDim.new(0, 8)
listBtnCorner.Parent = listBtn

listBtn.MouseButton1Click:Connect(function()
    if not selectedSellItem then return end
    local qty   = tonumber(qtyBox.Text)   or 1
    local price = tonumber(priceBox.Text) or 100
    local ok, result = ListMarketItem:InvokeServer(selectedSellItem, qty, price)
    _ = ok
    _ = result
    populateInvScroll()
end)

-- ─── Populate Browse ──────────────────────────────────────────────────────────
local function populateBrowse()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if #currentListings == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size   = UDim2.new(1, 0, 0, 60)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.Font   = Enum.Font.Gotham
        emptyLabel.TextScaled = true
        emptyLabel.Text   = "No listings yet. Be the first to sell!"
        emptyLabel.Parent = scrollFrame
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 80)
        return
    end

    for _, listing in ipairs(currentListings) do
        local item = ItemData.ById[listing.itemId]
        local row = Instance.new("Frame")
        row.Name               = "Listing_" .. listing.id
        row.Size               = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3   = listing.sellerId == player.UserId
            and Color3.fromRGB(25, 40, 25) or Color3.fromRGB(22, 28, 45)
        row.BorderSizePixel    = 0
        row.Parent             = scrollFrame
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 6)
        rowCorner.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size          = UDim2.new(0.3, 0, 1, 0)
        nameLabel.Position      = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3    = Color3.new(1, 1, 1)
        nameLabel.Font          = Enum.Font.GothamBold
        nameLabel.TextScaled    = true
        nameLabel.TextXAlignment= Enum.TextXAlignment.Left
        nameLabel.Text          = (item and item.name or listing.itemId)
        nameLabel.Parent        = row

        local sellerLabel = Instance.new("TextLabel")
        sellerLabel.Size        = UDim2.new(0.22, 0, 1, 0)
        sellerLabel.Position    = UDim2.new(0.3, 0, 0, 0)
        sellerLabel.BackgroundTransparency = 1
        sellerLabel.TextColor3  = Color3.fromRGB(150, 180, 150)
        sellerLabel.Font        = Enum.Font.Gotham
        sellerLabel.TextScaled  = true
        sellerLabel.Text        = listing.sellerName
        sellerLabel.Parent      = row

        local qtyLabel2 = Instance.new("TextLabel")
        qtyLabel2.Size          = UDim2.new(0.12, 0, 1, 0)
        qtyLabel2.Position      = UDim2.new(0.52, 0, 0, 0)
        qtyLabel2.BackgroundTransparency = 1
        qtyLabel2.TextColor3    = Color3.fromRGB(180, 200, 180)
        qtyLabel2.Font          = Enum.Font.Gotham
        qtyLabel2.TextScaled    = true
        qtyLabel2.Text          = "x" .. listing.qty
        qtyLabel2.Parent        = row

        local priceLabel2 = Instance.new("TextLabel")
        priceLabel2.Size        = UDim2.new(0.18, 0, 1, 0)
        priceLabel2.Position    = UDim2.new(0.64, 0, 0, 0)
        priceLabel2.BackgroundTransparency = 1
        priceLabel2.TextColor3  = Color3.fromRGB(255, 215, 50)
        priceLabel2.Font        = Enum.Font.GothamBold
        priceLabel2.TextScaled  = true
        priceLabel2.Text        = "$" .. listing.price .. " ea"
        priceLabel2.Parent      = row

        if listing.sellerId ~= player.UserId then
            local buyBtn = Instance.new("TextButton")
            buyBtn.Size             = UDim2.new(0, 70, 0, 38)
            buyBtn.Position         = UDim2.new(1, -78, 0.5, -19)
            buyBtn.BackgroundColor3 = Color3.fromRGB(40, 130, 200)
            buyBtn.BorderSizePixel  = 0
            buyBtn.TextColor3       = Color3.new(1, 1, 1)
            buyBtn.Font             = Enum.Font.GothamBold
            buyBtn.TextScaled       = true
            buyBtn.Text             = "Buy"
            buyBtn.Parent           = row
            local buyBtnCorner = Instance.new("UICorner")
            buyBtnCorner.CornerRadius = UDim.new(0, 6)
            buyBtnCorner.Parent = buyBtn

            buyBtn.MouseButton1Click:Connect(function()
                local ok, result = BuyMarketItem:InvokeServer(listing.id)
                _ = ok
                _ = result
            end)
        end
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #currentListings * 58 + 16)
end

-- Tab switching
browseTab.MouseButton1Click:Connect(function()
    browseTab.BackgroundColor3 = Color3.fromRGB(30, 80, 150)
    sellTab.BackgroundColor3   = Color3.fromRGB(20, 20, 30)
    scrollFrame.Visible = true
    sellPanel.Visible   = false
    populateBrowse()
end)

sellTab.MouseButton1Click:Connect(function()
    sellTab.BackgroundColor3   = Color3.fromRGB(80, 50, 150)
    browseTab.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    scrollFrame.Visible = false
    sellPanel.Visible   = true
    populateInvScroll()
    -- Show suggested market price
    if selectedSellItem and currentPrices[selectedSellItem] then
        suggestedLabel.Text = "Market price: $" .. currentPrices[selectedSellItem]
    end
end)

-- ─── Show/Hide ────────────────────────────────────────────────────────────────
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if screenGui.Enabled then
        populateBrowse()
    end
end)

UpdateMarketPrices.OnClientEvent:Connect(function(prices, listings)
    currentPrices   = prices
    currentListings = listings or {}
    if screenGui.Enabled and scrollFrame.Visible then
        populateBrowse()
    end
end)

print("[MarketGui] Ready")
