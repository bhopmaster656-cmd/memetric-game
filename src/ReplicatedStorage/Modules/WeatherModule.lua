-- Modules/WeatherModule.lua
-- Shared weather/season helpers

local GameConfig = require(script.Parent.Parent.GameConfig)
local WeatherModule = {}

-- Weighted random pick from a probability table
-- probTable: { TypeName = probability, ... }  (must sum to ~1)
function WeatherModule.PickWeather(season)
    local probs = GameConfig.WeatherChangeProbability[season]
    if not probs then return "Clear" end
    local r = math.random()
    local cumulative = 0
    for weatherType, prob in pairs(probs) do
        cumulative = cumulative + prob
        if r <= cumulative then
            return weatherType
        end
    end
    return "Clear"
end

-- Returns current season index (1-4) based on elapsed game time
-- totalSeconds: total seconds elapsed since server start
function WeatherModule.GetSeasonIndex(totalSeconds)
    local seasonDuration = GameConfig.SeasonDurationSeconds
    local cycle = math.floor(totalSeconds / seasonDuration)
    return (cycle % 4) + 1
end

-- Returns season name
function WeatherModule.GetSeason(totalSeconds)
    return GameConfig.Seasons[WeatherModule.GetSeasonIndex(totalSeconds)]
end

-- Returns the outdoor temperature modifier for a given season + weather
function WeatherModule.OutdoorTemp(season, weather)
    local base = GameConfig.TemperatureNeutral  -- 50
    if season == "Winter" then
        base = GameConfig.OutdoorTempCold       -- 20
        if weather == "Snowy" then base = base - 10 end
    elseif season == "Summer" then
        base = GameConfig.OutdoorTempHot        -- 75
        if weather == "Clear" then base = base + 5 end
    elseif season == "Spring" then
        base = 45
        if weather == "Rainy" then base = base - 5 end
    elseif season == "Autumn" then
        base = 40
        if weather == "Rainy" then base = base - 5 end
    end
    return base
end

-- Returns Roblox Lighting atmosphere / color adjustments per weather
function WeatherModule.LightingParams(weather, season)
    local params = {
        FogEnd    = 2000,
        Brightness = 2.0,
        ClockOffset = 0,
    }
    if weather == "Foggy" then
        params.FogEnd = 300
        params.Brightness = 1.2
    elseif weather == "Rainy" then
        params.FogEnd = 800
        params.Brightness = 1.0
    elseif weather == "Snowy" then
        params.FogEnd = 500
        params.Brightness = 1.5
    elseif weather == "Cloudy" then
        params.FogEnd = 1500
        params.Brightness = 1.4
    end
    if season == "Winter" then
        params.Brightness = params.Brightness * 0.8
    end
    return params
end

return WeatherModule
