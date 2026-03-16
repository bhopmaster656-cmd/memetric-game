-- StarterGui/HUD/Script.client.lua
-- Main HUD for Evergreen County.
-- Displays: Money, Reputation, Stats (Hunger, Thirst, Energy, Health, Temperature),
-- Season/Weather indicator, Notifications, and action buttons.

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local screenGui = script.Parent  -- The HUD ScreenGui

local RemoteEvents      = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateStats       = RemoteEvents:WaitForChild("UpdateStats")
local UpdateMoney       = RemoteEvents:WaitForChild("UpdateMoney")
local UpdateReputation  = RemoteEvents:WaitForChild("UpdateReputation")
local UpdateWeather     = RemoteEvents:WaitForChild("UpdateWeather")
local UpdateSeason      = RemoteEvents:WaitForChild("UpdateSeason")
local NotifyPlayer      = RemoteEvents:WaitForChild("NotifyPlayer")
local OpenShop          = RemoteEvents:WaitForChild("OpenShop")
local SpawnVehicle      = RemoteEvents:WaitForChild("SpawnVehicle")

-- ─── Utility ──────────────────────────────────────────────────────────────────
local function makeFrame(name, size, pos, color, alpha, parent)
    local f = Instance.new("Frame")
    f.Name                   = name
    f.Size                   = size
    f.Position               = pos
    f.BackgroundColor3       = color or Color3.fromRGB(20, 20, 20)
    f.BackgroundTransparency = alpha or 0.35
    f.BorderSizePixel        = 0
    f.Parent                 = parent or screenGui
    return f
end

local function makeLabel(name, text, size, pos, color, font, parent)
    local l = Instance.new("TextLabel")
    l.Name              = name
    l.Text              = text
    l.Size              = size
    l.Position          = pos
    l.BackgroundTransparency = 1
    l.TextColor3        = color or Color3.new(1, 1, 1)
    l.Font              = font or Enum.Font.GothamBold
    l.TextScaled        = true
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = parent or screenGui
    return l
end

local function makeButton(name, text, size, pos, bgColor, parent, callback)
    local btn = Instance.new("TextButton")
    btn.Name             = name
    btn.Text             = text
    btn.Size             = size
    btn.Position         = pos
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(50, 120, 200)
    btn.BorderSizePixel  = 0
    btn.TextColor3       = Color3.new(1, 1, 1)
    btn.Font             = Enum.Font.GothamBold
    btn.TextScaled       = true
    btn.Parent           = parent or screenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

local function makeStatBar(name, color, yOffset, parent)
    local container = makeFrame(name .. "Container",
        UDim2.new(0, 180, 0, 22),
        UDim2.new(0, 10, 0, yOffset),
        Color3.fromRGB(0, 0, 0), 0.5, parent)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local fill = Instance.new("Frame")
    fill.Name                = "Fill"
    fill.Size                = UDim2.new(1, 0, 1, 0)
    fill.Position            = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3    = color
    fill.BorderSizePixel     = 0
    fill.Parent              = container
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local label = Instance.new("TextLabel")
    label.Name               = "Label"
    label.Size               = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3         = Color3.new(1, 1, 1)
    label.Font               = Enum.Font.GothamBold
    label.TextScaled         = true
    label.Text               = name .. ": 100"
    label.Parent             = container

    return container, fill, label
end

-- ─── Top Bar (Money + Reputation) ─────────────────────────────────────────────
local topBar = makeFrame("TopBar",
    UDim2.new(0, 280, 0, 44),
    UDim2.new(0.5, -140, 0, 8),
    Color3.fromRGB(10, 10, 10), 0.3)
local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local moneyLabel = makeLabel("MoneyLabel", "💰 $0",
    UDim2.new(0.5, 0, 1, 0),
    UDim2.new(0, 10, 0, 0),
    Color3.fromRGB(255, 220, 50),
    Enum.Font.GothamBold, topBar)

local repLabel = makeLabel("RepLabel", "⭐ Rep: 0",
    UDim2.new(0.5, -20, 1, 0),
    UDim2.new(0.5, 10, 0, 0),
    Color3.fromRGB(100, 200, 255),
    Enum.Font.GothamBold, topBar)

