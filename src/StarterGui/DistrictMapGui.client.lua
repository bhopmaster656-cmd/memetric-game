--[[
	DistrictMapGui.client.lua
	City district map showing territory ownership and status.
	Players can select districts for their runs and view guild control.
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
local SelectDistrictEvent = ReplicatedStorage:WaitForChild("SelectDistrict")
local DistrictUpdateEvent = ReplicatedStorage:WaitForChild("DistrictUpdate")
local ToggleDistrictMap   = ReplicatedStorage:WaitForChild("ToggleDistrictMap")
local ToggleShop          = ReplicatedStorage:WaitForChild("ToggleShop")
local ToggleRaidUI        = ReplicatedStorage:WaitForChild("ToggleRaidUI")
local GetDistrictsFunc    = ReplicatedStorage:WaitForChild("GetDistricts")

--------------------------------------------------------------------
-- State
--------------------------------------------------------------------
local selectedDistrict = "Newtown"
local districtOwnership = {} -- [name] = owner string

--------------------------------------------------------------------
-- ScreenGui
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DistrictMapGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 30
screenGui.Parent = playerGui

-- Main container
local container = Instance.new("Frame")
container.Name = "MapContainer"
container.BackgroundColor3 = Config.BG_DARK
container.BackgroundTransparency = 0.05
container.BorderSizePixel = 0
container.Size = UDim2.new(0, 600, 0, 450)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.Visible = false
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Config.NEON_BLUE
containerStroke.Thickness = 2
containerStroke.Parent = container

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "🗺  NEON CITY — DISTRICT MAP"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Config.NEON_CYAN
titleLabel.TextSize = 22
titleLabel.BackgroundColor3 = Config.NEON_BLUE
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
		local bg = mainMenuGui:FindFirstChild("Background")
		if bg and not bg:GetAttribute("RunActive") then
			bg.Visible = true
		end
	end
end)

-- Map area (grid of district tiles)
local mapArea = Instance.new("Frame")
mapArea.BackgroundTransparency = 1
mapArea.Size = UDim2.new(1, -20, 1, -120)
mapArea.Position = UDim2.new(0, 10, 0, 60)
mapArea.Parent = container

-- Detail panel at the bottom
local detailPanel = Instance.new("Frame")
detailPanel.BackgroundColor3 = Color3.fromRGB(20, 15, 40)
detailPanel.BackgroundTransparency = 0.3
detailPanel.BorderSizePixel = 0
detailPanel.Size = UDim2.new(1, -20, 0, 55)
detailPanel.Position = UDim2.new(0, 10, 1, -60)
detailPanel.Parent = container

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 8)
detailCorner.Parent = detailPanel

local detailText = Instance.new("TextLabel")
detailText.Name = "DetailText"
detailText.Text = "Select a district to begin your run."
detailText.Font = Enum.Font.Gotham
detailText.TextColor3 = Color3.fromRGB(200, 200, 220)
detailText.TextSize = 14
detailText.TextWrapped = true
detailText.BackgroundTransparency = 1
detailText.Size = UDim2.new(0.65, 0, 1, -10)
detailText.Position = UDim2.new(0, 10, 0, 5)
detailText.TextXAlignment = Enum.TextXAlignment.Left
detailText.Parent = detailPanel

local selectBtn = Instance.new("TextButton")
selectBtn.Text = "SELECT"
selectBtn.Font = Enum.Font.GothamBold
selectBtn.TextColor3 = Color3.new(1, 1, 1)
selectBtn.TextSize = 16
selectBtn.BackgroundColor3 = Config.NEON_CYAN
selectBtn.BackgroundTransparency = 0.1
selectBtn.BorderSizePixel = 0
selectBtn.Size = UDim2.new(0, 120, 0, 35)
selectBtn.Position = UDim2.new(1, -10, 0.5, 0)
selectBtn.AnchorPoint = Vector2.new(1, 0.5)
selectBtn.Parent = detailPanel

local selectCorner = Instance.new("UICorner")
selectCorner.CornerRadius = UDim.new(0, 8)
selectCorner.Parent = selectBtn

selectBtn.MouseButton1Click:Connect(function()
	SelectDistrictEvent:FireServer(selectedDistrict)
	container.Visible = false
	-- Re-show main menu (only if not in a run)
	local mainMenuGui = playerGui:FindFirstChild("MainMenuGui")
	if mainMenuGui then
		local bg = mainMenuGui:FindFirstChild("Background")
		if bg and not bg:GetAttribute("RunActive") then
			bg.Visible = true
		end
	end
end)

--------------------------------------------------------------------
-- Build district tiles
--------------------------------------------------------------------
local districtTiles = {}

