--[[
	MusicController.client.lua
	Manages background music and sound effects.
	Plays lo-fi / synthwave tracks and speeds them up during raids.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer

--------------------------------------------------------------------
-- Sound setup
--------------------------------------------------------------------

-- Background music (placeholder asset IDs – replace with real ones)
local bgMusic = Instance.new("Sound")
bgMusic.Name = "BackgroundMusic"
bgMusic.SoundId = "rbxassetid://0" -- Replace with synthwave track
bgMusic.Volume = 0.4
bgMusic.Looped = true
bgMusic.PlaybackSpeed = 1
bgMusic.Parent = SoundService

-- Slice sound effect
local sliceSound = Instance.new("Sound")
sliceSound.Name = "SliceSound"
sliceSound.SoundId = "rbxassetid://0" -- Replace with satisfying slice SFX
sliceSound.Volume = 0.6
sliceSound.Looped = false
sliceSound.Parent = SoundService

-- Combo sound (pitch increases with combo)
local comboSound = Instance.new("Sound")
comboSound.Name = "ComboSound"
comboSound.SoundId = "rbxassetid://0" -- Replace with ascending tone SFX
comboSound.Volume = 0.5
comboSound.Looped = false
comboSound.Parent = SoundService

-- Miss / hit sound
local missSound = Instance.new("Sound")
missSound.Name = "MissSound"
missSound.SoundId = "rbxassetid://0" -- Replace with impact SFX
missSound.Volume = 0.5
missSound.Looped = false
missSound.Parent = SoundService

-- Menu music
local menuMusic = Instance.new("Sound")
menuMusic.Name = "MenuMusic"
menuMusic.SoundId = "rbxassetid://0" -- Replace with chill lo-fi track
menuMusic.Volume = 0.3
menuMusic.Looped = true
menuMusic.Parent = SoundService

--------------------------------------------------------------------
-- Music control
--------------------------------------------------------------------
local isRunning = false

local function playMenuMusic()
	bgMusic:Stop()
	if not menuMusic.IsPlaying then
		menuMusic:Play()
	end
end

local function playGameMusic()
	menuMusic:Stop()
	bgMusic.PlaybackSpeed = 1
	bgMusic:Play()
end

local function stopAllMusic()
	bgMusic:Stop()
	menuMusic:Stop()
end

--------------------------------------------------------------------
-- Speed up music during high combos / raids
--------------------------------------------------------------------
local function setMusicIntensity(combo)
	if not isRunning then return end
	local maxCombo = Config.MAX_COMBO_MULTIPLIER * Config.COMBO_MULTIPLIER_STEP
	local t = math.clamp(combo / maxCombo, 0, 1)
	local targetSpeed = 1 + t * 0.3 -- Up to 1.3x speed

	local tween = TweenService:Create(bgMusic, TweenInfo.new(0.5), {
		PlaybackSpeed = targetSpeed,
	})
	tween:Play()
end

--------------------------------------------------------------------
-- Sound effects
--------------------------------------------------------------------
local function playSliceSound(combo)
	sliceSound:Play()
	-- Pitch combo sound based on combo count
	comboSound.PlaybackSpeed = 1 + math.clamp((combo or 0) / 40, 0, 0.5)
	comboSound:Play()
end

local function playMissSound()
	missSound:Play()
end

--------------------------------------------------------------------
-- Events
--------------------------------------------------------------------
local SliceResultEvent = ReplicatedStorage:WaitForChild("SliceResult")
SliceResultEvent.OnClientEvent:Connect(function(result)
	if result.Success then
		playSliceSound(result.Combo)
		setMusicIntensity(result.Combo)
	end
end)

local RunStateEvent = ReplicatedStorage:WaitForChild("RunStateChanged")
RunStateEvent.Event:Connect(function(running)
	isRunning = running
	if running then
		playGameMusic()
	else
		playMenuMusic()
	end
end)

local RunEndedEvent = ReplicatedStorage:WaitForChild("RunEnded")
RunEndedEvent.OnClientEvent:Connect(function()
	isRunning = false
	playMenuMusic()
end)

-- Start with menu music
playMenuMusic()

print("[NEON SLICE] MusicController loaded ✓")
