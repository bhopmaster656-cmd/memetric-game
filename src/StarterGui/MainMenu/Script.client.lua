-- StarterGui/MainMenu/Script.client.lua
-- Main menu / loading screen shown when the player first joins.
-- Fades out once the world is ready.

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local player    = Players.LocalPlayer
local screenGui = script.Parent  -- MainMenu ScreenGui
screenGui.Enabled = true

-- ─── Build the loading screen ─────────────────────────────────────────────────
local bg = Instance.new("Frame")
bg.Name                   = "Background"
bg.Size                   = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3       = Color3.fromRGB(10, 20, 35)
bg.BorderSizePixel        = 0
bg.Parent                 = screenGui

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name              = "Title"
titleLabel.Size              = UDim2.new(0, 600, 0, 80)
titleLabel.Position          = UDim2.new(0.5, -300, 0.3, -40)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3        = Color3.fromRGB(100, 220, 130)
titleLabel.Font              = Enum.Font.GothamBold
titleLabel.TextScaled        = true
titleLabel.Text              = "🌳 EVERGREEN COUNTY"
titleLabel.Parent            = bg

-- Subtitle
local subLabel = Instance.new("TextLabel")
subLabel.Name               = "Subtitle"
subLabel.Size               = UDim2.new(0, 500, 0, 40)
subLabel.Position           = UDim2.new(0.5, -250, 0.3, 50)
subLabel.BackgroundTransparency = 1
subLabel.TextColor3         = Color3.fromRGB(180, 200, 180)
subLabel.Font               = Enum.Font.Gotham
subLabel.TextScaled         = true
subLabel.Text               = "A Living, Breathing Township"
subLabel.Parent             = bg

-- Loading bar background
local loadBg = Instance.new("Frame")
loadBg.Name                = "LoadBarBg"
loadBg.Size                = UDim2.new(0, 400, 0, 20)
loadBg.Position            = UDim2.new(0.5, -200, 0.65, 0)
loadBg.BackgroundColor3    = Color3.fromRGB(40, 60, 40)
loadBg.BorderSizePixel     = 0
loadBg.Parent              = bg
local loadBgCorner = Instance.new("UICorner")
loadBgCorner.CornerRadius  = UDim.new(0, 10)
loadBgCorner.Parent        = loadBg

-- Loading bar fill
local loadFill = Instance.new("Frame")
loadFill.Name              = "LoadBarFill"
loadFill.Size              = UDim2.new(0, 0, 1, 0)
loadFill.BackgroundColor3  = Color3.fromRGB(80, 200, 100)
loadFill.BorderSizePixel   = 0
loadFill.Parent            = loadBg
local loadFillCorner = Instance.new("UICorner")
loadFillCorner.CornerRadius= UDim.new(0, 10)
loadFillCorner.Parent      = loadFill

-- Loading text
local loadLabel = Instance.new("TextLabel")
loadLabel.Name             = "LoadLabel"
loadLabel.Size             = UDim2.new(0, 400, 0, 30)
loadLabel.Position         = UDim2.new(0.5, -200, 0.65, 25)
loadLabel.BackgroundTransparency = 1
loadLabel.TextColor3       = Color3.fromRGB(180, 200, 180)
loadLabel.Font             = Enum.Font.Gotham
loadLabel.TextScaled       = true
loadLabel.Text             = "Loading world…"
loadLabel.Parent           = bg

-- Tips panel
local tipMessages = {
    "💡 Press [Shift] to sprint",
    "💡 Buy a plot in the Suburbs to start building your home!",
    "💡 Visit the Town Hall to change your profession.",
    "💡 The market price of resources changes based on supply!",
    "💡 In Winter, make sure your home has a fireplace or heater.",
    "💡 Press [E] near a vehicle to enter or exit it.",
    "💡 Type /arrest <player> to arrest a criminal (Sheriff only).",
    "💡 Property tax is collected every hour — stay rich!",
    "💡 Chat /coop <player> to invite someone to co-own your plot.",
    "💡 Farming gives double yield in Autumn!",
}

