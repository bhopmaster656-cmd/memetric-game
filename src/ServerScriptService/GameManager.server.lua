--[[
	GameManager.server.lua
	Central server-side orchestrator for NEON SLICE.
	Creates RemoteEvents, manages game state, and coordinates subsystems.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

--------------------------------------------------------------------
-- Remote Events / Functions setup
--------------------------------------------------------------------
local function createRemote(className, name)
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

-- Client -> Server
local SliceRequestEvent   = createRemote("RemoteEvent", "SliceRequest")
local StartRunEvent       = createRemote("RemoteEvent", "StartRun")
local EndRunEvent         = createRemote("RemoteEvent", "EndRun")
local JoinRaidEvent       = createRemote("RemoteEvent", "JoinRaid")
local PurchaseEvent       = createRemote("RemoteEvent", "PurchaseRequest")
local EquipKatanaEvent    = createRemote("RemoteEvent", "EquipKatana")
local SelectDistrictEvent = createRemote("RemoteEvent", "SelectDistrict")

-- Server -> Client
local SpawnBlockEvent     = createRemote("RemoteEvent", "SpawnBlock")
local SliceResultEvent    = createRemote("RemoteEvent", "SliceResult")
local UpdateScoreEvent    = createRemote("RemoteEvent", "UpdateScore")
local UpdateSpeedEvent    = createRemote("RemoteEvent", "UpdateSpeed")
local RunEndedEvent       = createRemote("RemoteEvent", "RunEnded")
local RaidUpdateEvent     = createRemote("RemoteEvent", "RaidUpdate")
local DistrictUpdateEvent = createRemote("RemoteEvent", "DistrictUpdate")
local PlayerDataEvent     = createRemote("RemoteEvent", "PlayerData")
local NotificationEvent   = createRemote("RemoteEvent", "Notification")

-- Remote Functions
local GetPlayerDataFunc   = createRemote("RemoteFunction", "GetPlayerData")
local GetDistrictsFunc    = createRemote("RemoteFunction", "GetDistricts")

--------------------------------------------------------------------
-- Per-player session state
--------------------------------------------------------------------
local playerSessions = {} -- [Player] = session table

local function createSession(player)
	return {
		Running = false,
		Score = 0,
		Combo = 0,
		Multiplier = 1,
		Energy = 0,
		Speed = Config.BASE_SPEED,
		CurrentDistrict = "Newtown",
		EquippedKatana = Config.DEFAULT_KATANA,
		RunStartTime = 0,
	}
end

--------------------------------------------------------------------
-- Player lifecycle
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	playerSessions[player] = createSession(player)

	-- Let the character load, then send initial data
	player.CharacterAdded:Connect(function(character)
		-- Anchor character during menu; gameplay manages movement
		task.wait(1)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerSessions[player] = nil
end)

--------------------------------------------------------------------
-- Start / End Run
--------------------------------------------------------------------
StartRunEvent.OnServerEvent:Connect(function(player)
	local session = playerSessions[player]
	if not session or session.Running then return end

	session.Running = true
	session.Score = 0
	session.Combo = 0
	session.Multiplier = 1
	session.Energy = 0
	session.Speed = Config.BASE_SPEED
	session.RunStartTime = tick()

	-- Un-anchor character for the run
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0 -- movement is handled by the track system
			humanoid.JumpPower = 0
		end
	end

	UpdateScoreEvent:FireClient(player, session.Score, session.Combo, session.Multiplier, session.Energy)
	UpdateSpeedEvent:FireClient(player, session.Speed)
end)

EndRunEvent.OnServerEvent:Connect(function(player)
	local session = playerSessions[player]
	if not session or not session.Running then return end

	session.Running = false
	local duration = tick() - session.RunStartTime

	RunEndedEvent:FireClient(player, {
		Score = session.Score,
		Energy = session.Energy,
		Duration = duration,
		MaxCombo = session.Multiplier,
	})
end)

--------------------------------------------------------------------
-- Slice validation
--------------------------------------------------------------------
SliceRequestEvent.OnServerEvent:Connect(function(player, blockId, sliceAngle)
	local session = playerSessions[player]
	if not session or not session.Running then return end

	-- In a full implementation this would validate the block and angle
	-- For now, accept any slice and award points
	local points = Config.POINTS_PER_SLICE
	local energy = Config.ENERGY_PER_SLICE

	session.Combo = session.Combo + 1
	session.Multiplier = math.min(
		Config.MAX_COMBO_MULTIPLIER,
		1 + math.floor(session.Combo / Config.COMBO_MULTIPLIER_STEP)
	)

	local earned = math.floor(points * session.Multiplier)
	session.Score = session.Score + earned
	session.Energy = session.Energy + energy

	-- Speed boost on successful slice
	session.Speed = math.min(Config.MAX_SPEED, session.Speed + Config.SPEED_BOOST_AMOUNT * 0.1)

	SliceResultEvent:FireClient(player, {
		Success = true,
		Points = earned,
		Combo = session.Combo,
		Multiplier = session.Multiplier,
	})
	UpdateScoreEvent:FireClient(player, session.Score, session.Combo, session.Multiplier, session.Energy)
	UpdateSpeedEvent:FireClient(player, session.Speed)
end)

--------------------------------------------------------------------
-- Katana equip
--------------------------------------------------------------------
EquipKatanaEvent.OnServerEvent:Connect(function(player, katanaName)
	local session = playerSessions[player]
	if not session then return end

	local KatanaData = require(ReplicatedStorage:WaitForChild("KatanaData"))
	if KatanaData.Katanas[katanaName] then
		session.EquippedKatana = katanaName
		PlayerDataEvent:FireClient(player, {EquippedKatana = katanaName})
	end
end)

--------------------------------------------------------------------
-- District selection
--------------------------------------------------------------------
SelectDistrictEvent.OnServerEvent:Connect(function(player, districtName)
	local session = playerSessions[player]
	if not session then return end

	local DistrictData = require(ReplicatedStorage:WaitForChild("DistrictData"))
	if DistrictData.Districts[districtName] then
		session.CurrentDistrict = districtName
		NotificationEvent:FireClient(player, "District changed to " .. districtName)
	end
end)

--------------------------------------------------------------------
-- Remote Functions
--------------------------------------------------------------------
GetPlayerDataFunc.OnServerInvoke = function(player)
	local session = playerSessions[player]
	if not session then return {} end
	return {
		Score = session.Score,
		Energy = session.Energy,
		EquippedKatana = session.EquippedKatana,
		CurrentDistrict = session.CurrentDistrict,
	}
end

GetDistrictsFunc.OnServerInvoke = function(_player)
	local DistrictData = require(ReplicatedStorage:WaitForChild("DistrictData"))
	-- Return district info plus ownership (placeholder)
	local result = {}
	for name, data in pairs(DistrictData.Districts) do
		result[name] = {
			DisplayName = data.DisplayName,
			Description = data.Description,
			Difficulty = data.Difficulty,
			Owner = "Unclaimed",
		}
	end
	return result
end

print("[NEON SLICE] GameManager loaded ✓")
