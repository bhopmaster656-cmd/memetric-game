-- StarterGui/ShopGui/Script.client.lua
-- Government Store & Café shop interface.
-- Shows item list with prices, allows buying/selling.

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local screenGui = script.Parent
screenGui.Enabled = false

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemData     = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemData"))
local EconomyModule= require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EconomyModule"))

local RemoteEvents   = ReplicatedStorage:WaitForChild("RemoteEvents")
local PurchaseItem   = RemoteEvents:WaitForChild("PurchaseItem")
local SellItem       = RemoteEvents:WaitForChild("SellItem")
local NotifyPlayer   = RemoteEvents:WaitForChild("NotifyPlayer")
local UpdateInventory= RemoteEvents:WaitForChild("UpdateInventory")

local currentShopType = "GovStore"
local currentPrices   = {}  -- Updated from UpdateMarketPrices
local playerInventory = {}

UpdateInventory.OnClientEvent:Connect(function(inv)
    playerInventory = inv
end)

RemoteEvents:WaitForChild("UpdateMarketPrices").OnClientEvent:Connect(function(prices)
    currentPrices = prices
end)

-- ─── Build UI ─────────────────────────────────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name                = "ShopFrame"
mainFrame.Size                = UDim2.new(0, 600, 0, 500)
mainFrame.Position            = UDim2.new(0.5, -300, 0.5, -250)
mainFrame.BackgroundColor3    = Color3.fromRGB(18, 28, 22)
mainFrame.BorderSizePixel     = 0
mainFrame.Parent              = screenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title
local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = mainFrame
local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 12)
titleBarCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name            = "Title"
titleLabel.Size            = UDim2.new(1, -60, 1, 0)
titleLabel.Position        = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3      = Color3.new(1, 1, 1)
titleLabel.Font            = Enum.Font.GothamBold
titleLabel.TextScaled      = true
titleLabel.TextXAlignment  = Enum.TextXAlignment.Left
titleLabel.Text            = "🏪 Government Store"
titleLabel.Parent          = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name              = "CloseBtn"
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
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- Tab buttons (Buy / Sell)
local tabBar = Instance.new("Frame")
tabBar.Size            = UDim2.new(1, 0, 0, 36)
tabBar.Position        = UDim2.new(0, 0, 0, 50)
tabBar.BackgroundColor3= Color3.fromRGB(12, 20, 15)
tabBar.BorderSizePixel = 0
tabBar.Parent          = mainFrame

local buyTabBtn = Instance.new("TextButton")
buyTabBtn.Name             = "BuyTab"
buyTabBtn.Size             = UDim2.new(0.5, 0, 1, 0)
buyTabBtn.Position         = UDim2.new(0, 0, 0, 0)
buyTabBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
buyTabBtn.BorderSizePixel  = 0
buyTabBtn.TextColor3       = Color3.new(1, 1, 1)
buyTabBtn.Font             = Enum.Font.GothamBold
buyTabBtn.TextScaled       = true
buyTabBtn.Text             = "🛒 Buy"
buyTabBtn.Parent           = tabBar

local sellTabBtn = Instance.new("TextButton")
sellTabBtn.Name            = "SellTab"
sellTabBtn.Size            = UDim2.new(0.5, 0, 1, 0)
sellTabBtn.Position        = UDim2.new(0.5, 0, 0, 0)
sellTabBtn.BackgroundColor3= Color3.fromRGB(25, 25, 35)
sellTabBtn.BorderSizePixel = 0
sellTabBtn.TextColor3      = Color3.fromRGB(180, 180, 180)
sellTabBtn.Font            = Enum.Font.GothamBold
sellTabBtn.TextScaled      = true
sellTabBtn.Text            = "💰 Sell"
sellTabBtn.Parent          = tabBar

-- Scroll frame for items
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name             = "ItemList"
scrollFrame.Size             = UDim2.new(1, 0, 1, -100)
scrollFrame.Position         = UDim2.new(0, 0, 0, 86)
scrollFrame.BackgroundColor3 = Color3.fromRGB(12, 20, 15)
scrollFrame.BorderSizePixel  = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize       = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent           = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding        = UDim.new(0, 4)
listLayout.Parent         = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingLeft  = UDim.new(0, 8)
listPadding.PaddingRight = UDim.new(0, 8)
listPadding.PaddingTop   = UDim.new(0, 8)
listPadding.Parent       = scrollFrame

-- ─── Populate Items ───────────────────────────────────────────────────────────
local currentTab   = "Buy"
local activeItems  = {}  -- For sell tab: { id, qty } pairs from inventory

local shopCategories = {
    GovStore = {
        ItemData.CATEGORY.RESOURCE,
        ItemData.CATEGORY.FOOD,
        ItemData.CATEGORY.DRINK,
        ItemData.CATEGORY.TOOL,
        ItemData.CATEGORY.CLOTHING,
        ItemData.CATEGORY.MEDICAL,
        ItemData.CATEGORY.SEED,
        ItemData.CATEGORY.FURNITURE,
    },
    Cafe = {
        ItemData.CATEGORY.FOOD,
        ItemData.CATEGORY.DRINK,
    },
}