-- ─── Stats Panel (Left side) ─────────────────────────────────────────────────
local statsPanel = makeFrame("StatsPanel",
    UDim2.new(0, 200, 0, 185),
    UDim2.new(0, 8, 0.5, -90),
    Color3.fromRGB(10, 10, 10), 0.3)
local statsPanelCorner = Instance.new("UICorner")
statsPanelCorner.CornerRadius = UDim.new(0, 8)
statsPanelCorner.Parent = statsPanel

-- Stat bars
local _, hungerFill, hungerLbl   = makeStatBar("🍖 Hunger",      Color3.fromRGB(255, 165, 0),  8,  statsPanel)
local _, thirstFill, thirstLbl   = makeStatBar("💧 Thirst",      Color3.fromRGB(50, 150, 255),  38, statsPanel)
local _, energyFill, energyLbl   = makeStatBar("⚡ Energy",      Color3.fromRGB(255, 220, 50),  68, statsPanel)
local _, healthFill, healthLbl   = makeStatBar("❤️ Health",       Color3.fromRGB(220, 50, 50),   98, statsPanel)
local _, tempFill,   tempLbl     = makeStatBar("🌡️ Temp",        Color3.fromRGB(100, 200, 255), 128, statsPanel)

-- Profession label
local profLabel = makeLabel("ProfLabel", "👷 Unemployed",
    UDim2.new(1, -10, 0, 24),
    UDim2.new(0, 5, 0, 156),
    Color3.fromRGB(200, 200, 200),
    Enum.Font.Gotham, statsPanel)

-- ─── Weather / Season Display (Top Right) ────────────────────────────────────
local weatherFrame = makeFrame("WeatherFrame",
    UDim2.new(0, 180, 0, 44),
    UDim2.new(1, -190, 0, 8),
    Color3.fromRGB(10, 10, 10), 0.3)
local weatherCorner = Instance.new("UICorner")
weatherCorner.CornerRadius = UDim.new(0, 8)
weatherCorner.Parent = weatherFrame

local weatherLabel = makeLabel("WeatherLabel", "☀️ Clear | 🌸 Spring",
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 8, 0, 0),
    Color3.new(1, 1, 1),
    Enum.Font.Gotham, weatherFrame)
weatherLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ─── Action Buttons (Bottom Right) ───────────────────────────────────────────
local actionPanel = makeFrame("ActionPanel",
    UDim2.new(0, 140, 0, 260),
    UDim2.new(1, -150, 1, -270),
    Color3.fromRGB(10, 10, 10), 0.3)
local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 8)
actionCorner.Parent = actionPanel

makeButton("ShopBtn",       "🏪 Shop",       UDim2.new(1, -10, 0, 36), UDim2.new(0, 5, 0, 5),   Color3.fromRGB(50, 150, 80),  actionPanel, function()
    OpenShop:FireServer("GovStore")
end)
makeButton("MarketBtn",     "📦 Market",     UDim2.new(1, -10, 0, 36), UDim2.new(0, 5, 0, 46),  Color3.fromRGB(80, 100, 200), actionPanel, function()
    OpenShop:FireServer("Market")
end)
makeButton("ProfessionBtn", "🎓 Profession", UDim2.new(1, -10, 0, 36), UDim2.new(0, 5, 0, 87),  Color3.fromRGB(150, 80, 200), actionPanel, function()
    OpenShop:FireServer("Profession")
end)
makeButton("BuildBtn",      "🏗️ Build",      UDim2.new(1, -10, 0, 36), UDim2.new(0, 5, 0, 128), Color3.fromRGB(200, 120, 30), actionPanel, function()
    OpenShop:FireServer("Build")
end)
makeButton("VehicleBtn",    "🚗 Vehicle",    UDim2.new(1, -10, 0, 36), UDim2.new(0, 5, 0, 169), Color3.fromRGB(30, 130, 180), actionPanel, function()
    -- Spawn bicycle as default, player can buy cars
    SpawnVehicle:InvokeServer("Bicycle")
end)
makeButton("InventoryBtn",  "🎒 Inventory",  UDim2.new(1, -10, 0, 36), UDim2.new(0, 5, 0, 210), Color3.fromRGB(100, 100, 100),actionPanel, function()
    OpenShop:FireServer("Inventory")
end)

