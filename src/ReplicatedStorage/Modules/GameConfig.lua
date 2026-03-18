--[[
    GameConfig.lua
    Central configuration for Memetric Fishing.
    Tune economy, multipliers, timers and DevProduct / GamePass IDs here.
--]]

local GameConfig = {}

-- ─── Economy ────────────────────────────────────────────────────────────────
GameConfig.BASE_CATCH_COINS   = 10   -- coins awarded for a Normal catch
GameConfig.GOLDEN_MULTIPLIER  = 3    -- Golden  catch coin multiplier
GameConfig.DIAMOND_MULTIPLIER = 10   -- Diamond catch coin multiplier

-- ─── Fishing ────────────────────────────────────────────────────────────────
GameConfig.CAST_WAIT_MIN    = 3      -- seconds before a bite (min)
GameConfig.CAST_WAIT_MAX    = 8      -- seconds before a bite (max)
GameConfig.REEL_WINDOW      = 3      -- seconds to reel before the fish escapes

-- ─── Quests ─────────────────────────────────────────────────────────────────
GameConfig.DAILY_RESET_HOURS = 24    -- hours until daily quests reset

-- ─── Rebirth ────────────────────────────────────────────────────────────────
GameConfig.REBIRTH_COST         = 1000  -- coins required per rebirth
GameConfig.REBIRTH_LUCK_BONUS   = 0.05  -- +5% rarity luck per rebirth level
GameConfig.REBIRTH_COIN_BONUS   = 0.10  -- +10% coin multiplier per rebirth level
GameConfig.MAX_REBIRTHS         = 50

-- ─── Spin Wheel ─────────────────────────────────────────────────────────────
GameConfig.SPIN_COOLDOWN_HOURS = 24  -- one free spin per day

-- ─── VIP Gamepass ───────────────────────────────────────────────────────────
-- Set real IDs before publishing; 0 = placeholder (disabled)
GameConfig.VIP_GAMEPASS_ID        = 0
GameConfig.VIP_LUCK_BONUS         = 0.15  -- +15% rarity luck
GameConfig.VIP_COIN_BONUS         = 0.25  -- +25% coin multiplier
GameConfig.VIP_SPIN_EXTRA_TICKETS = 1     -- extra daily spin

-- ─── Developer Products (one-time purchases) ────────────────────────────────
GameConfig.DEVPRODUCT_COINS_SMALL  = 0   -- 500 coins
GameConfig.DEVPRODUCT_COINS_MEDIUM = 0   -- 2500 coins
GameConfig.DEVPRODUCT_COINS_LARGE  = 0   -- 10000 coins

-- ─── Coin packages (product value maps) ─────────────────────────────────────
GameConfig.COIN_PACKAGES = {
    [GameConfig.DEVPRODUCT_COINS_SMALL]  = 500,
    [GameConfig.DEVPRODUCT_COINS_MEDIUM] = 2500,
    [GameConfig.DEVPRODUCT_COINS_LARGE]  = 10000,
}

-- ─── DataStore key ──────────────────────────────────────────────────────────
GameConfig.DATA_STORE_NAME    = "MemetricFishingV1"
GameConfig.DATA_STORE_VERSION = 1

return GameConfig
