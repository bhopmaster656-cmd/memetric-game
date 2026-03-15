--[[
	CameraController.client.lua
	Manages the third-person chase camera during gameplay.
	Smooth follow with slight sway for dynamic feel.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

--------------------------------------------------------------------
-- State
--------------------------------------------------------------------
local isRunning = false
local cameraOffset = Config.CAMERA_OFFSET
local targetFOV = Config.CAMERA_FOV
local currentFOV = Config.CAMERA_FOV
local swayTime = 0
local shakeAmount = 0
local shakeDecay = 5

--------------------------------------------------------------------
-- Camera update
--------------------------------------------------------------------
local function updateCamera(dt)
	if not isRunning then return end

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	camera.CameraType = Enum.CameraType.Scriptable

	-- Smooth follow position
	local targetPos = root.Position + cameraOffset
	local lookAt = root.Position + Vector3.new(0, 2, 10)

	-- Gentle sway
	swayTime = swayTime + dt
	local swayX = math.sin(swayTime * 0.8) * 0.5
	local swayY = math.cos(swayTime * 0.6) * 0.3
	targetPos = targetPos + Vector3.new(swayX, swayY, 0)

	-- Camera shake (from impacts)
	if shakeAmount > 0.01 then
		local shakeX = (math.random() - 0.5) * shakeAmount
		local shakeY = (math.random() - 0.5) * shakeAmount
		targetPos = targetPos + Vector3.new(shakeX, shakeY, 0)
		shakeAmount = shakeAmount * math.exp(-shakeDecay * dt)
	end

	-- Lerp camera
	local currentCF = camera.CFrame
	local targetCF = CFrame.lookAt(targetPos, lookAt)
	camera.CFrame = currentCF:Lerp(targetCF, math.clamp(dt * 8, 0, 1))

	-- FOV (increases with speed for a rush effect)
	currentFOV = currentFOV + (targetFOV - currentFOV) * math.clamp(dt * 5, 0, 1)
	camera.FieldOfView = currentFOV
end

RunService.RenderStepped:Connect(updateCamera)

--------------------------------------------------------------------
-- Speed changes affect FOV
--------------------------------------------------------------------
local UpdateSpeedEvent = ReplicatedStorage:WaitForChild("UpdateSpeed")
UpdateSpeedEvent.OnClientEvent:Connect(function(speed)
	-- Map speed to FOV: BASE_SPEED -> 75, MAX_SPEED -> 95
	local t = (speed - Config.BASE_SPEED) / (Config.MAX_SPEED - Config.BASE_SPEED)
	targetFOV = 75 + t * 20
end)

--------------------------------------------------------------------
-- Camera shake API
--------------------------------------------------------------------
local function triggerShake(amount)
	shakeAmount = math.min(shakeAmount + amount, 3)
end

-- Shake on slice result
local SliceResultEvent = ReplicatedStorage:WaitForChild("SliceResult")
SliceResultEvent.OnClientEvent:Connect(function(result)
	if result.Success then
		triggerShake(0.3)
	end
end)

--------------------------------------------------------------------
-- Run state
--------------------------------------------------------------------
local RunStateEvent = ReplicatedStorage:WaitForChild("RunStateChanged")
RunStateEvent.Event:Connect(function(running)
	isRunning = running
	if not running then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = Config.CAMERA_FOV
	end
end)

local RunEndedEvent = ReplicatedStorage:WaitForChild("RunEnded")
RunEndedEvent.OnClientEvent:Connect(function()
	isRunning = false
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = Config.CAMERA_FOV
end)

print("[NEON SLICE] CameraController loaded ✓")
