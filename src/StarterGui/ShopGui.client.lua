--[[
	ShopGui.client.lua
	Katana shop interface.
	Players can browse, purchase, and equip katanas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local KatanaData = require(ReplicatedStorage:WaitForChild("KatanaData"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------
local PurchaseEvent    = ReplicatedStorage:WaitForChild("PurchaseRequest")
local EquipKatanaEvent = ReplicatedStorage:WaitForChild("EquipKatana")
local PlayerDataEvent  = ReplicatedStorage:WaitForChild("PlayerData")
local ToggleShop       = ReplicatedStorage:WaitForChild("ToggleShop")
local ToggleDistrictMap = ReplicatedStorage:WaitForChild("ToggleDistrictMap")
local ToggleRaidUI     = ReplicatedStorage:WaitForChild("ToggleRaidUI")
local NotificationEvent = ReplicatedStorage:WaitForChild("Notification")

--------------------------------------------------------------------
-- Player data cache
--------------------------------------------------------------------
local playerCurrency = 0
local unlockedKatanas = {NeonBlade = true}
local equippedKatana = Config.DEFAULT_KATANA

--------------------------------------------------------------------
-- ScreenGui
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 30
screenGui.Parent = playerGui

-- Main container
local container = Instance.new("Frame")
container.Name = "ShopContainer"
container.BackgroundColor3 = Config.BG_DARK
container.BackgroundTransparency = 0.05
container.BorderSizePixel = 0
container.Size = UDim2.new(0, 520, 0, 440)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.Visible = false
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Config.NEON_PURPLE
containerStroke.Thickness = 2
containerStroke.Parent = container

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.BackgroundColor3 = Config.NEON_PURPLE
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.Parent = container

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "🗡  KATANA SHOP"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 22
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Currency display
local currencyLabel = Instance.new("TextLabel")
currencyLabel.Name = "Currency"
currencyLabel.Text = "💰 0"
currencyLabel.Font = Enum.Font.GothamBold
currencyLabel.TextColor3 = Config.NEON_YELLOW
currencyLabel.TextSize = 18
currencyLabel.BackgroundTransparency = 1
currencyLabel.Size = UDim2.new(0.3, -15, 1, 0)
currencyLabel.Position = UDim2.new(0.7, 0, 0, 0)
currencyLabel.TextXAlignment = Enum.TextXAlignment.Right
currencyLabel.Parent = titleBar

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

-- Scrolling frame for katana cards
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Config.NEON_CYAN
scrollFrame.Parent = container

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 230, 0, 140)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollFrame

--------------------------------------------------------------------
-- Build katana cards
--------------------------------------------------------------------
local function buildCards()
	-- Clear existing
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local sorted = KatanaData.GetSortedList()
	for i, entry in ipairs(sorted) do
		local name = entry.Name
		local data = entry.Data
		local owned = unlockedKatanas[name] or false
		local equipped = equippedKatana == name
		local rarityColor = KatanaData.RarityColors[data.Rarity] or Color3.new(1, 1, 1)

		local card = Instance.new("Frame")
		card.Name = name
		card.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
		card.BackgroundTransparency = 0.1
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = equipped and Config.NEON_CYAN or rarityColor
		cardStroke.Thickness = equipped and 3 or 1
		cardStroke.Transparency = 0.3
		cardStroke.Parent = card

		-- Color preview bar
		local preview = Instance.new("Frame")
		preview.BackgroundColor3 = data.BladeColor
		preview.BorderSizePixel = 0
		preview.Size = UDim2.new(1, 0, 0, 6)
		preview.Parent = card

		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 8)
		previewCorner.Parent = preview

		-- Katana name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Text = data.DisplayName
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 16
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, -10, 0, 22)
		nameLabel.Position = UDim2.new(0, 5, 0, 12)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Rarity
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Text = data.Rarity
		rarityLabel.Font = Enum.Font.Gotham
		rarityLabel.TextColor3 = rarityColor
		rarityLabel.TextSize = 12
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Size = UDim2.new(1, -10, 0, 16)
		rarityLabel.Position = UDim2.new(0, 5, 0, 34)
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.Parent = card

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Text = data.Description
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
		descLabel.TextSize = 11
		descLabel.TextWrapped = true
		descLabel.BackgroundTransparency = 1
		descLabel.Size = UDim2.new(1, -10, 0, 36)
		descLabel.Position = UDim2.new(0, 5, 0, 52)
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = card

		-- Action button
		local actionBtn = Instance.new("TextButton")
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextColor3 = Color3.new(1, 1, 1)
		actionBtn.TextSize = 14
		actionBtn.BorderSizePixel = 0
		actionBtn.Size = UDim2.new(1, -20, 0, 30)
		actionBtn.Position = UDim2.new(0, 10, 1, -40)
		actionBtn.Parent = card

		local actionCorner = Instance.new("UICorner")
		actionCorner.CornerRadius = UDim.new(0, 6)
		actionCorner.Parent = actionBtn

		if equipped then
			actionBtn.Text = "EQUIPPED"
			actionBtn.BackgroundColor3 = Config.NEON_CYAN
			actionBtn.BackgroundTransparency = 0.3
		elseif owned then
			actionBtn.Text = "EQUIP"
			actionBtn.BackgroundColor3 = Config.NEON_PURPLE
			actionBtn.BackgroundTransparency = 0.1
			actionBtn.MouseButton1Click:Connect(function()
				EquipKatanaEvent:FireServer(name)
				equippedKatana = name
				buildCards()
			end)
		else
			actionBtn.Text = "💰 " .. Utilities.FormatNumber(data.Price)
			actionBtn.BackgroundColor3 = Config.NEON_YELLOW
			actionBtn.BackgroundTransparency = 0.2
			actionBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
			actionBtn.MouseButton1Click:Connect(function()
				PurchaseEvent:FireServer("Katana", name)
			end)
		end
	end

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
end

--------------------------------------------------------------------
-- Helper: close other menus
--------------------------------------------------------------------
local function closeOtherMenus()
	local districtGui = playerGui:FindFirstChild("DistrictMapGui")
	if districtGui then
		local mapContainer = districtGui:FindFirstChild("MapContainer")
		if mapContainer then mapContainer.Visible = false end
	end
	local raidGui = playerGui:FindFirstChild("RaidUIGui")
	if raidGui then
		local raidContainer = raidGui:FindFirstChild("RaidContainer")
		if raidContainer then raidContainer.Visible = false end
	end
end

--------------------------------------------------------------------
-- Toggle visibility
--------------------------------------------------------------------
ToggleShop.Event:Connect(function()
	container.Visible = not container.Visible
	if container.Visible then
		closeOtherMenus()
		buildCards()
	end
end)

--------------------------------------------------------------------
-- Update from server
--------------------------------------------------------------------
PlayerDataEvent.OnClientEvent:Connect(function(data)
	if data.Currency ~= nil then
		playerCurrency = data.Currency
		currencyLabel.Text = "💰 " .. Utilities.FormatNumber(playerCurrency)
	end
	if data.UnlockedKatanas then
		unlockedKatanas = data.UnlockedKatanas
	end
	if data.EquippedKatana then
		equippedKatana = data.EquippedKatana
	end
	if container.Visible then
		buildCards()
	end
end)

print("[NEON SLICE] ShopGui loaded ✓")
