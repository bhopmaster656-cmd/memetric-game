--[[
	LoadingScreen.client.lua
	Displays a neon-themed loading screen while the game assets load.
	Placed in ReplicatedFirst so it runs before other scripts.
]]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- Colours
--------------------------------------------------------------------
local NEON_CYAN   = Color3.fromRGB(0, 255, 255)
local NEON_PURPLE = Color3.fromRGB(155, 89, 182)
local NEON_PINK   = Color3.fromRGB(255, 71, 148)
local BG_DARK     = Color3.fromRGB(15, 15, 30)

--------------------------------------------------------------------
-- Build loading screen
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreenGui"
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- Disable default loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Background
local bg = Instance.new("Frame")
bg.BackgroundColor3 = BG_DARK
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BorderSizePixel = 0
bg.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Text = "NEON SLICE"
title.Font = Enum.Font.GothamBold
title.TextColor3 = NEON_CYAN
title.TextSize = 56
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 70)
title.Position = UDim2.new(0.5, 0, 0.35, 0)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Parent = bg

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = NEON_PURPLE
titleStroke.Thickness = 2
titleStroke.Parent = title

-- Loading bar background
local barBg = Instance.new("Frame")
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
barBg.BackgroundTransparency = 0.3
barBg.BorderSizePixel = 0
barBg.Size = UDim2.new(0.4, 0, 0, 8)
barBg.Position = UDim2.new(0.5, 0, 0.55, 0)
barBg.AnchorPoint = Vector2.new(0.5, 0.5)
barBg.Parent = bg

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 4)
barCorner.Parent = barBg

-- Loading bar fill
local barFill = Instance.new("Frame")
barFill.BackgroundColor3 = NEON_CYAN
barFill.BorderSizePixel = 0
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = barFill

-- Status text
local statusText = Instance.new("TextLabel")
statusText.Text = "Loading..."
statusText.Font = Enum.Font.Gotham
statusText.TextColor3 = NEON_PINK
statusText.TextSize = 16
statusText.BackgroundTransparency = 1
statusText.Size = UDim2.new(1, 0, 0, 30)
statusText.Position = UDim2.new(0.5, 0, 0.6, 0)
statusText.AnchorPoint = Vector2.new(0.5, 0)
statusText.Parent = bg

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Text = "Cut, ride and rock in the neon city"
subtitle.Font = Enum.Font.Gotham
subtitle.TextColor3 = Color3.fromRGB(120, 120, 150)
subtitle.TextSize = 14
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1, 0, 0, 25)
subtitle.Position = UDim2.new(0.5, 0, 0.42, 0)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Parent = bg

--------------------------------------------------------------------
-- Animate loading
--------------------------------------------------------------------
local steps = {
	{text = "Initializing neon grid...", progress = 0.2},
	{text = "Loading katana arsenal...", progress = 0.4},
	{text = "Mapping city districts...", progress = 0.6},
	{text = "Calibrating slice engine...", progress = 0.8},
	{text = "Ready to ride!", progress = 1.0},
}

-- Title color cycle
task.spawn(function()
	local colors = {NEON_CYAN, NEON_PURPLE, NEON_PINK}
	local i = 1
	while screenGui.Parent do
		TweenService:Create(title, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
			TextColor3 = colors[i],
		}):Play()
		i = (i % #colors) + 1
		task.wait(1.5)
	end
end)

-- Progress through loading steps
for _, step in ipairs(steps) do
	statusText.Text = step.text
	TweenService:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
		Size = UDim2.new(step.progress, 0, 1, 0),
	}):Play()
	task.wait(0.8)
end

-- Wait for the game to be loaded
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Fade out
task.wait(0.5)
TweenService:Create(bg, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
	BackgroundTransparency = 1,
}):Play()
TweenService:Create(title, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
TweenService:Create(statusText, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
TweenService:Create(subtitle, TweenInfo.new(0.6), {TextTransparency = 1}):Play()
TweenService:Create(barBg, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
TweenService:Create(barFill, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()

task.wait(1)
screenGui:Destroy()

print("[NEON SLICE] LoadingScreen complete ✓")
