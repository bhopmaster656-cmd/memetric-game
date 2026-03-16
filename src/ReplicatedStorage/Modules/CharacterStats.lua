-- Modules/CharacterStats.lua
-- Shared utility functions for reading/writing character stat Values

local CharacterStats = {}

-- Default stat table for a brand-new player
function CharacterStats.DefaultStats()
    return {
        Hunger      = 100,
        Thirst      = 100,
        Energy      = 100,
        Health      = 100,
        Temperature = 50,
        Reputation  = 0,
    }
end

-- Clamp a value between min and max
function CharacterStats.Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Apply decay to a stat, returns new clamped value
function CharacterStats.Decay(current, rate, dt)
    return CharacterStats.Clamp(current - rate * dt, 0, 100)
end

-- Apply recovery to a stat, returns new clamped value
function CharacterStats.Recover(current, rate, dt)
    return CharacterStats.Clamp(current + rate * dt, 0, 100)
end

-- Create NumberValue children for a player character
function CharacterStats.CreateStatValues(parent, stats)
    stats = stats or CharacterStats.DefaultStats()
    local names = { "Hunger", "Thirst", "Energy", "Health", "Temperature" }
    for _, name in ipairs(names) do
        local existing = parent:FindFirstChild(name)
        if not existing then
            local v = Instance.new("NumberValue")
            v.Name = name
            v.Value = stats[name] or 100
            v.Parent = parent
        else
            existing.Value = stats[name] or existing.Value
        end
    end
end

-- Read all stats from a character/humanoid
function CharacterStats.ReadStats(parent)
    local result = {}
    local names = { "Hunger", "Thirst", "Energy", "Health", "Temperature" }
    for _, name in ipairs(names) do
        local v = parent:FindFirstChild(name)
        result[name] = v and v.Value or 100
    end
    return result
end

return CharacterStats