local function buildMap()
	-- Clear existing tiles
	for _, tile in pairs(districtTiles) do
		tile:Destroy()
	end
	districtTiles = {}

	local names = DistrictData.GetAllNames()
	local cols = 3
	local tileWidth = (mapArea.AbsoluteSize.X - 20) / cols
	local tileHeight = 90

	for i, name in ipairs(names) do
		local data = DistrictData.Districts[name]
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local owner = districtOwnership[name] or "Unclaimed"

		local tile = Instance.new("TextButton")
		tile.Name = name
		tile.Text = ""
		tile.BackgroundColor3 = data.ThemeColor
		tile.BackgroundTransparency = 0.6
		tile.BorderSizePixel = 0
		tile.Size = UDim2.new(0, tileWidth - 8, 0, tileHeight)
		tile.Position = UDim2.new(0, col * tileWidth + 4, 0, row * (tileHeight + 8))
		tile.Parent = mapArea

		local tileCorner = Instance.new("UICorner")
		tileCorner.CornerRadius = UDim.new(0, 8)
		tileCorner.Parent = tile

		local tileStroke = Instance.new("UIStroke")
		tileStroke.Color = selectedDistrict == name and Config.NEON_CYAN or data.ThemeColor
		tileStroke.Thickness = selectedDistrict == name and 3 or 1
		tileStroke.Parent = tile

		-- District name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Text = data.DisplayName
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 16
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, -10, 0, 22)
		nameLabel.Position = UDim2.new(0, 5, 0, 8)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = tile

		-- Difficulty stars
		local diffLabel = Instance.new("TextLabel")
		diffLabel.Text = string.rep("★", data.Difficulty) .. string.rep("☆", 5 - data.Difficulty)
		diffLabel.Font = Enum.Font.Gotham
		diffLabel.TextColor3 = Config.NEON_YELLOW
		diffLabel.TextSize = 12
		diffLabel.BackgroundTransparency = 1
		diffLabel.Size = UDim2.new(1, -10, 0, 16)
		diffLabel.Position = UDim2.new(0, 5, 0, 30)
		diffLabel.TextXAlignment = Enum.TextXAlignment.Left
		diffLabel.Parent = tile

		-- Owner
		local ownerLabel = Instance.new("TextLabel")
		ownerLabel.Text = "Owner: " .. owner
		ownerLabel.Font = Enum.Font.Gotham
		ownerLabel.TextColor3 = owner == "Unclaimed" and Color3.fromRGB(150, 150, 170) or Config.NEON_CYAN
		ownerLabel.TextSize = 11
		ownerLabel.BackgroundTransparency = 1
		ownerLabel.Size = UDim2.new(1, -10, 0, 16)
		ownerLabel.Position = UDim2.new(0, 5, 0, 48)
		ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
		ownerLabel.Parent = tile

		-- XP bonus
		local bonusLabel = Instance.new("TextLabel")
		bonusLabel.Text = "+" .. tostring(math.floor((data.BonusXP - 1) * 100)) .. "% XP"
		bonusLabel.Font = Enum.Font.GothamBold
		bonusLabel.TextColor3 = Config.NEON_YELLOW
		bonusLabel.TextSize = 11
		bonusLabel.BackgroundTransparency = 1
		bonusLabel.Size = UDim2.new(1, -10, 0, 16)
		bonusLabel.Position = UDim2.new(0, 5, 0, 66)
		bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
		bonusLabel.Parent = tile

		tile.MouseButton1Click:Connect(function()
			selectedDistrict = name
			detailText.Text = data.DisplayName .. " — " .. data.Description
			buildMap() -- refresh selection
		end)

		districtTiles[name] = tile
	end
end

--------------------------------------------------------------------
-- Helper: close other menus
--------------------------------------------------------------------
local function closeOtherMenus()
	local shopGui = playerGui:FindFirstChild("ShopGui")
	if shopGui then
		local shopContainer = shopGui:FindFirstChild("ShopContainer")
		if shopContainer then shopContainer.Visible = false end
	end
	local raidGui = playerGui:FindFirstChild("RaidUIGui")
	if raidGui then
		local raidContainer = raidGui:FindFirstChild("RaidContainer")
		if raidContainer then raidContainer.Visible = false end
	end
end

--------------------------------------------------------------------
-- Toggle
--------------------------------------------------------------------
ToggleDistrictMap.Event:Connect(function()
	container.Visible = not container.Visible
	if container.Visible then
		closeOtherMenus()
		-- Fetch latest ownership
		local ok, districts = pcall(function()
			return GetDistrictsFunc:InvokeServer()
		end)
		if ok and districts then
			for name, info in pairs(districts) do
				districtOwnership[name] = info.Owner
			end
		end
		buildMap()
	end
end)

--------------------------------------------------------------------
-- District updates from server
--------------------------------------------------------------------
DistrictUpdateEvent.OnClientEvent:Connect(function(update)
	if update.Type == "Captured" then
		districtOwnership[update.District] = update.NewOwner
		if container.Visible then buildMap() end
	elseif update.Type == "FullUpdate" and update.Districts then
		for name, info in pairs(update.Districts) do
			districtOwnership[name] = info.Owner
		end
		if container.Visible then buildMap() end
	end
end)

print("[NEON SLICE] DistrictMapGui loaded ✓")