local function clearItems()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function createItemRow(itemId, name, price, qty, actionText, actionCallback)
    local row = Instance.new("Frame")
    row.Name               = "Row_" .. itemId
    row.Size               = UDim2.new(1, 0, 0, 52)
    row.BackgroundColor3   = Color3.fromRGB(22, 35, 28)
    row.BorderSizePixel    = 0
    row.Parent             = scrollFrame
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size          = UDim2.new(0.45, 0, 1, 0)
    nameLabel.Position      = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3    = Color3.new(1, 1, 1)
    nameLabel.Font          = Enum.Font.Gotham
    nameLabel.TextScaled    = true
    nameLabel.TextXAlignment= Enum.TextXAlignment.Left
    nameLabel.Text          = name
    nameLabel.Parent        = row

    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size         = UDim2.new(0.25, 0, 1, 0)
    priceLabel.Position     = UDim2.new(0.45, 0, 0, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.TextColor3   = Color3.fromRGB(255, 215, 50)
    priceLabel.Font         = Enum.Font.GothamBold
    priceLabel.TextScaled   = true
    priceLabel.Text         = "$" .. price
    priceLabel.Parent       = row

    if qty then
        local qtyLabel = Instance.new("TextLabel")
        qtyLabel.Size          = UDim2.new(0.12, 0, 1, 0)
        qtyLabel.Position      = UDim2.new(0.7, 0, 0, 0)
        qtyLabel.BackgroundTransparency = 1
        qtyLabel.TextColor3    = Color3.fromRGB(180, 200, 180)
        qtyLabel.Font          = Enum.Font.Gotham
        qtyLabel.TextScaled    = true
        qtyLabel.Text          = "x" .. qty
        qtyLabel.Parent        = row
    end

    local actionBtn = Instance.new("TextButton")
    actionBtn.Size             = UDim2.new(0, 70, 0, 36)
    actionBtn.Position         = UDim2.new(1, -78, 0.5, -18)
    actionBtn.BackgroundColor3 = actionText == "Buy" and Color3.fromRGB(40, 160, 70) or Color3.fromRGB(200, 100, 30)
    actionBtn.BorderSizePixel  = 0
    actionBtn.TextColor3       = Color3.new(1, 1, 1)
    actionBtn.Font             = Enum.Font.GothamBold
    actionBtn.TextScaled       = true
    actionBtn.Text             = actionText
    actionBtn.Parent           = row
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = actionBtn

    actionBtn.MouseButton1Click:Connect(actionCallback)
    return row
end

local function populateBuyTab()
    clearItems()
    local allowed = shopCategories[currentShopType] or shopCategories.GovStore
    local allowedSet = {}
    for _, cat in ipairs(allowed) do allowedSet[cat] = true end

    for _, item in ipairs(ItemData.Catalog) do
        if allowedSet[item.category] and GameConfig.BaseItemPrices[item.id] then
            local dynPrice = currentPrices[item.id] or GameConfig.BaseItemPrices[item.id]
            createItemRow(item.id, item.name, dynPrice, nil, "Buy", function()
                local ok, msg = PurchaseItem:InvokeServer(item.id, 1)
                if not ok then
                    NotifyPlayer:FireServer and nil  -- server handles notifications
                end
            end)
        end
    end

    -- Update canvas size
    local rowCount = #scrollFrame:GetChildren() - 2  -- subtract layout and padding
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rowCount * 56 + 16)
end

local function populateSellTab()
    clearItems()
    for _, slot in ipairs(playerInventory) do
        local item = ItemData.ById[slot.id]
        if item and GameConfig.BaseItemPrices[slot.id] then
            local dynPrice = currentPrices[slot.id] or GameConfig.BaseItemPrices[slot.id]
            local sellPrice = math.floor(dynPrice * 0.6)
            createItemRow(slot.id, (item and item.name or slot.id), sellPrice, slot.qty, "Sell", function()
                local ok, msg = SellItem:InvokeServer(slot.id, 1)
                _ = ok
                _ = msg
            end)
        end
    end
    local rowCount = #scrollFrame:GetChildren() - 2
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rowCount * 56 + 16)
end

buyTabBtn.MouseButton1Click:Connect(function()
    currentTab = "Buy"
    buyTabBtn.BackgroundColor3  = Color3.fromRGB(40, 140, 70)
    sellTabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    populateBuyTab()
end)

sellTabBtn.MouseButton1Click:Connect(function()
    currentTab = "Sell"
    sellTabBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
    buyTabBtn.BackgroundColor3  = Color3.fromRGB(25, 25, 35)
    populateSellTab()
end)

-- ─── Show/Hide ────────────────────────────────────────────────────────────────
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if screenGui.Enabled then
        currentShopType = screenGui:GetAttribute("ShopType") or "GovStore"
        if currentShopType == "Cafe" then
            titleLabel.Text = "☕ Café"
        else
            titleLabel.Text = "🏪 Government Store"
        end
        populateBuyTab()
    end
end)

-- Also refresh when inventory updates (for sell tab)
UpdateInventory.OnClientEvent:Connect(function(inv)
    playerInventory = inv
    if screenGui.Enabled and currentTab == "Sell" then
        populateSellTab()
    end
end)

print("[ShopGui] Ready")
