-- ShopMenu.client.lua
-- StarterGui
-- Robux store: buy cash packs and game passes.

local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RS                 = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))

local gui           = Instance.new("ScreenGui")
gui.Name            = "ShopMenu"
gui.ResetOnSpawn    = false
gui.DisplayOrder    = 20
gui.Enabled         = false
gui.Parent          = playerGui

local window        = Instance.new("Frame")
window.Size         = UDim2.new(0, 520, 0, 560)
window.Position     = UDim2.new(0.5, -260, 0.5, -280)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
window.BackgroundTransparency = 0.05
window.BorderSizePixel = 0
window.Parent       = gui
Instance.new("UICorner").Parent = window

local title         = Instance.new("TextLabel")
title.Size          = UDim2.new(1, -44, 0, 50)
title.BackgroundTransparency = 1
title.Text          = "🛒 Robux Store"
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

-- Section: Cash Packs
local sectionLbl    = Instance.new("TextLabel")
sectionLbl.Size     = UDim2.new(1, -10, 0, 30)
sectionLbl.Position = UDim2.new(0, 5, 0, 52)
sectionLbl.BackgroundTransparency = 1
sectionLbl.Text     = "💰 Cash Packs"
sectionLbl.TextColor3 = Color3.fromRGB(80, 220, 130)
sectionLbl.Font     = Enum.Font.GothamBold
sectionLbl.TextScaled = true
sectionLbl.TextXAlignment = Enum.TextXAlignment.Left
sectionLbl.Parent   = window

local scroll        = Instance.new("ScrollingFrame")
scroll.Size         = UDim2.new(1, -10, 1, -100)
scroll.Position     = UDim2.new(0, 5, 0, 86)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.BorderSizePixel = 0
scroll.CanvasSize   = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent       = window

local listLayout    = Instance.new("UIListLayout")
listLayout.Padding  = UDim.new(0, 6)
listLayout.Parent   = scroll

local pad = Instance.new("UIPadding")
pad.PaddingLeft  = UDim.new(0,6) pad.PaddingRight = UDim.new(0,6)
pad.Parent       = scroll

-- Cash pack cards
for _, prod in ipairs(GameConfig.DevProducts) do
    local card = Instance.new("Frame")
    card.Size  = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
    card.BorderSizePixel = 0
    card.Parent = scroll
    Instance.new("UICorner").Parent = card

    local nl = Instance.new("TextLabel")
    nl.Size  = UDim2.new(0.55, 0, 0.5, 0)
    nl.Position = UDim2.new(0, 8, 0, 4)
    nl.BackgroundTransparency = 1
    nl.Text  = prod.name
    nl.TextColor3 = Color3.new(1,1,1)
    nl.Font  = Enum.Font.GothamBold
    nl.TextScaled = true
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.Parent = card

    local il = Instance.new("TextLabel")
    il.Size  = UDim2.new(0.55, 0, 0.45, 0)
    il.Position = UDim2.new(0, 8, 0.5, 0)
    il.BackgroundTransparency = 1
    il.Text  = "+$" .. prod.cash .. " in-game cash"
    il.TextColor3 = Color3.fromRGB(180, 240, 180)
    il.Font  = Enum.Font.Gotham
    il.TextScaled = true
    il.TextXAlignment = Enum.TextXAlignment.Left
    il.Parent = card

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size  = UDim2.new(0, 110, 0, 40)
    buyBtn.Position = UDim2.new(1, -118, 0.5, -20)
    buyBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    buyBtn.Text  = "R$ " .. prod.price
    buyBtn.Font  = Enum.Font.GothamBold
    buyBtn.TextScaled = true
    buyBtn.BorderSizePixel = 0
    buyBtn.Parent = card
    Instance.new("UICorner").Parent = buyBtn

    local prodId = prod.id
    buyBtn.MouseButton1Click:Connect(function()
        if prodId == 0 then
            -- Placeholder: show message until real IDs are set
            print("[ShopMenu] Purchase attempted for placeholder product:", prod.name)
        else
            MarketplaceService:PromptProductPurchase(player, prodId)
        end
    end)
end

-- Separator
local sep = Instance.new("Frame")
sep.Size  = UDim2.new(1, 0, 0, 2)
sep.BackgroundColor3 = Color3.fromRGB(60,60,80)
sep.BorderSizePixel = 0
sep.Parent = scroll

-- Game Pass section header
local passHeader = Instance.new("TextLabel")
passHeader.Size  = UDim2.new(1, 0, 0, 30)
passHeader.BackgroundTransparency = 1
passHeader.Text  = "⭐ Game Passes"
passHeader.TextColor3 = Color3.fromRGB(255, 200, 50)
passHeader.Font  = Enum.Font.GothamBold
passHeader.TextScaled = true
passHeader.TextXAlignment = Enum.TextXAlignment.Left
passHeader.Parent = scroll

-- Game pass cards
for _, pass in ipairs(GameConfig.GamePasses) do
    local card = Instance.new("Frame")
    card.Size  = UDim2.new(1, 0, 0, 80)
    card.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    card.BorderSizePixel = 0
    card.Parent = scroll
    Instance.new("UICorner").Parent = card

    local nl = Instance.new("TextLabel")
    nl.Size  = UDim2.new(0.65, 0, 0.45, 0)
    nl.Position = UDim2.new(0, 8, 0, 4)
    nl.BackgroundTransparency = 1
    nl.Text  = pass.name
    nl.TextColor3 = Color3.fromRGB(255, 220, 80)
    nl.Font  = Enum.Font.GothamBold
    nl.TextScaled = true
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.Parent = card

    local dl = Instance.new("TextLabel")
    dl.Size  = UDim2.new(0.65, 0, 0.45, 0)
    dl.Position = UDim2.new(0, 8, 0.5, 0)
    dl.BackgroundTransparency = 1
    dl.Text  = pass.description
    dl.TextColor3 = Color3.fromRGB(200,200,200)
    dl.Font  = Enum.Font.Gotham
    dl.TextScaled = true
    dl.TextXAlignment = Enum.TextXAlignment.Left
    dl.Parent = card

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size  = UDim2.new(0, 90, 0, 40)
    buyBtn.Position = UDim2.new(1, -98, 0.5, -20)
    buyBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    buyBtn.Text  = "Get Pass"
    buyBtn.Font  = Enum.Font.GothamBold
    buyBtn.TextColor3 = Color3.fromRGB(30, 20, 0)
    buyBtn.TextScaled = true
    buyBtn.BorderSizePixel = 0
    buyBtn.Parent = card
    Instance.new("UICorner").Parent = buyBtn

    local passId = pass.id
    buyBtn.MouseButton1Click:Connect(function()
        if passId == 0 then
            print("[ShopMenu] Game pass purchase attempted for placeholder:", pass.name)
        else
            MarketplaceService:PromptGamePassPurchase(player, passId)
        end
    end)
end

print("[ShopMenu] Loaded.")
