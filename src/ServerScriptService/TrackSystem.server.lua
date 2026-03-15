--[[
	TrackSystem.server.lua
	Manages the procedural track that the player rides along.
	Creates and recycles track segments as the player moves forward.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

--------------------------------------------------------------------
-- Track folder in Workspace
--------------------------------------------------------------------
local trackFolder = Instance.new("Folder")
trackFolder.Name = "Track"
trackFolder.Parent = Workspace

--------------------------------------------------------------------
-- Segment creation
--------------------------------------------------------------------
local SEGMENT_LENGTH = Config.TRACK_SEGMENT_LENGTH
local SEGMENTS_AHEAD = 3
local SEGMENTS_BEHIND = 1

local function createTrackSegment(index)
	local zPos = index * SEGMENT_LENGTH

	local segment = Instance.new("Model")
	segment.Name = "Segment_" .. tostring(index)

	-- Main rail (center lane)
	local rail = Utilities.CreateNeonPart(
		Vector3.new(Config.LANE_WIDTH * 3 + 4, 1, SEGMENT_LENGTH),
		Config.BG_DARK,
		Vector3.new(0, 0, zPos + SEGMENT_LENGTH / 2)
	)
	rail.Material = Enum.Material.SmoothPlastic
	rail.Transparency = 0.3
	rail.CanCollide = true
	rail.Name = "Floor"
	rail.Parent = segment

	-- Neon lane dividers
	for lane = -1, 1 do
		local divider = Utilities.CreateNeonPart(
			Vector3.new(0.3, 0.3, SEGMENT_LENGTH),
			Config.NEON_CYAN,
			Vector3.new(lane * Config.LANE_WIDTH, 0.6, zPos + SEGMENT_LENGTH / 2)
		)
		divider.Name = "LaneDivider_" .. tostring(lane)
		divider.Parent = segment
	end

	-- Side walls with neon strips
	for side = -1, 1, 2 do
		local wall = Utilities.CreateNeonPart(
			Vector3.new(1, 12, SEGMENT_LENGTH),
			Config.BG_DARK,
			Vector3.new(side * (Config.LANE_WIDTH * 1.5 + 3), 6, zPos + SEGMENT_LENGTH / 2)
		)
		wall.Material = Enum.Material.SmoothPlastic
		wall.Transparency = 0.5
		wall.Name = "Wall_" .. (side == -1 and "Left" or "Right")
		wall.Parent = segment

		-- Neon strip along wall
		local strip = Utilities.CreateNeonPart(
			Vector3.new(0.2, 0.4, SEGMENT_LENGTH),
			side == -1 and Config.NEON_PURPLE or Config.NEON_PINK,
			Vector3.new(side * (Config.LANE_WIDTH * 1.5 + 2.5), 3, zPos + SEGMENT_LENGTH / 2)
		)
		strip.Name = "NeonStrip_" .. (side == -1 and "Left" or "Right")
		strip.Parent = segment
	end

	-- Random neon decorations
	for i = 1, 4 do
		local zOffset = math.random(10, SEGMENT_LENGTH - 10)
		local side = (math.random(0, 1) == 0) and -1 or 1
		local height = math.random(4, 10)
		local colors = {Config.NEON_PURPLE, Config.NEON_BLUE, Config.NEON_PINK, Config.NEON_CYAN}
		local color = colors[math.random(1, #colors)]

		local deco = Utilities.CreateNeonPart(
			Vector3.new(0.5, math.random(2, 6), 0.5),
			color,
			Vector3.new(
				side * (Config.LANE_WIDTH * 1.5 + 5 + math.random(0, 5)),
				height,
				zPos + zOffset
			)
		)
		deco.Name = "Decoration_" .. tostring(i)
		deco.Parent = segment
	end

	segment.Parent = trackFolder
	return segment
end

--------------------------------------------------------------------
-- Per-player track management
--------------------------------------------------------------------
local playerSegments = {} -- [Player] = {currentIndex, segments = {}}

local function updateTrackForPlayer(player, zPosition)
	local data = playerSegments[player]
	if not data then return end

	local currentIndex = math.floor(zPosition / SEGMENT_LENGTH)

	-- Create segments ahead
	for i = currentIndex - SEGMENTS_BEHIND, currentIndex + SEGMENTS_AHEAD do
		if not data.segments[i] then
			data.segments[i] = createTrackSegment(i)
		end
	end

	-- Remove segments too far behind
	for idx, seg in pairs(data.segments) do
		if idx < currentIndex - SEGMENTS_BEHIND - 1 then
			seg:Destroy()
			data.segments[idx] = nil
		end
	end

	data.currentIndex = currentIndex
end

--------------------------------------------------------------------
-- Run lifecycle
--------------------------------------------------------------------
local StartRunEvent = ReplicatedStorage:WaitForChild("StartRun")
local EndRunEvent   = ReplicatedStorage:WaitForChild("EndRun")
local UpdateSpeedEvent = ReplicatedStorage:WaitForChild("UpdateSpeed")

StartRunEvent.OnServerEvent:Connect(function(player)
	playerSegments[player] = {
		currentIndex = 0,
		segments = {},
	}

	-- Create initial segments
	updateTrackForPlayer(player, 0)

	-- Move character to start
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(0, 3, 5)
		end
	end
end)

EndRunEvent.OnServerEvent:Connect(function(player)
	-- Clean up segments
	local data = playerSegments[player]
	if data then
		for _, seg in pairs(data.segments) do
			seg:Destroy()
		end
	end
	playerSegments[player] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	local data = playerSegments[player]
	if data then
		for _, seg in pairs(data.segments) do
			seg:Destroy()
		end
	end
	playerSegments[player] = nil
end)

--------------------------------------------------------------------
-- Heartbeat: move characters and extend track
--------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	for player, data in pairs(playerSegments) do
		local character = player.Character
		if not character then continue end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		-- Move character forward at current speed
		-- Speed is managed by GameManager; we read from a session-like approach
		-- For simplicity we use a default speed; the client also drives visuals
		local speed = Config.BASE_SPEED
		root.CFrame = root.CFrame + Vector3.new(0, 0, speed * dt)

		-- Extend track
		updateTrackForPlayer(player, root.Position.Z)
	end
end)

print("[NEON SLICE] TrackSystem loaded ✓")
