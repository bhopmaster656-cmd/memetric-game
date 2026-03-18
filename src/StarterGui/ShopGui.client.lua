--[[
    ShopGui.client.lua  (StarterGui)
    Browse and purchase brainrot packs and gamepasses.
    Toggle with [P] key.
--]]

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local MarketplaceService  = game:GetService("MarketplaceService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(Modules.RemoteEvents)
local ShopConfig  = require(Modules.ShopConfig)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end  -- luacheck: ignore

local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── ScreenGui ───────────────────────────────────────────────────────────────
local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "ShopGui"
screenGui.DisplayOrder = 30
screenGui.ResetOnSpawn = false
screenGui.Parent       = PlayerGui

local panel             = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 520, 0, 560)
panel.Position          = UDim2.new(0.5, -260, 0.5, -280)
panel.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0.05
panel.Visible           = false
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent       = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size  = UDim2.new(1, -60, 0, 50)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text  = "🛒 Shop"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font  = Enum.Font.GothamBold
titleLabel.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size   = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 5)
closeBtn.Text   = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Font   = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.Parent = panel

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- Tab buttons
local tabPacks = Instance.new("TextButton")
tabPacks.Size  = UDim2.new(0.5, -5, 0, 38)
tabPacks.Position = UDim2.new(0, 5, 0, 55)
tabPacks.Text  = "📦 Packs"
tabPacks.BackgroundColor3 = Color3.fromRGB(80, 50, 150)
tabPacks.TextColor3 = Color3.fromRGB(255,255,255)
tabPacks.Font  = Enum.Font.GothamBold
tabPacks.TextScaled = true
tabPacks.Parent = panel

local tabPacksCorner = Instance.new("UICorner")
tabPacksCorner.CornerRadius = UDim.new(0, 8)
tabPacksCorner.Parent = tabPacks

local tabPasses = Instance.new("TextButton")
tabPasses.Size  = UDim2.new(0.5, -5, 0, 38)
tabPasses.Position = UDim2.new(0.5, 0, 0, 55)
tabPasses.Text  = "👑 Gamepasses"
tabPasses.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tabPasses.TextColor3 = Color3.fromRGB(200,200,200)
tabPasses.Font  = Enum.Font.GothamBold
tabPasses.TextScaled = true
tabPasses.Parent = panel

local tabPassesCorner = Instance.new("UICorner")
tabPassesCorner.CornerRadius = UDim.new(0, 8)
tabPassesCorner.Parent = tabPasses

-- Scroll area
local scroll = Instance.new("ScrollingFrame")
scroll.Size  = UDim2.new(1, -20, 1, -110)
scroll.Position = UDim2.new(0, 10, 0, 100)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding   = UDim.new(0, 8)
listLayout.Parent    = scroll

-- ─── Card builder ────────────────────────────────────────────────────────────
local function makeCard(name, desc, priceStr, order, onBuy)
    local card = Instance.new("Frame")
    card.Size  = UDim2.new(1, -10, 0, 90)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    card.LayoutOrder = order
    card.Parent = scroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size  = UDim2.new(0.65, 0, 0.45, 0)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text  = name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font  = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size  = UDim2.new(0.65, 0, 0.45, 0)
    descLabel.Position = UDim2.new(0, 10, 0.5, 0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text  = desc
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextScaled = true
    descLabel.Font  = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = card

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size  = UDim2.new(0.28, 0, 0.65, 0)
    buyBtn.Position = UDim2.new(0.7, 0, 0.17, 0)
    buyBtn.Text  = "🛒 " .. priceStr .. " Robux"
    buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    buyBtn.Font  = Enum.Font.GothamBold
    buyBtn.TextScaled = true
    buyBtn.Parent = card

    local buyBtnCorner = Instance.new("UICorner")
    buyBtnCorner.CornerRadius = UDim.new(0, 8)
    buyBtnCorner.Parent = buyBtn

    buyBtn.MouseButton1Click:Connect(onBuy)
    return card
end

-- ─── Populate tabs ───────────────────────────────────────────────────────────
local function clearScroll()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function showPacks()
    clearScroll()
    tabPacks.BackgroundColor3  = Color3.fromRGB(80, 50, 150)
    tabPasses.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    for i, pack in ipairs(ShopConfig.PACKS) do
        makeCard(pack.Name, pack.Description, tostring(pack.Price), i, function()
            if pack.ProductId ~= 0 then
                MarketplaceService:PromptProductPurchase(localPlayer, pack.ProductId)
            end
        end)
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0,
        #ShopConfig.PACKS * 98 + (#ShopConfig.PACKS - 1) * 8
    )
end

local function showGamepasses()
    clearScroll()
    tabPacks.BackgroundColor3  = Color3.fromRGB(40, 40, 40)
    tabPasses.BackgroundColor3 = Color3.fromRGB(80, 50, 150)
    for i, gp in ipairs(ShopConfig.GAMEPASSES) do
        makeCard(gp.Name, gp.Description, tostring(gp.Price), i, function()
            if gp.GamePassId ~= 0 then
                MarketplaceService:PromptGamePassPurchase(localPlayer, gp.GamePassId)
            end
        end)
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0,
        #ShopConfig.GAMEPASSES * 98 + (#ShopConfig.GAMEPASSES - 1) * 8
    )
end

tabPacks.MouseButton1Click:Connect(showPacks)
tabPasses.MouseButton1Click:Connect(showGamepasses)

-- ─── Toggle ──────────────────────────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.P then
        panel.Visible = not panel.Visible
        if panel.Visible then showPacks() end
    end
end)
