--[[
    InventoryGui.client.lua  (StarterGui)
    Browse collected brainrots grouped by rarity.
    Toggle with [I] key or the Inventory button in the HUD.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames  = require(Modules.RemoteEvents)
local RarityConfig = require(Modules.RarityConfig)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── ScreenGui ───────────────────────────────────────────────────────────────
local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "InventoryGui"
screenGui.DisplayOrder = 30
screenGui.ResetOnSpawn = false
screenGui.Parent       = PlayerGui

-- Main panel
local panel             = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 500, 0, 400)
panel.Position          = UDim2.new(0.5, -250, 0.5, -200)
panel.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0.05
panel.Visible           = false
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent       = panel

-- Title bar
local titleBar         = Instance.new("Frame")
titleBar.Size          = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel  = 0
titleBar.Parent        = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent       = titleBar

local titleLabel       = Instance.new("TextLabel")
titleLabel.Size        = UDim2.new(1, -60, 1, 0)
titleLabel.Position    = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text        = "🎒 Inventory"
titleLabel.TextColor3  = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled  = true
titleLabel.Font        = Enum.Font.GothamBold
titleLabel.Parent      = titleBar

local closeBtn         = Instance.new("TextButton")
closeBtn.Size          = UDim2.new(0, 40, 0, 40)
closeBtn.Position      = UDim2.new(1, -50, 0, 5)
closeBtn.Text          = "✕"
closeBtn.TextColor3    = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Font          = Enum.Font.GothamBold
closeBtn.TextScaled    = true
closeBtn.Parent        = titleBar

local closeBtnCorner   = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent  = closeBtn

-- Scroll frame for items
local scroll           = Instance.new("ScrollingFrame")
scroll.Size            = UDim2.new(1, -20, 1, -60)
scroll.Position        = UDim2.new(0, 10, 0, 55)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.Parent          = panel

local listLayout       = Instance.new("UIListLayout")
listLayout.SortOrder   = Enum.SortOrder.LayoutOrder
listLayout.Padding     = UDim.new(0, 6)
listLayout.Parent      = scroll

-- ─── Helper: build one item row ──────────────────────────────────────────────
local RARITY_COLORS = {
    Normal  = Color3.fromRGB(200, 200, 200),
    Golden  = Color3.fromRGB(255, 215, 0),
    Diamond = Color3.fromRGB(100, 220, 255),
}

local function makeItemRow(name, rarity, count, layoutOrder)
    local row           = Instance.new("Frame")
    row.Size            = UDim2.new(1, -10, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    row.LayoutOrder     = layoutOrder
    row.Parent          = scroll

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent       = row

    local rarityDot        = Instance.new("Frame")
    rarityDot.Size         = UDim2.new(0, 12, 0, 12)
    rarityDot.Position     = UDim2.new(0, 10, 0.5, -6)
    rarityDot.BackgroundColor3 = RARITY_COLORS[rarity] or Color3.fromRGB(200,200,200)
    rarityDot.BorderSizePixel = 0
    rarityDot.Parent       = row

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent       = rarityDot

    local nameLabel        = Instance.new("TextLabel")
    nameLabel.Size         = UDim2.new(0.7, 0, 1, 0)
    nameLabel.Position     = UDim2.new(0, 30, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text         = rarity .. " " .. name
    nameLabel.TextColor3   = RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
    nameLabel.TextScaled   = true
    nameLabel.Font         = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent       = row

    local countLabel       = Instance.new("TextLabel")
    countLabel.Size        = UDim2.new(0.2, 0, 1, 0)
    countLabel.Position    = UDim2.new(0.8, 0, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text        = "x" .. count
    countLabel.TextColor3  = Color3.fromRGB(200, 200, 200)
    countLabel.TextScaled  = true
    countLabel.Font        = Enum.Font.GothamSemibold
    countLabel.Parent      = row

    return row
end

-- ─── Rebuild inventory list ──────────────────────────────────────────────────
local currentInventory = {}

local function refreshInventory()
    -- Clear old rows
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local rows = {}
    for key, count in pairs(currentInventory) do
        -- key format: brainrotId_RarityName
        local sep      = key:find("_[^_]*$")
        local bId      = key:sub(1, sep - 1)
        local rarityN  = key:sub(sep + 1)
        local b        = RarityConfig.GetBrainrot(bId)
        local name     = b and b.Name or bId
        table.insert(rows, { name = name, rarity = rarityN, count = count })
    end

    -- Sort by rarity order then name
    local rarityOrder = {}
    for i, r in ipairs(RarityConfig.RARITIES) do rarityOrder[r.Name] = i end
    table.sort(rows, function(a, b)
        local ra = rarityOrder[a.rarity] or 99
        local rb = rarityOrder[b.rarity] or 99
        if ra ~= rb then return ra < rb end
        return a.name < b.name
    end)

    for i, row in ipairs(rows) do
        makeItemRow(row.name, row.rarity, row.count, i)
    end

    -- Adjust canvas size
    scroll.CanvasSize = UDim2.new(0, 0, 0,
        #rows * 46 + (#rows - 1) * 6
    )
end

-- ─── Toggle ──────────────────────────────────────────────────────────────────
local function toggle()
    panel.Visible = not panel.Visible
    if panel.Visible then refreshInventory() end
end

closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.I then toggle() end
end)

-- ─── Remote listener ─────────────────────────────────────────────────────────
RE(RemoteNames.UpdateInventory).OnClientEvent:Connect(function(inventory)
    currentInventory = inventory or {}
    if panel.Visible then refreshInventory() end
end)
