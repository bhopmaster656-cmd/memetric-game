--[[
	TrailEffects.client.lua
	Manages katana trail effects and movement particles.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local KatanaData = require(ReplicatedStorage:WaitForChild("KatanaData"))

local player = Players.LocalPlayer

--------------------------------------------------------------------
-- State
--------------------------------------------------------------------
local isRunning = false
local currentTrail = nil
local currentParticles = nil
local equippedKatana = Config.DEFAULT_KATANA

--------------------------------------------------------------------
-- Create trail attachment on character
--------------------------------------------------------------------
local function setupTrail(character)
	if not character then return end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end

	-- Remove old trail
	if currentTrail then
		currentTrail:Destroy()
		currentTrail = nil
	end
	if currentParticles then
		currentParticles:Destroy()
		currentParticles = nil
	end

	local katana = KatanaData.GetKatana(equippedKatana) or KatanaData.GetKatana("NeonBlade")
	local trailColor = katana.TrailColor

	-- Create attachments for the trail
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 2, 0)
	attachment0.Name = "TrailAttach0"
	attachment0.Parent = root

	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, -1, 0)
	attachment1.Name = "TrailAttach1"
	attachment1.Parent = root

	-- Trail
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(trailColor, trailColor)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = Config.TRAIL_LIFETIME
	trail.MinLength = Config.TRAIL_MIN_LENGTH
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = root

	currentTrail = trail

	-- Speed particles
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Color = ColorSequence.new(trailColor)
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	particleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particleEmitter.Lifetime = NumberRange.new(0.2, 0.5)
	particleEmitter.Speed = NumberRange.new(2, 8)
	particleEmitter.SpreadAngle = Vector2.new(30, 30)
	particleEmitter.Rate = 0
	particleEmitter.LightEmission = 1
	particleEmitter.Enabled = false
	particleEmitter.Parent = root

	currentParticles = particleEmitter
end

--------------------------------------------------------------------
-- Enable/disable trail based on run state
--------------------------------------------------------------------
local function setTrailEnabled(enabled)
	if currentTrail then
		currentTrail.Enabled = enabled
	end
	if currentParticles then
		if enabled then
			currentParticles.Rate = 30
		else
			currentParticles.Rate = 0
		end
	end
end

--------------------------------------------------------------------
-- Character lifecycle
--------------------------------------------------------------------
player.CharacterAdded:Connect(function(character)
	setupTrail(character)
end)

if player.Character then
	setupTrail(player.Character)
end

--------------------------------------------------------------------
-- Run state
--------------------------------------------------------------------
local RunStateEvent = ReplicatedStorage:WaitForChild("RunStateChanged")
RunStateEvent.Event:Connect(function(running)
	isRunning = running
	setTrailEnabled(running)
end)

local RunEndedEvent = ReplicatedStorage:WaitForChild("RunEnded")
RunEndedEvent.OnClientEvent:Connect(function()
	isRunning = false
	setTrailEnabled(false)
end)

--------------------------------------------------------------------
-- Katana change
--------------------------------------------------------------------
local PlayerDataEvent = ReplicatedStorage:WaitForChild("PlayerData")
PlayerDataEvent.OnClientEvent:Connect(function(data)
	if data.EquippedKatana then
		equippedKatana = data.EquippedKatana
		setupTrail(player.Character)
		if isRunning then
			setTrailEnabled(true)
		end
	end
end)

print("[NEON SLICE] TrailEffects loaded ✓")
