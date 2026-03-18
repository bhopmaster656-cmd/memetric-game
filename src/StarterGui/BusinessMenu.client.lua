-- BusinessMenu.client.lua
-- StarterGui
-- Browse, open, and close businesses.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RE         = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))
local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))

local gui           = Instance.new("ScreenGui")
gui.Name            = "BusinessMenu"
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
title.Text          = "🏪 Business Market"
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
local tabOpen   = Instance.new("TextButton")
tabOpen.Size    = UDim2.new(0.5, -3, 0, 36)
tabOpen.Position = UDim2.new(0, 3, 0, 53)
tabOpen.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
tabOpen.Text    = "Open Business"
tabOpen.Font    = Enum.Font.GothamBold
tabOpen.TextScaled = true
tabOpen.BorderSizePixel = 0
tabOpen.Parent  = window
Instance.new("UICorner").Parent = tabOpen

local tabMine   = Instance.new("TextButton")
tabMine.Size    = UDim2.new(0.5, -3, 0, 36)
tabMine.Position = UDim2.new(0.5, 0, 0, 53)
tabMine.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
tabMine.Text    = "My Businesses"
tabMine.Font    = Enum.Font.GothamBold
tabMine.TextScaled = true
tabMine.BorderSizePixel = 0
tabMine.Parent  = window
Instance.new("UICorner").Parent = tabMine

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

local currentTab = "open"

local function clearScroll()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function buildOpenTab()
    clearScroll()
    for _, biz in ipairs(GameConfig.Businesses) do
        local card = Instance.new("Frame")
        card.Size  = UDim2.new(1, 0, 0, 90)
        card.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
        card.BorderSizePixel = 0
        card.Parent = scroll
        Instance.new("UICorner").Parent = card

        local nl = Instance.new("TextLabel")
        nl.Size  = UDim2.new(0.62, 0, 0.45, 0)
        nl.Position = UDim2.new(0, 8, 0, 4)
        nl.BackgroundTransparency = 1
        nl.Text  = biz.name
        nl.TextColor3 = Color3.new(1,1,1)
        nl.Font  = Enum.Font.GothamBold
        nl.TextScaled = true
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Parent = card

        local il = Instance.new("TextLabel")
        il.Size  = UDim2.new(0.62, 0, 0.5, 0)
        il.Position = UDim2.new(0, 8, 0.48, 0)
        il.BackgroundTransparency = 1
        il.Text  = "Cost: $"..biz.cost.."  |  📈 +$"..biz.incomePerMin.."/min  |  Tax: "..math.floor(biz.taxRate*100).."%"
        il.TextColor3 = Color3.fromRGB(180, 230, 180)
        il.Font  = Enum.Font.Gotham
        il.TextScaled = true
        il.TextXAlignment = Enum.TextXAlignment.Left
        il.Parent = card

        local openBtn = Instance.new("TextButton")
        openBtn.Size  = UDim2.new(0, 100, 0, 40)
        openBtn.Position = UDim2.new(1, -108, 0.5, -20)
        openBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        openBtn.Text  = "Open"
        openBtn.Font  = Enum.Font.GothamBold
        openBtn.TextScaled = true
        openBtn.BorderSizePixel = 0
        openBtn.Parent = card
        Instance.new("UICorner").Parent = openBtn

        openBtn.MouseButton1Click:Connect(function()
            RE.OpenBusiness:FireServer(biz.id)
        end)
    end
end

local function buildMineTab()
    clearScroll()
    local businesses = RE.GetMyBusinesses:InvokeServer()
    if not businesses or #businesses == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size  = UDim2.new(1, 0, 0, 60)
        lbl.BackgroundTransparency = 1
        lbl.Text  = "You don't own any businesses yet."
        lbl.TextColor3 = Color3.fromRGB(180,180,180)
        lbl.Font  = Enum.Font.Gotham
        lbl.TextScaled = true
        lbl.Parent = scroll
        return
    end
    for _, entry in ipairs(businesses) do
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
        nl.Text  = entry.type .. " | Revenue: $" .. (entry.revenue or 0)
        nl.TextColor3 = Color3.new(1,1,1)
        nl.Font  = Enum.Font.Gotham
        nl.TextScaled = true
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Parent = card

        local closeBusinessBtn = Instance.new("TextButton")
        closeBusinessBtn.Size  = UDim2.new(0, 90, 0, 36)
        closeBusinessBtn.Position = UDim2.new(1, -98, 0.5, -18)
        closeBusinessBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        closeBusinessBtn.Text  = "Close (60%)"
        closeBusinessBtn.Font  = Enum.Font.GothamBold
        closeBusinessBtn.TextScaled = true
        closeBusinessBtn.BorderSizePixel = 0
        closeBusinessBtn.Parent = card
        Instance.new("UICorner").Parent = closeBusinessBtn

        closeBusinessBtn.MouseButton1Click:Connect(function()
            RE.CloseBusiness:FireServer(entry.businessId)
            buildMineTab()
        end)
    end
end

tabOpen.MouseButton1Click:Connect(function()
    currentTab = "open"
    tabOpen.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    tabMine.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    buildOpenTab()
end)
tabMine.MouseButton1Click:Connect(function()
    currentTab = "mine"
    tabMine.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    tabOpen.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    buildMineTab()
end)

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if gui.Enabled then
        if currentTab == "open" then buildOpenTab() else buildMineTab() end
    end
end)

print("[BusinessMenu] Loaded.")