-- ─── Notification System ─────────────────────────────────────────────────────
local notificationQueue = {}
local isShowingNotification = false
local notifColors = {
    green  = Color3.fromRGB(50, 200, 80),
    red    = Color3.fromRGB(220, 50, 50),
    blue   = Color3.fromRGB(50, 120, 220),
    yellow = Color3.fromRGB(240, 200, 30),
    white  = Color3.new(1, 1, 1),
}

local notifFrame = makeFrame("NotifFrame",
    UDim2.new(0, 350, 0, 60),
    UDim2.new(0.5, -175, 0, -70),
    Color3.fromRGB(10, 10, 10), 0.2)
local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notifFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Size              = UDim2.new(1, -20, 1, 0)
notifLabel.Position          = UDim2.new(0, 10, 0, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3        = Color3.new(1, 1, 1)
notifLabel.Font              = Enum.Font.GothamBold
notifLabel.TextScaled        = true
notifLabel.TextWrapped       = true
notifLabel.TextXAlignment    = Enum.TextXAlignment.Center
notifLabel.Parent            = notifFrame

local function showNotification(text, colorKey)
    table.insert(notificationQueue, { text=text, color=colorKey })
end

local function processNotifications()
    while true do
        if #notificationQueue > 0 and not isShowingNotification then
            isShowingNotification = true
            local notif = table.remove(notificationQueue, 1)
            notifLabel.Text       = notif.text
            notifLabel.TextColor3 = notifColors[notif.color] or Color3.new(1, 1, 1)

            -- Slide in
            local tweenIn = TweenService:Create(notifFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Position = UDim2.new(0.5, -175, 0, 10) })
            tweenIn:Play()
            tweenIn.Completed:Wait()
            task.wait(2.5)

            -- Slide out
            local tweenOut = TweenService:Create(notifFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Sine),
                { Position = UDim2.new(0.5, -175, 0, -70) })
            tweenOut:Play()
            tweenOut.Completed:Wait()
            isShowingNotification = false
        else
            task.wait(0.1)
        end
    end
end

task.spawn(processNotifications)

NotifyPlayer.OnClientEvent:Connect(function(text, colorKey)
    showNotification(text, colorKey or "white")
end)

-- ─── Stat Bar Update ─────────────────────────────────────────────────────────
local function updateStatBar(fill, label, statName, value)
    local pct = math.clamp(value / 100, 0, 1)
    TweenService:Create(fill,
        TweenInfo.new(0.3, Enum.EasingStyle.Sine),
        { Size = UDim2.new(pct, 0, 1, 0) }
    ):Play()
    label.Text = statName .. ": " .. math.floor(value)
end

UpdateStats.OnClientEvent:Connect(function(stats)
    if stats.Hunger      then updateStatBar(hungerFill, hungerLbl, "🍖 Hunger", stats.Hunger) end
    if stats.Thirst      then updateStatBar(thirstFill, thirstLbl, "💧 Thirst", stats.Thirst) end
    if stats.Energy      then updateStatBar(energyFill, energyLbl, "⚡ Energy", stats.Energy) end
    if stats.Health      then updateStatBar(healthFill, healthLbl, "❤️ Health", stats.Health) end
    if stats.Temperature then
        local temp = stats.Temperature
        -- Color: blue (cold) -> green (neutral) -> red (hot)
        local tempColor
        if temp < 30 then
            tempColor = Color3.fromRGB(50, 100, 255)
        elseif temp > 70 then
            tempColor = Color3.fromRGB(255, 80, 50)
        else
            tempColor = Color3.fromRGB(50, 200, 100)
        end
        tempFill.BackgroundColor3 = tempColor
        updateStatBar(tempFill, tempLbl, "🌡️ Temp", temp)
    end
end)

UpdateMoney.OnClientEvent:Connect(function(money)
    moneyLabel.Text = "💰 $" .. tostring(money)
end)

