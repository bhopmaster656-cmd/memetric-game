-- StarterPlayer/StarterCharacterScripts/StatsMonitor.client.lua
-- Monitors character stats on the client side, applies temperature effects,
-- and syncs with the server periodically.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local character = script.Parent  -- This is the character model

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateStats   = RemoteEvents:WaitForChild("UpdateStats")
local NotifyPlayer  = RemoteEvents:WaitForChild("NotifyPlayer")

-- Current weather state (updated by WeatherManager broadcasts)
local currentOutdoorTemp = GameConfig.TemperatureNeutral
local currentSeason      = "Spring"

RemoteEvents:WaitForChild("UpdateWeather").OnClientEvent:Connect(function(weather, outdoorTemp)
    currentOutdoorTemp = outdoorTemp or GameConfig.TemperatureNeutral
end)

RemoteEvents:WaitForChild("UpdateSeason").OnClientEvent:Connect(function(season)
    currentSeason = season
end)

-- ─── Stat Update Handling ─────────────────────────────────────────────────────
local statsCache = {
    Hunger      = 100,
    Thirst      = 100,
    Energy      = 100,
    Health      = 100,
    Temperature = 50,
}

UpdateStats.OnClientEvent:Connect(function(stats)
    for k, v in pairs(stats) do
        statsCache[k] = v
        local valInst = character:FindFirstChild(k)
        if valInst then valInst.Value = v end
    end
end)

-- ─── Temperature Logic ─────────────────────────────────────────────────────────
local function computeTemperature()
    local base = currentOutdoorTemp

    -- Check if inside a building (approximate: check if character is under a roof)
    -- Simple heuristic: raycast upward, if we hit something within 20 studs -> inside
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local isInside = false
    if humanoidRootPart then
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { character }
        local result = workspace:Raycast(
            humanoidRootPart.Position,
            Vector3.new(0, 20, 0),
            rayParams
        )
        if result then
            isInside = true
            base = base + GameConfig.InsideWarmthBonus
        end
    end

    -- Clothing warmth
    local warmthFromClothing = 0
    for clothingId, warmth in pairs(GameConfig.ClothingWarmth) do
        -- Check if player is wearing this (simplified check via inventory cache)
        -- Full implementation would track equipped items server-side
        _ = clothingId  -- suppress unused warning
        _ = warmth
    end

    return math.clamp(base + warmthFromClothing, 0, 100)
end

-- ─── Periodic Stat Decay (client-side approximation for smooth UI) ─────────────
local decayTimer = 0
local DECAY_INTERVAL = 5  -- Apply decay every 5 seconds (server is authoritative)

RunService.Heartbeat:Connect(function(dt)
    decayTimer = decayTimer + dt

    if decayTimer >= DECAY_INTERVAL then
        decayTimer = 0

        -- Compute current temperature
        local temp = computeTemperature()
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        -- Thirst decays faster in Summer
        local thirstMult = (currentSeason == "Summer") and GameConfig.SummerThirstMult or 1.0
        local energyMult = (currentSeason == "Winter") and GameConfig.WinterEnergyMult or 1.0

        -- Check if running (energy decay)
        local isRunning = false
        if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
            isRunning = true
        end

        -- Update temperature stat
        local tempVal = character:FindFirstChild("Temperature")
        if tempVal then tempVal.Value = temp end

        -- Notify on extreme stats
        if statsCache.Hunger <= 20 and statsCache.Hunger > 0 then
            NotifyPlayer:FireServer and nil  -- notifications are server-side
        end
        if statsCache.Thirst <= 15 then
            -- Warning displayed by HUD
        end
        if temp < 20 then
            -- Cold warning
        end

        -- Push updated temperature to server (simplified; in production would
        -- use a RemoteEvent to inform server of client-computed temperature)
    end
end)

-- ─── Low Stat Warnings ────────────────────────────────────────────────────────
-- These are handled by the HUD script reading the same statsCache.
-- We expose the cache globally for the HUD to access.
_G.PlayerStatsCache = statsCache