local tipLabel = Instance.new("TextLabel")
tipLabel.Name              = "TipLabel"
tipLabel.Size              = UDim2.new(0, 500, 0, 50)
tipLabel.Position          = UDim2.new(0.5, -250, 0.75, 0)
tipLabel.BackgroundTransparency = 1
tipLabel.TextColor3        = Color3.fromRGB(200, 220, 200)
tipLabel.Font              = Enum.Font.GothamItalic
tipLabel.TextScaled        = true
tipLabel.TextWrapped       = true
tipLabel.Text              = tipMessages[math.random(#tipMessages)]
tipLabel.Parent            = bg

-- Version label
local versionLabel = Instance.new("TextLabel")
versionLabel.Name          = "VersionLabel"
versionLabel.Size          = UDim2.new(0, 200, 0, 24)
versionLabel.Position      = UDim2.new(1, -210, 1, -30)
versionLabel.BackgroundTransparency = 1
versionLabel.TextColor3    = Color3.fromRGB(100, 120, 100)
versionLabel.Font          = Enum.Font.Gotham
versionLabel.TextScaled    = true
versionLabel.Text          = "v1.0.0 — Evergreen County"
versionLabel.Parent        = bg

-- ─── Loading Animation ────────────────────────────────────────────────────────
local loadingTexts = {
    "Planting trees…",
    "Building roads…",
    "Stocking the store…",
    "Setting up the mine…",
    "Hiring NPCs…",
    "Checking the weather…",
    "Painting houses…",
    "World ready!",
}

local function animateLoading()
    for i, text in ipairs(loadingTexts) do
        loadLabel.Text = text
        local progress = i / #loadingTexts
        TweenService:Create(loadFill,
            TweenInfo.new(0.4, Enum.EasingStyle.Sine),
            { Size = UDim2.new(progress, 0, 1, 0) }
        ):Play()
        task.wait(0.5)
    end
end

-- ─── Wait for World Ready ─────────────────────────────────────────────────────
task.spawn(animateLoading)

-- Wait for world attribute or timeout
local timeout = 10
local elapsed = 0
while elapsed < timeout do
    if Workspace:GetAttribute("WorldReady") then
        break
    end
    elapsed = elapsed + 0.1
    task.wait(0.1)
end

-- Extra delay for assets to stream in
task.wait(1)

-- Dismiss button
local dismissBtn = Instance.new("TextButton")
dismissBtn.Name             = "DismissBtn"
dismissBtn.Size             = UDim2.new(0, 200, 0, 50)
dismissBtn.Position         = UDim2.new(0.5, -100, 0.85, 0)
dismissBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
dismissBtn.BorderSizePixel  = 0
dismissBtn.TextColor3       = Color3.new(1, 1, 1)
dismissBtn.Font             = Enum.Font.GothamBold
dismissBtn.TextScaled       = true
dismissBtn.Text             = "▶ Play"
dismissBtn.Parent           = bg
local dismissCorner = Instance.new("UICorner")
dismissCorner.CornerRadius  = UDim.new(0, 10)
dismissCorner.Parent        = dismissBtn

dismissBtn.MouseButton1Click:Connect(function()
    -- Fade out
    TweenService:Create(bg,
        TweenInfo.new(0.8, Enum.EasingStyle.Sine),
        { BackgroundTransparency = 1 }
    ):Play()
    for _, child in ipairs(bg:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            TweenService:Create(child,
                TweenInfo.new(0.6, Enum.EasingStyle.Sine),
                { TextTransparency = 1 }
            ):Play()
        elseif child:IsA("Frame") then
            TweenService:Create(child,
                TweenInfo.new(0.6, Enum.EasingStyle.Sine),
                { BackgroundTransparency = 1 }
            ):Play()
        end
    end
    task.delay(0.9, function()
        screenGui.Enabled = false
    end)
end)

-- Auto-dismiss after 3 seconds if player doesn't click
task.delay(3, function()
    if screenGui.Enabled then
        dismissBtn:Activate()
    end
end)

print("[MainMenu] Loading screen shown")
