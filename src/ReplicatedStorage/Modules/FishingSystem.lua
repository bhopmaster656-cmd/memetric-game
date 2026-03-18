--[[
    FishingSystem.lua
    Shared fishing helpers used by both server and client.
--]]

local GameConfig  = require(script.Parent.GameConfig)
local RaritySystem = require(script.Parent.RaritySystem)

local FishingSystem = {}

--[[
    GetBiteDelay()
    Returns a random number of seconds until the next bite.
--]]
function FishingSystem.GetBiteDelay()
    return GameConfig.CAST_WAIT_MIN
        + math.random() * (GameConfig.CAST_WAIT_MAX - GameConfig.CAST_WAIT_MIN)
end

--[[
    CalculateCoinReward(brainrot, rarity, coinMultiplier)
    Returns the coin reward for a single catch.
    coinMultiplier combines rebirth + VIP bonuses (default 1).
--]]
function FishingSystem.CalculateCoinReward(brainrot, rarity, coinMultiplier)
    coinMultiplier = coinMultiplier or 1
    local base = brainrot.CoinValue * rarity.CoinMultiplier * coinMultiplier
    return math.floor(base + 0.5)  -- round to nearest integer
end

--[[
    SimulateCatch(luckMultiplier, coinMultiplier)
    Returns { brainrot, rarity, coins } for a successful catch.
    Convenience wrapper used by FishingHandler.
--]]
function FishingSystem.SimulateCatch(luckMultiplier, coinMultiplier)
    local catch = RaritySystem.BuildCatch(luckMultiplier)
    local coins = FishingSystem.CalculateCoinReward(
        catch.brainrot, catch.rarity, coinMultiplier
    )
    return {
        brainrot = catch.brainrot,
        rarity   = catch.rarity,
        coins    = coins,
    }
end

return FishingSystem
