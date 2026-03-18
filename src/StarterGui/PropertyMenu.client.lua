-- PropertyMenu.client.lua
-- StarterGui
-- Browse available property types, buy or sell.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RE         = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))
local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))

-- ── Screen Gui ────────────────────────────────────────────────────────────────
local gui           = Instance.new("ScreenGui")
gui.Name            = "PropertyMenu"
gui.ResetOnSpawn    = false
gui.DisplayOrder    = 20
gui.Enabled         = false
gui.Parent          = playerGui

local window        = Instance.new("Frame")
window.Size         = UDim2.new(0, 540, 0, 560)
window.Position     = UDim2.new(0.5, -270, 0.5, -280)
window.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
window.BackgroundTransparency = 0.05
window.BorderSizePixel = 0
window.Parent       = gui
Instance.new("UICorner").Parent = window

local title         = Instance.new("TextLabel")
title.Size          = UDim2.new(1, -44, 0, 50)
title.BackgroundTransparency = 1
title.Text          = "🏠 Real Estate Market"
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

-- Tabs: Buy | My Properties
local tabBuy    = Instance.new("TextButton")
tabBuy.Size     = UDim2.new(0.5, -3, 0, 36)
tabBuy.Position = UDim2.new(0, 3, 0, 53)
tabBuy.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
tabBuy.Text     = "Buy"
tabBuy.Font     = Enum.Font.GothamBold
tabBuy.TextScaled = true
tabBuy.BorderSizePixel = 0
tabBuy.Parent   = window
Instance.new("UICorner").Parent = tabBuy

local tabOwned  = Instance.new("TextButton")
tabOwned.Size   = UDim2.new(0.5, -3, 0, 36)
tabOwned.Position = UDim2.new(0.5, 0, 0, 53)
tabOwned.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
tabOwned.Text   = "My Properties"
tabOwned.Font   = Enum.Font.GothamBold
tabOwned.TextScaled = true
tabOwned.BorderSizePixel = 0
tabOwned.Parent = window
Instance.new("UICorner").Parent = tabOwned

local scroll    = Instance.new("ScrollingFrame")
scroll.Size     = UDim2.new(1, -10, 1, -100)
scroll.Position = UDim2.new(0, 5, 0, 94)
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
pad.PaddingLeft  = UDim.new(0,6) pad.PaddingRight = UDim.new(0,6)
pad.Parent       = scroll

local currentTab = "buy"

local function clearScroll()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

-- ── Buy tab ───────────────────────────────────────────────────────────────────
local function buildBuyTab()
    clearScroll()
    for _, prop in ipairs(GameConfig.Properties) do
        local card = Instance.new("Frame")
        card.Size  = UDim2.new(1, 0, 0, 80)
        card.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
        card.BorderSizePixel = 0
        card.Parent = scroll
        Instance.new("UICorner").Parent = card

        local nl = Instance.new("TextLabel")
        nl.Size  = UDim2.new(0.6, 0, 0.45, 0)
        nl.Position = UDim2.new(0, 8, 0, 4)
        nl.BackgroundTransparency = 1
        nl.Text  = prop.name
        nl.TextColor3 = Color3.new(1,1,1)
        nl.Font  = Enum.Font.GothamBold
        nl.TextScaled = true
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Parent = card

        local pl = Instance.new("TextLabel")
        pl.Size  = UDim2.new(0.6, 0, 0.45, 0)
        pl.Position = UDim2.new(0, 8, 0.5, 0)
        pl.BackgroundTransparency = 1
        pl.Text  = "💰 $" .. prop.price .. "  |  Tax: " .. math.floor(prop.taxRate*100) .. "% per cycle"
        pl.TextColor3 = Color3.fromRGB(180, 230, 180)
        pl.Font  = Enum.Font.Gotham
        pl.TextScaled = true
        pl.TextXAlignment = Enum.TextXAlignment.Left
        pl.Parent = card

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size  = UDim2.new(0, 100, 0, 40)
        buyBtn.Position = UDim2.new(1, -108, 0.5, -20)
        buyBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        buyBtn.Text  = "Buy"
        buyBtn.Font  = Enum.Font.GothamBold
        buyBtn.TextScaled = true
        buyBtn.BorderSizePixel = 0
        buyBtn.Parent = card
        Instance.new("UICorner").Parent = buyBtn

        buyBtn.MouseButton1Click:Connect(function()
            -- Use plot_1 as a default (real integration uses nearby plot detection)
            RE.BuyProperty:FireServer(prop.id, "plot_1")
        end)
    end
end

-- ── My Properties tab ─────────────────────────────────────────────────────────
local function buildOwnedTab()
    clearScroll()
    local owned = RE.GetMyProperties:InvokeServer()
    if not owned or #owned == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size  = UDim2.new(1, 0, 0, 60)
        lbl.BackgroundTransparency = 1
        lbl.Text  = "You don't own any properties yet."
        lbl.TextColor3 = Color3.fromRGB(180,180,180)
        lbl.Font  = Enum.Font.Gotham
        lbl.TextScaled = true
        lbl.Parent = scroll
        return
    end
    for _, entry in ipairs(owned) do
        local card = Instance.new("Frame")
        card.Size  = UDim2.new(1, 0, 0, 70)
        card.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
        card.BorderSizePixel = 0
        card.Parent = scroll
        Instance.new("UICorner").Parent = card

        local nl = Instance.new("TextLabel")
        nl.Size  = UDim2.new(0.6, 0, 1, 0)
        nl.Position = UDim2.new(0, 8, 0, 0)
        nl.BackgroundTransparency = 1
        nl.Text  = entry.type .. " – Plot " .. entry.plotId
        nl.TextColor3 = Color3.new(1,1,1)
        nl.Font  = Enum.Font.Gotham
        nl.TextScaled = true
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Parent = card

        local sellBtn = Instance.new("TextButton")
        sellBtn.Size  = UDim2.new(0, 90, 0, 36)
        sellBtn.Position = UDim2.new(1, -98, 0.5, -18)
        sellBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        sellBtn.Text  = "Sell (70%)"
        sellBtn.Font  = Enum.Font.GothamBold
        sellBtn.TextScaled = true
        sellBtn.BorderSizePixel = 0
        sellBtn.Parent = card
        Instance.new("UICorner").Parent = sellBtn

        sellBtn.MouseButton1Click:Connect(function()
            RE.SellProperty:FireServer(entry.plotId)
            buildOwnedTab()
        end)
    end
end

tabBuy.MouseButton1Click:Connect(function()
    currentTab = "buy"
    tabBuy.BackgroundColor3    = Color3.fromRGB(50, 120, 200)
    tabOwned.BackgroundColor3  = Color3.fromRGB(40, 40, 60)
    buildBuyTab()
end)

tabOwned.MouseButton1Click:Connect(function()
    currentTab = "owned"
    tabOwned.BackgroundColor3  = Color3.fromRGB(50, 120, 200)
    tabBuy.BackgroundColor3    = Color3.fromRGB(40, 40, 60)
    buildOwnedTab()
end)

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if gui.Enabled then
        if currentTab == "buy" then buildBuyTab() else buildOwnedTab() end
    end
end)

print("[PropertyMenu] Loaded.")
