-- MainHUD.client.lua
-- StarterGui
-- Displays the player's cash, job, and quick-access buttons.

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")

local player       = Players.LocalPlayer
local playerGui    = player:WaitForChild("PlayerGui")

local RE           = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- ── Build ScreenGui ───────────────────────────────────────────────────────────
local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "MainHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent       = playerGui

-- ── Notification queue ────────────────────────────────────────────────────────
local notifQueue = {}
local notifActive = false

local notifColors = {
    info      = Color3.fromRGB(60, 120, 200),
    warn      = Color3.fromRGB(220, 160, 0),
    error     = Color3.fromRGB(200, 50, 50),
    success   = Color3.fromRGB(50, 190, 80),
    salary    = Color3.fromRGB(50, 200, 150),
    business  = Color3.fromRGB(150, 80, 200),
    tax       = Color3.fromRGB(200, 100, 50),
    eviction  = Color3.fromRGB(200, 30, 30),
}

local function showNextNotif()
    if #notifQueue == 0 then notifActive = false return end
    notifActive = true

    local entry = table.remove(notifQueue, 1)
    local bg    = Instance.new("Frame")
    bg.Size     = UDim2.new(0, 320, 0, 48)
    bg.Position = UDim2.new(0.5, -160, 0, -55)
    bg.BackgroundColor3 = notifColors[entry.kind] or notifColors.info
    bg.BackgroundTransparency = 0.15
    bg.BorderSizePixel = 0
    bg.Parent   = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = bg

    local lbl   = Instance.new("TextLabel")
    lbl.Size    = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.new(0, 5, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text    = entry.text
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font    = Enum.Font.GothamSemibold
    lbl.TextScaled = true
    lbl.Parent  = bg

    -- Slide in
    bg:TweenPosition(UDim2.new(0.5, -160, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
    task.wait(2.5)
    bg:TweenPosition(UDim2.new(0.5, -160, 0, -55), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.3, true)
    task.wait(0.35)
    bg:Destroy()

    task.spawn(showNextNotif)
end

local function pushNotif(text, kind)
    notifQueue[#notifQueue + 1] = { text = text, kind = kind or "info" }
    if not notifActive then
        task.spawn(showNextNotif)
    end
end

-- ── Top bar ────────────────────────────────────────────────────────────────────
local topBar        = Instance.new("Frame")
topBar.Name         = "TopBar"
topBar.Size         = UDim2.new(1, 0, 0, 50)
topBar.Position     = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent       = screenGui

local cashLabel     = Instance.new("TextLabel")
cashLabel.Name      = "CashLabel"
cashLabel.Size      = UDim2.new(0, 200, 1, 0)
cashLabel.Position  = UDim2.new(0, 10, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text      = "💰 $5,000"
cashLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
cashLabel.Font      = Enum.Font.GothamBold
cashLabel.TextScaled = true
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent    = topBar

local jobLabel      = Instance.new("TextLabel")
jobLabel.Name       = "JobLabel"
jobLabel.Size       = UDim2.new(0, 220, 1, 0)
jobLabel.Position   = UDim2.new(0.5, -110, 0, 0)
jobLabel.BackgroundTransparency = 1
jobLabel.Text       = "👤 Civilian"
jobLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
jobLabel.Font       = Enum.Font.GothamSemibold
jobLabel.TextScaled = true
jobLabel.Parent     = topBar

-- ── Side menu buttons ──────────────────────────────────────────────────────────
local sideBar       = Instance.new("Frame")
sideBar.Name        = "SideBar"
sideBar.Size        = UDim2.new(0, 60, 0, 280)
sideBar.Position    = UDim2.new(1, -70, 0.5, -140)
sideBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
sideBar.BackgroundTransparency = 0.3
sideBar.BorderSizePixel = 0
sideBar.Parent      = screenGui

local sideCorner    = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 10)
sideCorner.Parent   = sideBar

local layout        = Instance.new("UIListLayout")
layout.Padding      = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment   = Enum.VerticalAlignment.Top
layout.Parent       = sideBar

local function makeMenuBtn(icon, guiName)
    local btn = Instance.new("TextButton")
    btn.Size  = UDim2.new(0, 48, 0, 48)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    btn.Text  = icon
    btn.Font  = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.BorderSizePixel = 0
    local c   = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent  = btn
    btn.Parent = sideBar

    btn.MouseButton1Click:Connect(function()
        local gui = playerGui:FindFirstChild(guiName)
        if gui then gui.Enabled = not gui.Enabled end
    end)
    return btn
end

makeMenuBtn("💼", "JobMenu")
makeMenuBtn("🏠", "PropertyMenu")
makeMenuBtn("🏪", "BusinessMenu")
makeMenuBtn("🔨", "AuctionMenu")
makeMenuBtn("🛒", "ShopMenu")

-- ── Update HUD from server ─────────────────────────────────────────────────────
RE.UpdateHUD.OnClientEvent:Connect(function(data)
    if data.cash ~= nil then
        cashLabel.Text = "💰 $" .. string.format("%d", math.floor(data.cash))
    end
    if data.job ~= nil then
        local jobName = data.job or "Civilian"
        -- Capitalise first letter
        jobName = jobName:sub(1,1):upper() .. jobName:sub(2)
        jobLabel.Text = "👤 " .. jobName
    end
end)

RE.Notify.OnClientEvent:Connect(function(text, kind)
    pushNotif(text, kind)
end)

print("[MainHUD] Loaded.")
