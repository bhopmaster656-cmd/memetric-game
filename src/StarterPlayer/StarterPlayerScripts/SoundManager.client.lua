-- StarterPlayer/StarterPlayerScripts/SoundManager.client.lua
-- Manages ambient sounds, footstep sounds, and weather audio.

local Players          = game:GetService("Players")
local SoundService     = game:GetService("SoundService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")

-- ─── Create ambient sounds ────────────────────────────────────────────────────
local function makeSound(id, parent, volume, looped)
    local sound = Instance.new("Sound")
    sound.SoundId   = id
    sound.Volume    = volume or 0.5
    sound.Looped    = looped ~= false
    sound.Parent    = parent
    return sound
end

-- Use default Roblox ambient sounds (free to use, no asset IDs needed)
local ambientFolder = Instance.new("Folder")
ambientFolder.Name  = "EvergreenSounds"
ambientFolder.Parent= SoundService

-- Ambient birdsong (rbxasset or AssetId; using placeholder IDs)
local ambientBirds = makeSound("rbxassetid://1839577617", ambientFolder, 0.15, true)
ambientBirds.Name  = "Birdsong"

-- Wind sound
local windSound = makeSound("rbxassetid://785275977", ambientFolder, 0.1, true)
windSound.Name   = "Wind"

-- Rain sound (starts disabled)
local rainSound = makeSound("rbxassetid://1846830406", ambientFolder, 0, true)
rainSound.Name  = "Rain"
rainSound:Play()  -- Start looping silently

-- ─── Weather Sound Handling ───────────────────────────────────────────────────
RemoteEvents:WaitForChild("UpdateWeather").OnClientEvent:Connect(function(weather)
    if weather == "Rainy" or weather == "Snowy" then
        -- Fade in rain
        local tween = game:GetService("TweenService"):Create(
            rainSound,
            TweenInfo.new(3, Enum.EasingStyle.Sine),
            { Volume = 0.35 }
        )
        tween:Play()
        -- Fade out birds
        local birdTween = game:GetService("TweenService"):Create(
            ambientBirds,
            TweenInfo.new(3, Enum.EasingStyle.Sine),
            { Volume = 0 }
        )
        birdTween:Play()
    elseif weather == "Clear" then
        local tween = game:GetService("TweenService"):Create(
            rainSound,
            TweenInfo.new(3, Enum.EasingStyle.Sine),
            { Volume = 0 }
        )
        tween:Play()
        local birdTween = game:GetService("TweenService"):Create(
            ambientBirds,
            TweenInfo.new(3, Enum.EasingStyle.Sine),
            { Volume = 0.15 }
        )
        birdTween:Play()
    elseif weather == "Windy" then
        local tween = game:GetService("TweenService"):Create(
            windSound,
            TweenInfo.new(2, Enum.EasingStyle.Sine),
            { Volume = 0.4 }
        )
        tween:Play()
    end
end)

-- ─── Start ambient sounds ─────────────────────────────────────────────────────
task.delay(2, function()
    ambientBirds:Play()
    windSound:Play()
end)

-- ─── Footstep sounds ─────────────────────────────────────────────────────────
-- Simple footstep system based on terrain material
local footstepTimer = 0
local FOOTSTEP_INTERVAL = 0.45  -- seconds between steps at walk speed

RunService.RenderStepped:Connect(function(dt)
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.MoveDirection.Magnitude < 0.1 then return end

    footstepTimer = footstepTimer + dt
    local interval = humanoid.WalkSpeed > 20 and 0.28 or FOOTSTEP_INTERVAL

    if footstepTimer >= interval then
        footstepTimer = 0
        -- Play a simple click sound for steps (using built-in)
        local stepSound = Instance.new("Sound")
        stepSound.SoundId = "rbxassetid://9118192232"  -- light footstep
        stepSound.Volume  = 0.2
        stepSound.Parent  = char:FindFirstChild("HumanoidRootPart") or workspace
        stepSound:Play()
        game:GetService("Debris"):AddItem(stepSound, 1)
    end
end)

print("[SoundManager] Ready")
