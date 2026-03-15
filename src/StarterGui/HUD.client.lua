--[[
	HUD.client.lua
	In-game heads-up display showing score, combo, energy, speed,
	and the end-of-run results screen.
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
local UpdateScoreEvent  = ReplicatedStorage:WaitForChild("UpdateScore")
local UpdateSpeedEvent  = ReplicatedStorage:WaitForChild("UpdateSpeed")
local SliceResultEvent  = ReplicatedStorage:WaitForChild("SliceResult")
local RunEndedEvent     = ReplicatedStorage:WaitForChild("RunEnded")
local EndRunEvent       = ReplicatedStorage:WaitForChild("EndRun")
local RunStateChanged   = ReplicatedStorage:WaitForChild("RunStateChanged")
local NotificationEvent = ReplicatedStorage:WaitForChild("Notification")

--------------------------------------------------------------------
-- ScreenGui
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HUDGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Container (hidden until run starts)
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUD"
hudFrame.BackgroundTransparency = 1
hudFrame.Size = UDim2.new(1, 0, 1, 0)
hudFrame.Visible = false
hudFrame.Parent = screenGui

--------------------------------------------------------------------
-- Score display (top center)
--------------------------------------------------------------------
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "Score"
scoreLabel.Text = "0"
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextColor3 = Color3.new(1, 1, 1)
scoreLabel.TextSize = 42
scoreLabel.BackgroundTransparency = 1
scoreLabel.Size = UDim2.new(0, 300, 0, 50)
scoreLabel.Position = UDim2.new(0.5, 0, 0.05, 0)
scoreLabel.AnchorPoint = Vector2.new(0.5, 0)
scoreLabel.Parent = hudFrame

local scoreStroke = Instance.new("UIStroke")
scoreStroke.Color = Config.NEON_CYAN
scoreStroke.Thickness = 1
scoreStroke.Transparency = 0.5
scoreStroke.Parent = scoreLabel

--------------------------------------------------------------------
-- Combo display (below score)
--------------------------------------------------------------------
local comboLabel = Instance.new("TextLabel")
comboLabel.Name = "Combo"
comboLabel.Text = ""
comboLabel.Font = Enum.Font.GothamBold
comboLabel.TextColor3 = Config.NEON_YELLOW
comboLabel.TextSize = 28
comboLabel.BackgroundTransparency = 1
comboLabel.Size = UDim2.new(0, 300, 0, 35)
comboLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
comboLabel.AnchorPoint = Vector2.new(0.5, 0)
comboLabel.Parent = hudFrame

--------------------------------------------------------------------
-- Multiplier indicator
--------------------------------------------------------------------
local multiplierLabel = Instance.new("TextLabel")
multiplierLabel.Name = "Multiplier"
multiplierLabel.Text = "x1"
multiplierLabel.Font = Enum.Font.GothamBold
multiplierLabel.TextColor3 = Config.NEON_PINK
multiplierLabel.TextSize = 36
multiplierLabel.TextTransparency = 0.5
multiplierLabel.BackgroundTransparency = 1
multiplierLabel.Size = UDim2.new(0, 100, 0, 40)
multiplierLabel.Position = UDim2.new(0.5, 160, 0.05, 0)
multiplierLabel.AnchorPoint = Vector2.new(0, 0)
multiplierLabel.Parent = hudFrame

--------------------------------------------------------------------
-- Energy bar (left side)
--------------------------------------------------------------------
local energyBg = Instance.new("Frame")
energyBg.Name = "EnergyBg"
energyBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
energyBg.BackgroundTransparency = 0.3
energyBg.BorderSizePixel = 0
energyBg.Size = UDim2.new(0, 12, 0.4, 0)
energyBg.Position = UDim2.new(0, 25, 0.3, 0)
energyBg.Parent = hudFrame

local energyCorner = Instance.new("UICorner")
energyCorner.CornerRadius = UDim.new(0, 6)
energyCorner.Parent = energyBg

local energyFill = Instance.new("Frame")
energyFill.Name = "EnergyFill"
energyFill.BackgroundColor3 = Config.NEON_CYAN
energyFill.BorderSizePixel = 0
energyFill.Size = UDim2.new(1, 0, 0, 0)
energyFill.Position = UDim2.new(0, 0, 1, 0)
energyFill.AnchorPoint = Vector2.new(0, 1)
energyFill.Parent = energyBg

local energyFillCorner = Instance.new("UICorner")
energyFillCorner.CornerRadius = UDim.new(0, 6)
energyFillCorner.Parent = energyFill

local energyLabel = Instance.new("TextLabel")
energyLabel.Name = "EnergyLabel"
energyLabel.Text = "⚡ 0"
energyLabel.Font = Enum.Font.GothamBold
energyLabel.TextColor3 = Config.NEON_CYAN
energyLabel.TextSize = 14
energyLabel.BackgroundTransparency = 1
energyLabel.Size = UDim2.new(0, 60, 0, 20)
energyLabel.Position = UDim2.new(0, 18, 0.71, 0)
energyLabel.TextXAlignment = Enum.TextXAlignment.Center
energyLabel.Parent = hudFrame

--------------------------------------------------------------------
-- Speed indicator (right side)
--------------------------------------------------------------------
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "Speed"
speedLabel.Text = "80 km/h"
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextColor3 = Config.NEON_PURPLE
speedLabel.TextSize = 18
speedLabel.BackgroundTransparency = 1
speedLabel.Size = UDim2.new(0, 120, 0, 30)
speedLabel.Position = UDim2.new(1, -20, 0.9, 0)
speedLabel.AnchorPoint = Vector2.new(1, 0)
speedLabel.TextXAlignment = Enum.TextXAlignment.Right
speedLabel.Parent = hudFrame

--------------------------------------------------------------------
-- Slice feedback flash (center screen text)
--------------------------------------------------------------------
local sliceFeedback = Instance.new("TextLabel")
sliceFeedback.Name = "SliceFeedback"
sliceFeedback.Text = ""
sliceFeedback.Font = Enum.Font.GothamBold
sliceFeedback.TextColor3 = Config.NEON_YELLOW
sliceFeedback.TextSize = 32
sliceFeedback.TextTransparency = 1
sliceFeedback.BackgroundTransparency = 1
sliceFeedback.Size = UDim2.new(0, 300, 0, 50)
sliceFeedback.Position = UDim2.new(0.5, 0, 0.4, 0)
sliceFeedback.AnchorPoint = Vector2.new(0.5, 0.5)
sliceFeedback.Parent = hudFrame

--------------------------------------------------------------------
-- End Run button (bottom center)
--------------------------------------------------------------------
local endRunBtn = Instance.new("TextButton")
endRunBtn.Name = "EndRun"
endRunBtn.Text = "✕  END RUN"
endRunBtn.Font = Enum.Font.GothamBold
endRunBtn.TextColor3 = Color3.new(1, 1, 1)
endRunBtn.TextSize = 16
endRunBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
endRunBtn.BackgroundTransparency = 0.3
endRunBtn.BorderSizePixel = 0
endRunBtn.Size = UDim2.new(0, 140, 0, 36)
endRunBtn.Position = UDim2.new(0.5, 0, 0.95, 0)
endRunBtn.AnchorPoint = Vector2.new(0.5, 0.5)
endRunBtn.Parent = hudFrame

local endRunCorner = Instance.new("UICorner")
endRunCorner.CornerRadius = UDim.new(0, 8)
endRunCorner.Parent = endRunBtn

endRunBtn.MouseButton1Click:Connect(function()
	EndRunEvent:FireServer()
	RunStateChanged:Fire(false)
end)

--------------------------------------------------------------------
-- Results overlay
--------------------------------------------------------------------
local resultsOverlay = Instance.new("Frame")
resultsOverlay.Name = "Results"
resultsOverlay.BackgroundColor3 = Config.BG_DARK
resultsOverlay.BackgroundTransparency = 0.15
resultsOverlay.BorderSizePixel = 0
resultsOverlay.Size = UDim2.new(0, 400, 0, 300)
resultsOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
resultsOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
resultsOverlay.Visible = false
resultsOverlay.Parent = screenGui

local resultsCorner = Instance.new("UICorner")
resultsCorner.CornerRadius = UDim.new(0, 12)
resultsCorner.Parent = resultsOverlay

local resultsStroke = Instance.new("UIStroke")
resultsStroke.Color = Config.NEON_CYAN
resultsStroke.Thickness = 2
resultsStroke.Parent = resultsOverlay

local resultsTitle = Instance.new("TextLabel")
resultsTitle.Text = "RUN COMPLETE"
resultsTitle.Font = Enum.Font.GothamBold
resultsTitle.TextColor3 = Config.NEON_CYAN
resultsTitle.TextSize = 30
resultsTitle.BackgroundTransparency = 1
resultsTitle.Size = UDim2.new(1, 0, 0, 50)
resultsTitle.Position = UDim2.new(0, 0, 0, 10)
resultsTitle.Parent = resultsOverlay

local resultsBody = Instance.new("TextLabel")
resultsBody.Name = "ResultsBody"
resultsBody.Text = ""
resultsBody.Font = Enum.Font.Gotham
resultsBody.TextColor3 = Color3.new(1, 1, 1)
resultsBody.TextSize = 18
resultsBody.BackgroundTransparency = 1
resultsBody.Size = UDim2.new(1, -40, 0, 180)
resultsBody.Position = UDim2.new(0, 20, 0, 60)
resultsBody.TextXAlignment = Enum.TextXAlignment.Left
resultsBody.TextYAlignment = Enum.TextYAlignment.Top
resultsBody.Parent = resultsOverlay

local resultsDismiss = Instance.new("TextButton")
resultsDismiss.Text = "CONTINUE"
resultsDismiss.Font = Enum.Font.GothamBold
resultsDismiss.TextColor3 = Color3.new(1, 1, 1)
resultsDismiss.TextSize = 18
resultsDismiss.BackgroundColor3 = Config.NEON_PURPLE
resultsDismiss.BackgroundTransparency = 0.1
resultsDismiss.BorderSizePixel = 0
resultsDismiss.Size = UDim2.new(0, 160, 0, 40)
resultsDismiss.Position = UDim2.new(0.5, 0, 1, -30)
resultsDismiss.AnchorPoint = Vector2.new(0.5, 1)
resultsDismiss.Parent = resultsOverlay

local dismissCorner = Instance.new("UICorner")
dismissCorner.CornerRadius = UDim.new(0, 8)
dismissCorner.Parent = resultsDismiss

resultsDismiss.MouseButton1Click:Connect(function()
	resultsOverlay.Visible = false
end)

--------------------------------------------------------------------
-- Notification toast (top)
--------------------------------------------------------------------
local notifLabel = Instance.new("TextLabel")
notifLabel.Name = "Notification"
notifLabel.Text = ""
notifLabel.Font = Enum.Font.GothamBold
notifLabel.TextColor3 = Config.NEON_YELLOW
notifLabel.TextSize = 18
notifLabel.BackgroundColor3 = Config.BG_DARK
notifLabel.BackgroundTransparency = 0.3
notifLabel.BorderSizePixel = 0
notifLabel.Size = UDim2.new(0, 400, 0, 40)
notifLabel.Position = UDim2.new(0.5, 0, 0, -50)
notifLabel.AnchorPoint = Vector2.new(0.5, 0)
notifLabel.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = notifLabel

--------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------
UpdateScoreEvent.OnClientEvent:Connect(function(score, combo, multiplier, energy)
	scoreLabel.Text = Utilities.FormatNumber(score)
	comboLabel.Text = combo > 0 and ("COMBO " .. tostring(combo)) or ""
	multiplierLabel.Text = "x" .. tostring(multiplier)
	energyLabel.Text = "⚡ " .. tostring(energy)

	-- Energy bar fill
	local fillRatio = math.clamp(energy / Config.DISTRICT_CAPTURE_ENERGY, 0, 1)
	TweenService:Create(energyFill, TweenInfo.new(0.3), {
		Size = UDim2.new(1, 0, fillRatio, 0),
	}):Play()
end)

UpdateSpeedEvent.OnClientEvent:Connect(function(speed)
	speedLabel.Text = tostring(math.floor(speed)) .. " km/h"
end)

SliceResultEvent.OnClientEvent:Connect(function(result)
	if result.Success then
		-- Flash feedback
		sliceFeedback.Text = "+" .. tostring(result.Points)
		sliceFeedback.TextTransparency = 0
		sliceFeedback.TextColor3 = result.Multiplier >= 4 and Config.NEON_YELLOW
			or result.Multiplier >= 2 and Config.NEON_PINK
			or Config.NEON_CYAN

		local tween = TweenService:Create(sliceFeedback, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.35, 0),
		})
		tween:Play()
		tween.Completed:Connect(function()
			sliceFeedback.Position = UDim2.new(0.5, 0, 0.4, 0)
		end)

		-- Combo text scale pulse
		TweenService:Create(comboLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 34,
		}):Play()
		task.delay(0.15, function()
			TweenService:Create(comboLabel, TweenInfo.new(0.2), {
				TextSize = 28,
			}):Play()
		end)
	end
