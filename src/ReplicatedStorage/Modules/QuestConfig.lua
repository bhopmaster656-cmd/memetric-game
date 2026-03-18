--[[
    QuestConfig.lua
    Defines all available quests.

    type values:
        "catch_total"   – catch N brainrots of any kind
        "catch_rarity"  – catch N brainrots of a specific rarity
        "catch_type"    – catch N of a specific brainrot id
        "earn_coins"    – earn N coins total (fishing only)

    resetType:
        "daily"     – resets every DAILY_RESET_HOURS
        "repeatable"– no reset; player can re-complete for the reward each time
--]]

local QuestConfig = {}

QuestConfig.QUESTS = {
    -- ── Daily quests ────────────────────────────────────────────────────────
    {
        Id          = "daily_catch_5",
        Name        = "Morning Haul",
        Description = "Catch 5 brainrots today.",
        Type        = "catch_total",
        Goal        = 5,
        ResetType   = "daily",
        Reward      = { Coins = 50 },
    },
    {
        Id          = "daily_catch_golden",
        Name        = "Gold Rush",
        Description = "Catch 2 Golden brainrots today.",
        Type        = "catch_rarity",
        RarityName  = "Golden",
        Goal        = 2,
        ResetType   = "daily",
        Reward      = { Coins = 150 },
    },
    {
        Id          = "daily_earn_200",
        Name        = "Coin Collector",
        Description = "Earn 200 coins from fishing today.",
        Type        = "earn_coins",
        Goal        = 200,
        ResetType   = "daily",
        Reward      = { Coins = 100 },
    },
    {
        Id          = "daily_catch_diamond",
        Name        = "Diamond Dreamer",
        Description = "Catch 1 Diamond brainrot today.",
        Type        = "catch_rarity",
        RarityName  = "Diamond",
        Goal        = 1,
        ResetType   = "daily",
        Reward      = { Coins = 300 },
    },
    -- ── Repeatable quests ───────────────────────────────────────────────────
    {
        Id          = "rep_catch_tralalero",
        Name        = "Tralalero Fan",
        Description = "Catch Tralalero Tralala 3 times.",
        Type        = "catch_type",
        BrainrotId  = "tralalero_tralala",
        Goal        = 3,
        ResetType   = "repeatable",
        Reward      = { Coins = 75 },
    },
    {
        Id          = "rep_catch_50",
        Name        = "Seasoned Fisher",
        Description = "Catch 50 brainrots.",
        Type        = "catch_total",
        Goal        = 50,
        ResetType   = "repeatable",
        Reward      = { Coins = 500 },
    },
    {
        Id          = "rep_earn_1000",
        Name        = "Thousand Coins",
        Description = "Earn 1000 coins from fishing.",
        Type        = "earn_coins",
        Goal        = 1000,
        ResetType   = "repeatable",
        Reward      = { Coins = 250 },
    },
    {
        Id          = "rep_catch_frigo",
        Name        = "Camel Hunter",
        Description = "Catch Frigo Camelo 1 time.",
        Type        = "catch_type",
        BrainrotId  = "frigo_camelo",
        Goal        = 1,
        ResetType   = "repeatable",
        Reward      = { Coins = 200 },
    },
}

-- Helper: returns a quest table by Id.
function QuestConfig.GetQuest(id)
    for _, q in ipairs(QuestConfig.QUESTS) do
        if q.Id == id then return q end
    end
    return nil
end

return QuestConfig
