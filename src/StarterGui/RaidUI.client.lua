--[[
	RaidUI.client.lua
	Raid battle interface for 3v3 territory competitions.
	Allows players to queue for raids and shows real-time raid status.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DistrictData = require(ReplicatedStorage:WaitForChild("DistrictData"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------
local JoinRaidEvent    = ReplicatedStorage:WaitForChild("JoinRaid")
local RaidUpdateEvent  = ReplicatedStorage:WaitForChild("RaidUpdate")
local ToggleRaidUI     = ReplicatedStorage:WaitForChild("ToggleRaidUI")
local ToggleShop       = ReplicatedStorage:WaitForChild("ToggleShop")
local ToggleDistrictMap = ReplicatedStorage:WaitForChild("ToggleDistrictMap")

--------------------------------------------------------------------
-- State
--------------------------------------------------------------------
local isInQueue = false
local isInRaid = false
local currentRaid = nil

--------------------------------------------------------------------
-- ScreenGui
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RaidUIGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 30
screenGui.Parent = playerGui

-- Main container
local container = Instance.new("Frame")
container.Name = "RaidContainer"
container.BackgroundColor3 = Config.BG_DARK
container.BackgroundTransparency = 0.05
container.BorderSizePixel = 0
container.Size = UDim2.new(0, 480, 0, 400)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.Visible = false
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Config.NEON_PINK
containerStroke.Thickness = 2
containerStroke.Parent = container

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "⚔  RAID BATTLE"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Config.NEON_PINK
titleLabel.TextSize = 24
titleLabel.BackgroundColor3 = Config.NEON_PINK
titleLabel.BackgroundTransparency = 0.7
titleLabel.BorderSizePixel = 0
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Parent = container

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleLabel

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 20
closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -5, 0, 5)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Parent = container

closeBtn.MouseButton1Click:Connect(function()
	container.Visible = false
	-- Re-show main menu (only if not in a run)
	local mainMenuGui = playerGui:FindFirstChild("MainMenuGui")
	if mainMenuGui then
		local mainBg = mainMenuGui:FindFirstChild("Background")
		if mainBg and not mainBg:GetAttribute("RunActive") then
			mainBg.Visible = true
		end
	end
end)

-- Info text
local infoLabel = Instance.new("TextLabel")
infoLabel.Text = "Compete in 3v3 Raid Runs to capture city districts!\n\nOne team slices blocks for speed while the other sets traps.\nThe team with the highest score wins control of the district."
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
infoLabel.TextSize = 14
infoLabel.TextWrapped = true
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(1, -30, 0, 80)
infoLabel.Position = UDim2.new(0, 15, 0, 60)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = container

-- District selector for raid
local districtSelectorLabel = Instance.new("TextLabel")
districtSelectorLabel.Text = "Select District:"
districtSelectorLabel.Font = Enum.Font.GothamBold
districtSelectorLabel.TextColor3 = Color3.new(1, 1, 1)
districtSelectorLabel.TextSize = 16
districtSelectorLabel.BackgroundTransparency = 1
districtSelectorLabel.Size = UDim2.new(0, 150, 0, 30)
districtSelectorLabel.Position = UDim2.new(0, 15, 0, 150)
districtSelectorLabel.TextXAlignment = Enum.TextXAlignment.Left
districtSelectorLabel.Parent = container

-- District buttons
local districtButtonFrame = Instance.new("Frame")
districtButtonFrame.BackgroundTransparency = 1
districtButtonFrame.Size = UDim2.new(1, -30, 0, 100)
districtButtonFrame.Position = UDim2.new(0, 15, 0, 185)
districtButtonFrame.Parent = container

local districtLayout = Instance.new("UIListLayout")
districtLayout.FillDirection = Enum.FillDirection.Horizontal
districtLayout.Padding = UDim.new(0, 8)
districtLayout.Parent = districtButtonFrame

local selectedRaidDistrict = "Newtown"
local districtButtons = {}

for _, name in ipairs(DistrictData.GetAllNames()) do
	local data = DistrictData.Districts[name]

	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Text = data.DisplayName
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 12
	btn.BackgroundColor3 = data.ThemeColor
	btn.BackgroundTransparency = 0.4
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(0, 80, 0, 35)
	btn.Parent = districtButtonFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = data.ThemeColor
	btnStroke.Thickness = 1
	btnStroke.Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedRaidDistrict = name
		for n, b in pairs(districtButtons) do
			local s = b:FindFirstChildOfClass("UIStroke")
			if s then
				s.Thickness = n == name and 3 or 1
			end
		end
	end)

	districtButtons[name] = btn
end

-- Highlight default selection
if districtButtons[selectedRaidDistrict] then
	local s = districtButtons[selectedRaidDistrict]:FindFirstChildOfClass("UIStroke")
	if s then s.Thickness = 3 end
end

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Text = ""
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextColor3 = Config.NEON_CYAN
statusLabel.TextSize = 16
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, -30, 0, 30)
statusLabel.Position = UDim2.new(0, 15, 0, 300)
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = container

-- Join Raid button
local joinBtn = Instance.new("TextButton")
joinBtn.Name = "JoinRaid"
joinBtn.Text = "⚔  JOIN RAID QUEUE"
joinBtn.Font = Enum.Font.GothamBold
joinBtn.TextColor3 = Color3.new(1, 1, 1)
joinBtn.TextSize = 18
joinBtn.BackgroundColor3 = Config.NEON_PINK
joinBtn.BackgroundTransparency = 0.1
joinBtn.BorderSizePixel = 0
joinBtn.Size = UDim2.new(0, 250, 0, 45)
joinBtn.Position = UDim2.new(0.5, 0, 1, -30)
joinBtn.AnchorPoint = Vector2.new(0.5, 1)
joinBtn.Parent = container

local joinCorner = Instance.new("UICorner")
joinCorner.CornerRadius = UDim.new(0, 8)
joinCorner.Parent = joinBtn

joinBtn.MouseButton1Click:Connect(function()
	if not isInQueue and not isInRaid then
		JoinRaidEvent:FireServer(selectedRaidDistrict)
		isInQueue = true
		statusLabel.Text = "Searching for opponents..."
		joinBtn.Text = "QUEUED..."
		joinBtn.BackgroundTransparency = 0.5
	end
end)

--------------------------------------------------------------------
-- Raid updates from server
--------------------------------------------------------------------
RaidUpdateEvent.OnClientEvent:Connect(function(update)
	if update.Type == "RaidStart" then
		isInQueue = false
		isInRaid = true
		currentRaid = update
		statusLabel.Text = "RAID STARTED! Role: " .. update.Role
		joinBtn.Text = "IN RAID"
		joinBtn.BackgroundColor3 = Config.NEON_CYAN

	elseif update.Type == "RaidEnd" then
		isInRaid = false
		currentRaid = nil
		local won = (update.Winner == "TeamA") -- simplified
		statusLabel.Text = won and "VICTORY! 🎉" or "DEFEAT..."
		statusLabel.TextColor3 = won and Config.NEON_YELLOW or Color3.fromRGB(255, 80, 80)
		joinBtn.Text = "⚔  JOIN RAID QUEUE"
		joinBtn.BackgroundColor3 = Config.NEON_PINK
		joinBtn.BackgroundTransparency = 0.1

		-- Reset status after delay
		task.delay(5, function()
			statusLabel.Text = ""
			statusLabel.TextColor3 = Config.NEON_CYAN
		end)
	end
end)

--------------------------------------------------------------------
-- Helper: close other menus
--------------------------------------------------------------------
local function closeOtherMenus()
	local shopGui = playerGui:FindFirstChild("ShopGui")
	if shopGui then
		local shopContainer = shopGui:FindFirstChild("ShopContainer")
		if shopContainer then shopContainer.Visible = false end
	end
	local districtGui = playerGui:FindFirstChild("DistrictMapGui")
	if districtGui then
		local mapContainer = districtGui:FindFirstChild("MapContainer")
		if mapContainer then mapContainer.Visible = false end
	end
end

--------------------------------------------------------------------
-- Toggle
--------------------------------------------------------------------
ToggleRaidUI.Event:Connect(function()
	container.Visible = not container.Visible
	if container.Visible then
		closeOtherMenus()
	end
end)

print("[NEON SLICE] RaidUI loaded ✓")
