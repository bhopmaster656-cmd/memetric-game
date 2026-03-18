--[[
    RaritySystem.lua
    Handles rarity rolling for caught brainrots.

    Usage (server):
        local RaritySystem = require(Modules.RaritySystem)
        local rarity = RaritySystem.Roll(luckMultiplier)
        local brainrot = RaritySystem.PickBrainrot()
--]]

local RarityConfig = require(script.Parent.RarityConfig)

local RaritySystem = {}

--[[
    Roll(luckMultiplier)
    Returns a rarity table from RarityConfig.RARITIES.
    luckMultiplier compresses the weight of rarer tiers towards Normal,
    effectively increasing the chance of rare outcomes.
        luckMultiplier = 1  → default weights
        luckMultiplier = 2  → rare weights doubled relative to Normal
--]]
function RaritySystem.Roll(luckMultiplier)
    luckMultiplier = luckMultiplier or 1

    -- Build adjusted weights: Normal stays fixed; rarer tiers scale up.
    local adjusted = {}
    local total    = 0
    for i, r in ipairs(RarityConfig.RARITIES) do
        local w
        if i == 1 then
            -- First entry is the "common" tier; keep it as-is
            w = r.Weight
        else
            w = r.Weight * luckMultiplier
        end
        adjusted[i] = w
        total = total + w
    end

    local roll = math.random() * total
    local cumulative = 0
    for i, r in ipairs(RarityConfig.RARITIES) do
        cumulative = cumulative + adjusted[i]
        if roll <= cumulative then
            return r
        end
    end
    -- Fallback (floating-point edge case)
    return RarityConfig.RARITIES[1]
end

--[[
    PickBrainrot()
    Returns a random brainrot template from RarityConfig.BRAINROTS.
    All brainrots have equal pick probability; rarity is determined separately.
--]]
function RaritySystem.PickBrainrot()
    local list = RarityConfig.BRAINROTS
    return list[math.random(1, #list)]
end

--[[
    BuildCatch(luckMultiplier)
    Convenience: returns { brainrot=..., rarity=... }.
--]]
function RaritySystem.BuildCatch(luckMultiplier)
    return {
        brainrot = RaritySystem.PickBrainrot(),
        rarity   = RaritySystem.Roll(luckMultiplier),
    }
end

return RaritySystem
