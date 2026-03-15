--[[
	SliceController.client.lua
	Handles mouse/touch input for slicing neon blocks.
	Renders blocks locally, detects swipe gestures, and sends slice
	requests to the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

--------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------
local SpawnBlockEvent  = ReplicatedStorage:WaitForChild("SpawnBlock")
local SliceRequestEvent = ReplicatedStorage:WaitForChild("SliceRequest")
local SliceResultEvent  = ReplicatedStorage:WaitForChild("SliceResult")
local StartRunEvent     = ReplicatedStorage:WaitForChild("StartRun")
local EndRunEvent       = ReplicatedStorage:WaitForChild("EndRun")

--------------------------------------------------------------------
-- State
--------------------------------------------------------------------
local isRunning = false
local activeBlocks = {} -- [blockId] = { Part, Data }
local swipeStart = nil  -- Vector2
local swipeStartTime = 0

-- Block container in Workspace
local blockFolder = Instance.new("Folder")
blockFolder.Name = "NeonBlocks"
blockFolder.Parent = Workspace

--------------------------------------------------------------------
-- Create a visible block from server data
--------------------------------------------------------------------
local function createBlockVisual(data)
	local part = Instance.new("Part")
	part.Size = data.Size
	part.Color = Color3.new(data.Color[1], data.Color[2], data.Color[3])
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.Name = "Block_" .. tostring(data.Id)
	part.CastShadow = false

	-- Position block ahead of the player in the correct lane
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local forwardPos = root.Position + Vector3.new(
				data.LaneOffset,
				math.random(2, 6),
				data.SpawnDistance
			)
			part.Position = forwardPos
		end
	end

	-- Slice line indicator (thin neon line across the block)
	if data.SliceDirection ~= "None" then
		local line = Instance.new("Part")
		line.Size = Vector3.new(data.Size.X + 1, 0.15, 0.15)
		line.Color = Color3.fromRGB(255, 255, 255)
		line.Material = Enum.Material.Neon
		line.Transparency = 0.3
		line.Anchored = true
		line.CanCollide = false
		line.CastShadow = false
		line.Name = "SliceLine"
		line.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(data.SliceAngle))
		line.Parent = part
	end

	-- Point light for glow
	local pointLight = Instance.new("PointLight")
	pointLight.Color = part.Color
	pointLight.Brightness = 2
	pointLight.Range = 12
	pointLight.Parent = part

	part.Parent = blockFolder

	return part
end

--------------------------------------------------------------------
-- Block lifecycle
--------------------------------------------------------------------
SpawnBlockEvent.OnClientEvent:Connect(function(data)
	if not isRunning then return end

	local part = createBlockVisual(data)
	activeBlocks[data.Id] = {
		Part = part,
		Data = data,
		SpawnTime = tick(),
	}

	-- Tween block towards the player
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local targetPos = root.Position + Vector3.new(data.LaneOffset, math.random(2, 6), -5)
	local distance = (part.Position - targetPos).Magnitude
	local travelTime = distance / Config.BASE_SPEED

	local tween = TweenService:Create(part, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
		Position = targetPos,
	})
	tween:Play()

	-- Auto-remove if not sliced after passing the player
	task.delay(travelTime + 0.5, function()
		if activeBlocks[data.Id] then
			-- Block was not sliced — player missed or it was a hazard
			local block = activeBlocks[data.Id]
			if block.Part and block.Part.Parent then
				-- Fade out
				local fadeOut = TweenService:Create(block.Part, TweenInfo.new(0.3), {
					Transparency = 1,
				})
				fadeOut:Play()
				fadeOut.Completed:Connect(function()
					if block.Part then
						block.Part:Destroy()
					end
				end)
			end
			activeBlocks[data.Id] = nil
		end
	end)
end)

--------------------------------------------------------------------
-- Slice effect (split animation)
--------------------------------------------------------------------
local function playSliceEffect(part, color)
	-- Create two halves that fly apart
	for i = 1, 2 do
		local half = Instance.new("Part")
		half.Size = Vector3.new(part.Size.X / 2, part.Size.Y, part.Size.Z)
		half.Color = color or part.Color
		half.Material = Enum.Material.Neon
		half.Anchored = false
		half.CanCollide = false
		half.CastShadow = false
		half.Position = part.Position + Vector3.new((i == 1 and -1 or 1) * part.Size.X / 4, 0, 0)
		half.Parent = blockFolder

		-- Add velocity to fly apart
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(
			(i == 1 and -1 or 1) * math.random(15, 30),
			math.random(5, 15),
			math.random(-5, 5)
		)
		bodyVelocity.MaxForce = Vector3.new(1e4, 1e4, 1e4)
		bodyVelocity.Parent = half

		-- Point light flash
		local flash = Instance.new("PointLight")
		flash.Color = color or part.Color
		flash.Brightness = 5
		flash.Range = 20
		flash.Parent = half

		-- Fade and destroy
		local tween = TweenService:Create(half, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = Vector3.new(0.1, 0.1, 0.1),
		})
		tween:Play()
		tween.Completed:Connect(function()
			half:Destroy()
		end)
	end

	-- Particle burst
	local emitter = Instance.new("Part")
	emitter.Size = Vector3.new(0.5, 0.5, 0.5)
	emitter.Transparency = 1
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.Position = part.Position
	emitter.Parent = blockFolder

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(color or part.Color)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.3, 0.6)
	particles.Speed = NumberRange.new(10, 25)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rate = 0
	particles.Parent = emitter
	particles:Emit(20)

	task.delay(1, function()
		emitter:Destroy()
	end)
