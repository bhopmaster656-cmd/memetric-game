--[[
	BlockSpawner.server.lua
	Spawns neon blocks ahead of each active runner.
	Blocks are streamed to the client via RemoteEvents for local rendering.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local BlockTypes = require(ReplicatedStorage:WaitForChild("BlockTypes"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

--------------------------------------------------------------------
-- Wait for GameManager to create remotes
--------------------------------------------------------------------
local SpawnBlockEvent = ReplicatedStorage:WaitForChild("SpawnBlock")
local StartRunEvent   = ReplicatedStorage:WaitForChild("StartRun")
local EndRunEvent     = ReplicatedStorage:WaitForChild("EndRun")

--------------------------------------------------------------------
-- State
--------------------------------------------------------------------
local activeSpawners = {} -- [Player] = spawner coroutine / flag
local blockIdCounter = 0

local function nextBlockId()
	blockIdCounter = blockIdCounter + 1
	return blockIdCounter
end

--------------------------------------------------------------------
-- Spawn loop per player
--------------------------------------------------------------------
local function spawnLoop(player)
	activeSpawners[player] = true

	while activeSpawners[player] and player.Parent do
		-- Pick a random block type
		local typeName, typeData = BlockTypes.GetRandomType()

		-- Choose a random lane (-1 = left, 0 = center, 1 = right)
		local lane = math.random(-1, 1)
		local laneOffset = lane * Config.LANE_WIDTH

		-- Determine a random slice line angle for the block
		local sliceAngle = 0
		if typeData.SliceDirection == "Horizontal" then
			sliceAngle = 0
		elseif typeData.SliceDirection == "Vertical" then
			sliceAngle = 90
		elseif typeData.SliceDirection == "Any" then
			sliceAngle = math.random(0, 3) * 45 -- 0, 45, 90, 135
		end

		local blockId = nextBlockId()

		-- Send block info to the client so it can render it
		SpawnBlockEvent:FireClient(player, {
			Id = blockId,
			TypeName = typeName,
			Lane = lane,
			LaneOffset = laneOffset,
			Size = typeData.Size,
			Color = {typeData.Color.R, typeData.Color.G, typeData.Color.B},
			Material = typeData.Material.Name,
			SliceAngle = sliceAngle,
			SliceDirection = typeData.SliceDirection,
			Points = typeData.Points,
			Energy = typeData.Energy,
			SpawnDistance = Config.BLOCK_SPAWN_DISTANCE,
		})

		-- Wait for the next spawn interval (speeds up as player goes faster)
		local interval = Utilities.Lerp(
			Config.BLOCK_MAX_INTERVAL,
			Config.BLOCK_MIN_INTERVAL,
			0.5 -- placeholder difficulty scaling
		)
		task.wait(interval)
	end
end

--------------------------------------------------------------------
-- Listen for run start / end
--------------------------------------------------------------------
StartRunEvent.OnServerEvent:Connect(function(player)
	-- Start spawning blocks for this player
	if not activeSpawners[player] then
		task.spawn(spawnLoop, player)
	end
end)

EndRunEvent.OnServerEvent:Connect(function(player)
	activeSpawners[player] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	activeSpawners[player] = nil
end)

print("[NEON SLICE] BlockSpawner loaded ✓")
