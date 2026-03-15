--[[
	RaidSystem.server.lua
	Manages 3-on-3 raid battles for territory control.
	Teams compete: one team slices for speed, the other sets traps.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

--------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------
local JoinRaidEvent   = ReplicatedStorage:WaitForChild("JoinRaid")
local RaidUpdateEvent = ReplicatedStorage:WaitForChild("RaidUpdate")
local NotificationEvent = ReplicatedStorage:WaitForChild("Notification")

--------------------------------------------------------------------
-- Raid queue and state
--------------------------------------------------------------------
local raidQueue = {} -- list of {Player, DistrictName}
local activeRaids = {} -- raidId -> raid state

local raidIdCounter = 0

local function newRaidId()
	raidIdCounter = raidIdCounter + 1
	return raidIdCounter
end

--------------------------------------------------------------------
-- Match-making
--------------------------------------------------------------------
local function tryMatchmake(districtName)
	-- Collect players queued for this district
	local candidates = {}
	for i, entry in ipairs(raidQueue) do
		if entry.District == districtName then
			table.insert(candidates, {Index = i, Player = entry.Player})
		end
	end

	local teamSize = Config.RAID_TEAM_SIZE
	if #candidates < teamSize * 2 then
		return -- not enough players
	end

	-- Form two teams from the first available players
	local teamA = {}
	local teamB = {}
	local toRemove = {}

	for i, c in ipairs(candidates) do
		if #teamA < teamSize then
			table.insert(teamA, c.Player)
			table.insert(toRemove, c.Index)
		elseif #teamB < teamSize then
			table.insert(teamB, c.Player)
			table.insert(toRemove, c.Index)
		end
		if #teamA == teamSize and #teamB == teamSize then
			break
		end
	end

	-- Remove matched players from queue (reverse order to preserve indices)
	table.sort(toRemove, function(a, b) return a > b end)
	for _, idx in ipairs(toRemove) do
		table.remove(raidQueue, idx)
	end

	-- Create raid
	local raidId = newRaidId()
	local raid = {
		Id = raidId,
		District = districtName,
		TeamA = teamA, -- Slicers
		TeamB = teamB, -- Trappers
		ScoreA = 0,
		ScoreB = 0,
		StartTime = tick(),
		Duration = Config.RAID_DURATION,
		Active = true,
	}
	activeRaids[raidId] = raid

	-- Notify all participants
	for _, p in ipairs(teamA) do
		RaidUpdateEvent:FireClient(p, {
			Type = "RaidStart",
			RaidId = raidId,
			Role = "Slicer",
			District = districtName,
			Duration = Config.RAID_DURATION,
			Teammates = {}, -- could send names
		})
	end
	for _, p in ipairs(teamB) do
		RaidUpdateEvent:FireClient(p, {
			Type = "RaidStart",
			RaidId = raidId,
			Role = "Trapper",
			District = districtName,
			Duration = Config.RAID_DURATION,
			Teammates = {},
		})
	end

	-- Schedule raid end
	task.delay(Config.RAID_DURATION, function()
		if raid.Active then
			endRaid(raid)
		end
	end)

	return raid
end

--------------------------------------------------------------------
-- End raid
--------------------------------------------------------------------
function endRaid(raid) -- luacheck: ignore (forward declaration)
	raid.Active = false
	local winner = raid.ScoreA >= raid.ScoreB and "TeamA" or "TeamB"

	local result = {
		Type = "RaidEnd",
		RaidId = raid.Id,
		Winner = winner,
		ScoreA = raid.ScoreA,
		ScoreB = raid.ScoreB,
		District = raid.District,
	}

	local allPlayers = {}
	for _, p in ipairs(raid.TeamA) do table.insert(allPlayers, p) end
	for _, p in ipairs(raid.TeamB) do table.insert(allPlayers, p) end

	for _, p in ipairs(allPlayers) do
		if p.Parent then -- still in game
			RaidUpdateEvent:FireClient(p, result)
		end
	end

	activeRaids[raid.Id] = nil
end

--------------------------------------------------------------------
-- Join raid request
--------------------------------------------------------------------
JoinRaidEvent.OnServerEvent:Connect(function(player, districtName)
	-- Check player isn't already in queue or in a raid
	for _, entry in ipairs(raidQueue) do
		if entry.Player == player then
			NotificationEvent:FireClient(player, "You are already in the raid queue!")
			return
		end
	end

	for _, raid in pairs(activeRaids) do
		for _, p in ipairs(raid.TeamA) do
			if p == player then
				NotificationEvent:FireClient(player, "You are already in an active raid!")
				return
			end
		end
		for _, p in ipairs(raid.TeamB) do
			if p == player then
				NotificationEvent:FireClient(player, "You are already in an active raid!")
				return
			end
		end
	end

	table.insert(raidQueue, {Player = player, District = districtName, JoinTime = tick()})
	NotificationEvent:FireClient(player, "Joined raid queue for " .. districtName .. "...")

	-- Attempt matchmaking
	tryMatchmake(districtName)
end)

--------------------------------------------------------------------
-- Clean up on player leave
--------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	-- Remove from queue
	for i = #raidQueue, 1, -1 do
		if raidQueue[i].Player == player then
			table.remove(raidQueue, i)
		end
	end
end)

print("[NEON SLICE] RaidSystem loaded ✓")