end)

RunEndedEvent.OnClientEvent:Connect(function(stats)
	hudFrame.Visible = false
	if stats then
		resultsBody.Text = string.format(
			"Score: %s\nEnergy Earned: %d\nMax Multiplier: x%d\nDuration: %s",
			Utilities.FormatNumber(stats.Score or 0),
			stats.Energy or 0,
			stats.MaxCombo or 1,
			Utilities.FormatTime(stats.Duration or 0)
		)
		resultsOverlay.Visible = true
	end
end)

NotificationEvent.OnClientEvent:Connect(function(message)
	notifLabel.Text = message
	TweenService:Create(notifLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 10),
	}):Play()

	task.delay(3, function()
		TweenService:Create(notifLabel, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, -50),
		}):Play()
	end)
end)

--------------------------------------------------------------------
-- Run state
--------------------------------------------------------------------
RunStateChanged.Event:Connect(function(running)
	hudFrame.Visible = running
	if running then
		scoreLabel.Text = "0"
		comboLabel.Text = ""
		multiplierLabel.Text = "x1"
		energyLabel.Text = "⚡ 0"
		speedLabel.Text = tostring(Config.BASE_SPEED) .. " km/h"
		energyFill.Size = UDim2.new(1, 0, 0, 0)
		resultsOverlay.Visible = false
	end
end)

print("[NEON SLICE] HUD loaded ✓")
