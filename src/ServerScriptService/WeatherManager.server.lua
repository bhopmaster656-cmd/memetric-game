-- ServerScriptService/WeatherManager.server.lua
-- Controls day/night cycle, seasons, and weather.
-- Broadcasts changes to all clients via RemoteEvents.

local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local WeatherModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WeatherModule"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateWeather   = RemoteEvents:WaitForChild("UpdateWeather")
local UpdateSeason    = RemoteEvents:WaitForChild("UpdateSeason")

-- ─── State ─────────────────────────────────────────────────────────────────
local totalElapsed   = 0   -- total real seconds since server start
local currentSeason  = "Spring"
local currentWeather = "Clear"
local weatherTimer   = 0
local weatherChangeInterval = 300  -- change weather every 5 real minutes

-- Day/night: 1 Roblox day = 10 real minutes (600s)
local DAY_LENGTH = 600
local clockStart = 8  -- start at 8:00 AM

-- ─── Apply Lighting Params ─────────────────────────────────────────────────
local function applyLighting(params)
    Lighting.FogEnd    = params.FogEnd
    Lighting.Brightness= params.Brightness
end

-- ─── Broadcast Season ─────────────────────────────────────────────────────
local function broadcastSeason()
    UpdateSeason:FireAllClients(currentSeason)
end

-- ─── Broadcast Weather ────────────────────────────────────────────────────
local function broadcastWeather()
    local outdoorTemp = WeatherModule.OutdoorTemp(currentSeason, currentWeather)
    UpdateWeather:FireAllClients(currentWeather, outdoorTemp)
    local params = WeatherModule.LightingParams(currentWeather, currentSeason)
    applyLighting(params)
end

-- ─── Change Weather ───────────────────────────────────────────────────────
local function changeWeather()
    local newWeather = WeatherModule.PickWeather(currentSeason)
    if newWeather ~= currentWeather then
        currentWeather = newWeather
        broadcastWeather()
    end
end

-- ─── Main Loop ────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
    totalElapsed  = totalElapsed + dt
    weatherTimer  = weatherTimer + dt

    -- Update season
    local newSeason = WeatherModule.GetSeason(totalElapsed)
    if newSeason ~= currentSeason then
        currentSeason = newSeason
        -- Pick appropriate weather for new season
        currentWeather = WeatherModule.PickWeather(currentSeason)
        broadcastSeason()
        broadcastWeather()
        print("[Weather] Season changed to: " .. currentSeason)
    end

    -- Day/night cycle: map elapsed time to clock time
    local dayProgress = (totalElapsed % DAY_LENGTH) / DAY_LENGTH  -- 0 to 1
    local clockTime   = clockStart + dayProgress * 24
    if clockTime >= 24 then clockTime = clockTime - 24 end
    Lighting.ClockTime = clockTime

    -- Change weather periodically
    if weatherTimer >= weatherChangeInterval then
        weatherTimer = 0
        changeWeather()
    end
end)

-- Initial broadcast
task.delay(2, function()
    broadcastSeason()
    broadcastWeather()
end)

print("[WeatherManager] Ready — Season: " .. currentSeason .. ", Weather: " .. currentWeather)