end

--------------------------------------------------------------------
-- Swipe detection
--------------------------------------------------------------------
local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if not isRunning then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		swipeStart = Vector2.new(input.Position.X, input.Position.Y)
		swipeStartTime = tick()
	end
end

local function onInputEnded(input, gameProcessed)
	if gameProcessed then return end
	if not isRunning then return end
	if not swipeStart then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		local swipeEnd = Vector2.new(input.Position.X, input.Position.Y)
		local swipeDelta = swipeEnd - swipeStart
		local swipeLength = swipeDelta.Magnitude
		local swipeDuration = tick() - swipeStartTime

		swipeStart = nil

		-- Minimum swipe threshold
		if swipeLength < 30 or swipeDuration > 1 then return end

		-- Calculate swipe angle
		local swipeAngle = math.deg(math.atan2(swipeDelta.Y, swipeDelta.X))

		-- Raycast from the center of the swipe to find blocks
		local midPoint = (swipeEnd + Vector2.new(input.Position.X, input.Position.Y)) / 2
		local ray = camera:ViewportPointToRay(swipeStart.X + swipeDelta.X / 2, swipeStart.Y + swipeDelta.Y / 2)

		-- Check collision with active blocks
		local closestBlock = nil
		local closestDist = math.huge

		for blockId, blockInfo in pairs(activeBlocks) do
			if blockInfo.Part and blockInfo.Part.Parent then
				local blockPos = blockInfo.Part.Position
				local screenPos, onScreen = camera:WorldToViewportPoint(blockPos)

				if onScreen then
					local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
					-- Check if swipe line passes near the block on screen
					local distToSwipe = distPointToLine(screenPoint, swipeStart, swipeEnd)

					if distToSwipe < 80 and screenPos.Z < closestDist then
						closestDist = screenPos.Z
						closestBlock = blockId
					end
				end
			end
		end

		if closestBlock then
			local blockInfo = activeBlocks[closestBlock]
			if blockInfo and blockInfo.Data.SliceDirection ~= "None" then
				-- Play slice effect
				playSliceEffect(blockInfo.Part, blockInfo.Part.Color)
				blockInfo.Part:Destroy()
				activeBlocks[closestBlock] = nil

				-- Send to server
				SliceRequestEvent:FireServer(closestBlock, swipeAngle)
			elseif blockInfo and blockInfo.Data.SliceDirection == "None" then
				-- Hit a hazard block! Flash red
				local originalColor = blockInfo.Part.Color
				blockInfo.Part.Color = Color3.fromRGB(255, 0, 0)
				task.delay(0.2, function()
					if blockInfo.Part and blockInfo.Part.Parent then
						blockInfo.Part.Color = originalColor
					end
				end)
			end
		end
	end
end

-- Helper: distance from point to line segment
function distPointToLine(point, lineStart, lineEnd)
	local lineVec = lineEnd - lineStart
	local pointVec = point - lineStart
	local lineLen = lineVec.Magnitude
	if lineLen < 0.001 then return (point - lineStart).Magnitude end

	local t = math.clamp(pointVec:Dot(lineVec) / (lineLen * lineLen), 0, 1)
	local projection = lineStart + lineVec * t
	return (point - projection).Magnitude
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

--------------------------------------------------------------------
-- Slice result feedback
--------------------------------------------------------------------
SliceResultEvent.OnClientEvent:Connect(function(result)
	if result.Success then
		-- Could play a sound here
		-- Feedback is handled by the HUD
	end
end)

--------------------------------------------------------------------
-- Run state management
--------------------------------------------------------------------
local function setRunning(state)
	isRunning = state
	if not state then
		-- Clear all blocks
		for id, blockInfo in pairs(activeBlocks) do
			if blockInfo.Part then
				blockInfo.Part:Destroy()
			end
		end
		activeBlocks = {}
	end
end

-- Listen for run state from other client scripts via a BindableEvent
local runStateEvent = Instance.new("BindableEvent")
runStateEvent.Name = "RunStateChanged"
runStateEvent.Parent = ReplicatedStorage

runStateEvent.Event:Connect(function(running)
	setRunning(running)
end)

-- Also listen for server RunEnded
local RunEndedEvent = ReplicatedStorage:WaitForChild("RunEnded")
RunEndedEvent.OnClientEvent:Connect(function()
	setRunning(false)
end)

print("[NEON SLICE] SliceController loaded ✓")
