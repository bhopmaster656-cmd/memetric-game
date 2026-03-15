--[[
	MainMenu.client.lua
	Main menu screen with Play, Shop, District Map, and Raid buttons.
	Full cyberpunk-neon styled UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------
local StartRunEvent    = ReplicatedStorage:WaitForChild("StartRun")
local RunEndedEvent    = ReplicatedStorage:WaitForChild("RunEnded")
local RunStateChanged  = ReplicatedStorage:WaitForChild("RunStateChanged")
local ToggleShop       = ReplicatedStorage:WaitForChild("ToggleShop")
local ToggleDistrictMap = ReplicatedStorage:WaitForChild("ToggleDistrictMap")
local ToggleRaidUI     = ReplicatedStorage:WaitForChild("ToggleRaidUI")

--------------------------------------------------------------------
-- Helper: Create styled UI elements
--------------------------------------------------------------------
local function createFrame(props)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = props.Color or Config.BG_DARK
	frame.BackgroundTransparency = props.Transparency or 0
	frame.BorderSizePixel = 0
	frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
	frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
	frame.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	frame.Name = props.Name or "Frame"
	if props.Parent then
		frame.Parent = props.Parent
	end
	-- Add corner radius if specified
	if props.CornerRadius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, props.CornerRadius)
		corner.Parent = frame
	end
	return frame
end

local function createLabel(props)
	local label = Instance.new("TextLabel")
	label.Text = props.Text or ""
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = props.TextColor or Color3.new(1, 1, 1)
	label.TextSize = props.TextSize or 24
	label.BackgroundTransparency = 1
	label.Size = props.Size or UDim2.new(1, 0, 0, 40)
	label.Position = props.Position or UDim2.new(0, 0, 0, 0)
	label.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
	label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	label.Name = props.Name or "Label"
	if props.Parent then
		label.Parent = props.Parent
	end
	return label
end

local function createButton(props)
	local button = Instance.new("TextButton")
	button.Text = props.Text or "Button"
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = props.TextColor or Color3.new(1, 1, 1)
	button.TextSize = props.TextSize or 20
	button.BackgroundColor3 = props.Color or Config.NEON_PURPLE
	button.BackgroundTransparency = props.Transparency or 0.1
	button.BorderSizePixel = 0
	button.Size = props.Size or UDim2.new(0, 200, 0, 50)
	button.Position = props.Position or UDim2.new(0.5, 0, 0.5, 0)
	button.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	button.AutoButtonColor = true
	button.Name = props.Name or "Button"
	if props.Parent then
		button.Parent = props.Parent
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	-- Neon border
	local stroke = Instance.new("UIStroke")
	stroke.Color = props.StrokeColor or props.Color or Config.NEON_CYAN
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = button

	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundTransparency = 0,
			Size = props.Size and UDim2.new(
				props.Size.X.Scale, props.Size.X.Offset + 6,
				props.Size.Y.Scale, props.Size.Y.Offset + 4
			) or UDim2.new(0, 206, 0, 54),
		}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundTransparency = props.Transparency or 0.1,
			Size = props.Size or UDim2.new(0, 200, 0, 50),
		}):Play()
	end)

	return button
end

--------------------------------------------------------------------
-- Build Main Menu ScreenGui
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenuGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Background overlay
local bg = createFrame({
	Name = "Background",
	Color = Config.BG_DARK,
	Transparency = 0.2,
	Size = UDim2.new(1, 0, 1, 0),
	Parent = screenGui,
})

-- Title
local title = createLabel({
	Name = "Title",
	Text = "NEON SLICE",
	TextSize = 64,
	TextColor = Config.NEON_CYAN,
	Size = UDim2.new(1, 0, 0, 80),
	Position = UDim2.new(0.5, 0, 0.15, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Parent = bg,
})

-- Title glow (stroke)
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Config.NEON_PURPLE
titleStroke.Thickness = 2
titleStroke.Transparency = 0.4
titleStroke.Parent = title

-- Subtitle
local subtitle = createLabel({
	Name = "Subtitle",
	Text = "Cut, ride and rock in the neon city",
	TextSize = 20,
	TextColor = Config.NEON_PINK,
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0.5, 0, 0.22, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Parent = bg,
})

-- Button container
local buttonContainer = createFrame({
	Name = "Buttons",
	Color = Config.BG_DARK,
	Transparency = 1,
	Size = UDim2.new(0, 300, 0, 320),
	Position = UDim2.new(0.5, 0, 0.55, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Parent = bg,
})

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 12)
listLayout.Parent = buttonContainer

-- Play button
local playBtn = createButton({
	Name = "PlayButton",
	Text = "▶  START RUN",
	Size = UDim2.new(1, 0, 0, 56),
	Color = Config.NEON_CYAN,
	StrokeColor = Config.NEON_CYAN,
	TextSize = 24,
	Parent = buttonContainer,
})

-- Shop button
local shopBtn = createButton({
	Name = "ShopButton",
	Text = "🗡  KATANA SHOP  [B]",
	Size = UDim2.new(1, 0, 0, 50),
	Color = Config.NEON_PURPLE,
	StrokeColor = Config.NEON_PURPLE,
	Parent = buttonContainer,
})

-- District Map button
local districtBtn = createButton({
	Name = "DistrictButton",
	Text = "🗺  DISTRICT MAP  [M]",
	Size = UDim2.new(1, 0, 0, 50),
	Color = Config.NEON_BLUE,
	StrokeColor = Config.NEON_BLUE,
	Parent = buttonContainer,
})

-- Raid button
local raidBtn = createButton({
	Name = "RaidButton",
	Text = "⚔  RAID BATTLE  [R]",
	Size = UDim2.new(1, 0, 0, 50),
	Color = Config.NEON_PINK,
	StrokeColor = Config.NEON_PINK,
	Parent = buttonContainer,
})

-- Version label
createLabel({
	Name = "Version",
	Text = "v" .. Config.VERSION,
	TextSize = 14,
	TextColor = Color3.fromRGB(100, 100, 120),
	Size = UDim2.new(0, 100, 0, 20),
	Position = UDim2.new(1, -10, 1, -10),
	AnchorPoint = Vector2.new(1, 1),
	Parent = bg,
})

--------------------------------------------------------------------
-- Button handlers
--------------------------------------------------------------------
playBtn.MouseButton1Click:Connect(function()
	-- Start a run
	bg.Visible = false
	StartRunEvent:FireServer()
	RunStateChanged:Fire(true)
end)

shopBtn.MouseButton1Click:Connect(function()
	ToggleShop:Fire()
end)

districtBtn.MouseButton1Click:Connect(function()
	ToggleDistrictMap:Fire()
end)

raidBtn.MouseButton1Click:Connect(function()
	ToggleRaidUI:Fire()
end)

--------------------------------------------------------------------
-- Show menu when run ends
--------------------------------------------------------------------
RunEndedEvent.OnClientEvent:Connect(function(stats)
	-- Show results briefly, then return to menu
	task.wait(2)
	bg.Visible = true
end)

--------------------------------------------------------------------
-- Title animation (pulse glow)
--------------------------------------------------------------------
task.spawn(function()
	local colors = {Config.NEON_CYAN, Config.NEON_PURPLE, Config.NEON_PINK, Config.NEON_BLUE}
	local index = 1
	while true do
		local nextColor = colors[index]
		TweenService:Create(title, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			TextColor3 = nextColor,
		}):Play()
		TweenService:Create(titleStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Color = colors[(index % #colors) + 1],
		}):Play()
		index = (index % #colors) + 1
		task.wait(2)
	end
end)

print("[NEON SLICE] MainMenu loaded ✓")
