-- AuctionMenu.client.lua
-- StarterGui
-- Browse active auctions, place bids, list items for auction, and claim winnings.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RE        = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

local gui           = Instance.new("ScreenGui")
gui.Name            = "AuctionMenu"
gui.ResetOnSpawn    = false
gui.DisplayOrder    = 20
gui.Enabled         = false
gui.Parent          = playerGui

local window        = Instance.new("Frame")
window.Size         = UDim2.new(0, 580, 0, 580)
window.Position     = UDim2.new(0.5, -290, 0.5, -290)
window.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
window.BackgroundTransparency = 0.05
window.BorderSizePixel = 0
window.Parent       = gui
Instance.new("UICorner").Parent = window

local title         = Instance.new("TextLabel")
title.Size          = UDim2.new(1, -44, 0, 50)
title.BackgroundTransparency = 1
title.Text          = "🔨 Auction House"
title.TextColor3    = Color3.new(1,1,1)
title.Font          = Enum.Font.GothamBold
title.TextScaled    = true
title.Parent        = window

local closeBtn      = Instance.new("TextButton")
closeBtn.Size       = UDim2.new(0, 36, 0, 36)
closeBtn.Position   = UDim2.new(1, -42, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text       = "✕"
closeBtn.Font       = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.Parent     = window
Instance.new("UICorner").Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- Tabs
local function makeTab(text, posX)
    local btn = Instance.new("TextButton")
    btn.Size  = UDim2.new(0, 130, 0, 34)
    btn.Position = UDim2.new(0, posX, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.Text  = text
    btn.Font  = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.BorderSizePixel = 0
    btn.Parent = window
    Instance.new("UICorner").Parent = btn
    return btn
end

local tabBrowse = makeTab("Browse", 5)
local tabList   = makeTab("List Item", 140)
tabBrowse.BackgroundColor3 = Color3.fromRGB(50, 120, 200)

local scroll    = Instance.new("ScrollingFrame")
scroll.Size     = UDim2.new(1, -10, 1, -100)
scroll.Position = UDim2.new(0, 5, 0, 92)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent   = window

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent  = scroll

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0,6) pad.PaddingRight = UDim.new(0,6)
pad.Parent      = scroll

-- List form (hidden by default)
local listForm  = Instance.new("Frame")
listForm.Size   = UDim2.new(1, -10, 1, -100)
listForm.Position = UDim2.new(0, 5, 0, 92)
listForm.BackgroundTransparency = 1
listForm.Visible = false
listForm.Parent  = window

local function makeInput(placeholder, posY)
    local box = Instance.new("TextBox")
    box.Size  = UDim2.new(1, -10, 0, 40)
    box.Position = UDim2.new(0, 5, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    box.PlaceholderText = placeholder
    box.Text  = ""
    box.TextColor3 = Color3.new(1,1,1)
    box.PlaceholderColor3 = Color3.fromRGB(130,130,130)
    box.Font  = Enum.Font.Gotham
    box.TextScaled = true
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = true
    box.Parent = listForm
    Instance.new("UICorner").Parent = box
    return box
end

local itemTypeBox   = makeInput("Item type: property or business", 10)
local itemRefBox    = makeInput("Item ID (plotId or businessId)", 60)
local startPriceBox = makeInput("Starting price ($)", 110)

local submitListBtn = Instance.new("TextButton")
submitListBtn.Size  = UDim2.new(0, 160, 0, 44)
submitListBtn.Position = UDim2.new(0.5, -80, 0, 162)
submitListBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
submitListBtn.Text  = "List Auction"
submitListBtn.Font  = Enum.Font.GothamBold
submitListBtn.TextScaled = true
submitListBtn.BorderSizePixel = 0
submitListBtn.Parent = listForm
Instance.new("UICorner").Parent = submitListBtn

submitListBtn.MouseButton1Click:Connect(function()
    RE.ListAuction:FireServer(itemTypeBox.Text, itemRefBox.Text, tonumber(startPriceBox.Text) or 100)
    itemTypeBox.Text = "" itemRefBox.Text = "" startPriceBox.Text = ""
end)

local currentTab = "browse"

local function clearScroll()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

-- ── Browse tab ────────────────────────────────────────────────────────────────
local function buildBrowseTab()
    clearScroll()
    local aucs = RE.GetAuctions:InvokeServer()
    if not aucs or #aucs == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size  = UDim2.new(1, 0, 0, 60)
        lbl.BackgroundTransparency = 1
        lbl.Text  = "No active auctions."
        lbl.TextColor3 = Color3.fromRGB(180,180,180)
        lbl.Font  = Enum.Font.Gotham
        lbl.TextScaled = true
        lbl.Parent = scroll
        return
    end
    for _, auc in ipairs(aucs) do
        local card = Instance.new("Frame")
        card.Size  = UDim2.new(1, 0, 0, 100)
        card.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        card.BorderSizePixel = 0
        card.Parent = scroll
        Instance.new("UICorner").Parent = card

        local infoLbl = Instance.new("TextLabel")
        infoLbl.Size  = UDim2.new(0.55, 0, 1, 0)
        infoLbl.Position = UDim2.new(0, 8, 0, 0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.Text  = "[" .. auc.itemType .. "] " .. tostring(auc.itemData.plotId or auc.itemData.businessId or "?") ..
                         "\nBid: $" .. auc.currentBid .. "  |  ⏱ " .. math.ceil(auc.timeLeft) .. "s"
        infoLbl.TextColor3 = Color3.new(1,1,1)
        infoLbl.Font  = Enum.Font.Gotham
        infoLbl.TextScaled = true
        infoLbl.TextWrapped = true
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.Parent = card

        local bidBox = Instance.new("TextBox")
        bidBox.Size  = UDim2.new(0, 100, 0, 34)
        bidBox.Position = UDim2.new(1, -220, 0.15, 0)
        bidBox.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        bidBox.PlaceholderText = "Amount"
        bidBox.Text  = ""
        bidBox.TextColor3 = Color3.new(1,1,1)
        bidBox.Font  = Enum.Font.Gotham
        bidBox.TextScaled = true
        bidBox.BorderSizePixel = 0
        bidBox.Parent = card
        Instance.new("UICorner").Parent = bidBox

        local bidBtn = Instance.new("TextButton")
        bidBtn.Size  = UDim2.new(0, 80, 0, 34)
        bidBtn.Position = UDim2.new(1, -110, 0.15, 0)
        bidBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 220)
        bidBtn.Text  = "Bid"
        bidBtn.Font  = Enum.Font.GothamBold
        bidBtn.TextScaled = true
        bidBtn.BorderSizePixel = 0
        bidBtn.Parent = card
        Instance.new("UICorner").Parent = bidBtn

        local claimBtn = Instance.new("TextButton")
        claimBtn.Size  = UDim2.new(0, 90, 0, 34)
        claimBtn.Position = UDim2.new(1, -98, 0.6, 0)
        claimBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        claimBtn.Text  = "Claim"
        claimBtn.Font  = Enum.Font.GothamBold
        claimBtn.TextScaled = true
        claimBtn.BorderSizePixel = 0
        claimBtn.Parent = card
        Instance.new("UICorner").Parent = claimBtn

        local aucId = auc.id
        bidBtn.MouseButton1Click:Connect(function()
            local amount = tonumber(bidBox.Text)
            if amount then RE.PlaceBid:FireServer(aucId, amount) end
        end)
        claimBtn.MouseButton1Click:Connect(function()
            RE.ClaimAuction:FireServer(aucId)
            task.wait(0.5)
            buildBrowseTab()
        end)
    end
end

tabBrowse.MouseButton1Click:Connect(function()
    currentTab = "browse"
    tabBrowse.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    tabList.BackgroundColor3   = Color3.fromRGB(40, 40, 60)
    scroll.Visible    = true
    listForm.Visible  = false
    buildBrowseTab()
end)

tabList.MouseButton1Click:Connect(function()
    currentTab = "list"
    tabList.BackgroundColor3   = Color3.fromRGB(50, 120, 200)
    tabBrowse.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    scroll.Visible   = false
    listForm.Visible = true
end)

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if gui.Enabled and currentTab == "browse" then buildBrowseTab() end
end)

print("[AuctionMenu] Loaded.")
