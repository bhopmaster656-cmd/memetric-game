--[[
	PlayerDataStore.server.lua
	Persists player data (currency, unlocked katanas, stats) using DataStoreService.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local KatanaData = require(ReplicatedStorage:WaitForChild("KatanaData"))

--------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------
local PlayerDataEvent  = ReplicatedStorage:WaitForChild("PlayerData")
local PurchaseEvent    = ReplicatedStorage:WaitForChild("PurchaseRequest")
local NotificationEvent = ReplicatedStorage:WaitForChild("Notification")
local GetPlayerDataFunc = ReplicatedStorage:WaitForChild("GetPlayerData")

--------------------------------------------------------------------
-- DataStore setup
--------------------------------------------------------------------
local DATA_STORE_NAME = "NeonSlice_PlayerData_v1"
local playerDataStore

-- pcall DataStore creation (may fail in Studio without API access)
local ok, store = pcall(function()
	return DataStoreService:GetDataStore(DATA_STORE_NAME)
end)
if ok then
	playerDataStore = store
else
	warn("[NEON SLICE] DataStore not available (Studio mode). Using in-memory storage.")
end

--------------------------------------------------------------------
-- In-memory cache
--------------------------------------------------------------------
local dataCache = {} -- [UserId] = data table

local DEFAULT_DATA = {
	Currency = 0,
	TotalScore = 0,
	TotalRuns = 0,
	BestScore = 0,
	UnlockedKatanas = {NeonBlade = true},
	EquippedKatana = Config.DEFAULT_KATANA,
	UnlockedTrails = {},
	EquippedTrail = "",
}

local function deepCopy(orig)
	if type(orig) ~= "table" then return orig end
	local copy = {}
	for k, v in pairs(orig) do
		copy[k] = deepCopy(v)
	end
	return copy
end

--------------------------------------------------------------------
-- Load / Save
--------------------------------------------------------------------
local function loadData(player)
	local userId = player.UserId
	local data

	if playerDataStore then
		local success, result = pcall(function()
			return playerDataStore:GetAsync("Player_" .. tostring(userId))
		end)
		if success and result then
			data = result
		end
	end

	if not data then
		data = deepCopy(DEFAULT_DATA)
	end

	-- Ensure all fields exist (forward compatibility)
	for key, value in pairs(DEFAULT_DATA) do
		if data[key] == nil then
			data[key] = deepCopy(value)
		end
	end

	dataCache[userId] = data
	return data
end

local function saveData(player)
	local userId = player.UserId
	local data = dataCache[userId]
	if not data or not playerDataStore then return end

	local success, err = pcall(function()
		playerDataStore:SetAsync("Player_" .. tostring(userId), data)
	end)
	if not success then
		warn("[NEON SLICE] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

--------------------------------------------------------------------
-- Player lifecycle
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	local data = loadData(player)
	-- Send initial data to client
	task.wait(2) -- wait for client to be ready
	PlayerDataEvent:FireClient(player, data)
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	dataCache[player.UserId] = nil
end)

-- Auto-save every 5 minutes
task.spawn(function()
	while true do
		task.wait(300)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

--------------------------------------------------------------------
-- Purchase handling
--------------------------------------------------------------------
PurchaseEvent.OnServerEvent:Connect(function(player, itemType, itemName)
	local userId = player.UserId
	local data = dataCache[userId]
	if not data then return end

	if itemType == "Katana" then
		local katana = KatanaData.Katanas[itemName]
		if not katana then
			NotificationEvent:FireClient(player, "Katana not found!")
			return
		end

		if data.UnlockedKatanas[itemName] then
			NotificationEvent:FireClient(player, "You already own this katana!")
			return
		end

		if data.Currency < katana.Price then
			NotificationEvent:FireClient(player, "Not enough currency!")
			return
		end

		data.Currency = data.Currency - katana.Price
		data.UnlockedKatanas[itemName] = true
		PlayerDataEvent:FireClient(player, {
			Currency = data.Currency,
			UnlockedKatanas = data.UnlockedKatanas,
		})
		NotificationEvent:FireClient(player, "Unlocked " .. katana.DisplayName .. "!")
	end
end)

--------------------------------------------------------------------
-- Update GetPlayerData to use saved data
--------------------------------------------------------------------
GetPlayerDataFunc.OnServerInvoke = function(player)
	local data = dataCache[player.UserId]
	if not data then
		return deepCopy(DEFAULT_DATA)
	end
	return deepCopy(data)
end

print("[NEON SLICE] PlayerDataStore loaded ✓")