UpdateReputation.OnClientEvent:Connect(function(rep)
    local repColor
    if rep >= 50 then repColor = Color3.fromRGB(50, 220, 100)
    elseif rep >= 0 then repColor = Color3.fromRGB(200, 200, 200)
    elseif rep >= -50 then repColor = Color3.fromRGB(255, 180, 50)
    else repColor = Color3.fromRGB(255, 60, 60) end
    repLabel.TextColor3 = repColor
    repLabel.Text = "⭐ Rep: " .. tostring(rep)
end)

local weatherIcons = {
    Clear   = "☀️",
    Cloudy  = "☁️",
    Rainy   = "🌧️",
    Snowy   = "❄️",
    Foggy   = "🌫️",
}
local seasonIcons = {
    Spring = "🌸",
    Summer = "☀️",
    Autumn = "🍂",
    Winter = "❄️",
}
local currentWeather = "Clear"
local currentSeason  = "Spring"

UpdateWeather.OnClientEvent:Connect(function(weather)
    currentWeather = weather
    local icon = weatherIcons[weather] or "🌤️"
    weatherLabel.Text = icon .. " " .. weather .. " | " .. (seasonIcons[currentSeason] or "") .. " " .. currentSeason
end)

UpdateSeason.OnClientEvent:Connect(function(season)
    currentSeason = season
    weatherLabel.Text = (weatherIcons[currentWeather] or "🌤️") .. " " .. currentWeather .. " | " .. (seasonIcons[season] or "") .. " " .. season
end)

-- ─── Low Stat Warnings ───────────────────────────────────────────────────────
-- Visual flash when stats are critically low
local lastWarnings = {}

RunService.RenderStepped:Connect(function()
    local statsCache = _G.PlayerStatsCache
    if not statsCache then return end

    local warnings = {
        { stat="Hunger",      threshold=20, msg="🍖 ГОЛОДЕН! Поешьте немедленно!",        color="red"    },
        { stat="Thirst",      threshold=15, msg="💧 ЖАЖДА! Выпейте воду!",                 color="red"    },
        { stat="Energy",      threshold=10, msg="⚡ Устали! Поспите в кровати.",            color="yellow" },
        { stat="Health",      threshold=20, msg="❤️ Низкое здоровье! Используйте аптечку.", color="red"    },
        { stat="Temperature", threshold=15, msg="🥶 Вы замерзаете! Найдите тепло!",        color="blue"   },
    }

    for _, w in ipairs(warnings) do
        local val = statsCache[w.stat]
        if val and val <= w.threshold then
            if not lastWarnings[w.stat] then
                lastWarnings[w.stat] = true
                showNotification(w.msg, w.color)
            end
        else
            lastWarnings[w.stat] = false
        end
    end
end)

-- ─── Open GUI handlers (from server or action buttons) ───────────────────────
OpenShop.OnClientEvent:Connect(function(shopType)
    -- Forward to the specific GUI
    local playerGui = player:WaitForChild("PlayerGui")

    -- Close all sub-GUIs first
    local guiNames = { "ShopGui", "ProfessionGui", "BuildingGui", "MarketGui" }
    for _, guiName in ipairs(guiNames) do
        local gui = playerGui:FindFirstChild(guiName)
        if gui then gui.Enabled = false end
    end

    if shopType == "GovStore" or shopType == "Cafe" then
        local gui = playerGui:FindFirstChild("ShopGui")
        if gui then
            gui:SetAttribute("ShopType", shopType)
            gui.Enabled = true
        end
    elseif shopType == "Profession" then
        local gui = playerGui:FindFirstChild("ProfessionGui")
        if gui then gui.Enabled = true end
    elseif shopType == "Build" or shopType == "Inventory" then
        local gui = playerGui:FindFirstChild("BuildingGui")
        if gui then
            gui:SetAttribute("Mode", shopType)
            gui.Enabled = true
        end
    elseif shopType == "Market" then
        local gui = playerGui:FindFirstChild("MarketGui")
        if gui then gui.Enabled = true end
    end
end)

print("[HUD] Ready")
