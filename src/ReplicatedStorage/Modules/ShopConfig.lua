--[[
    ShopConfig.lua
    Defines purchasable packs and gamepasses shown in the in-game shop.

    PACKS: one-time or limited bundles of brainrots/boosted luck.
    GAMEPASSES: permanent perks (VIP, coin boost, luck boost).

    Set real Roblox asset/gamepass IDs before publishing.
--]]

local ShopConfig = {}

-- ─── Brainrot Packs ─────────────────────────────────────────────────────────
ShopConfig.PACKS = {
    {
        Id          = "starter_pack",
        Name        = "Starter Pack",
        Description = "Guaranteed 5 Normal brainrots + 100 bonus coins.",
        Price       = 99,  -- Robux (DevProduct)
        ProductId   = 0,   -- Set real Roblox DevProduct ID
        Contents    = {
            { Type = "coins",     Amount = 100 },
            { Type = "brainrots", Rarity = "Normal", Count = 5 },
        },
    },
    {
        Id          = "golden_pack",
        Name        = "Golden Pack",
        Description = "Guaranteed 3 Golden brainrots + 500 bonus coins.",
        Price       = 299,
        ProductId   = 0,
        Contents    = {
            { Type = "coins",     Amount = 500 },
            { Type = "brainrots", Rarity = "Golden", Count = 3 },
        },
    },
    {
        Id          = "diamond_pack",
        Name        = "Diamond Pack",
        Description = "Guaranteed 1 Diamond brainrot + 1000 bonus coins.",
        Price       = 699,
        ProductId   = 0,
        Contents    = {
            { Type = "coins",     Amount = 1000 },
            { Type = "brainrots", Rarity = "Diamond", Count = 1 },
        },
    },
    {
        Id          = "luck_pack",
        Name        = "Lucky Pack",
        Description = "Doubles your rarity luck for 30 minutes.",
        Price       = 199,
        ProductId   = 0,
        Contents    = {
            { Type = "boost", BoostType = "luck", Multiplier = 2, DurationMin = 30 },
        },
    },
}

-- ─── Gamepasses ─────────────────────────────────────────────────────────────
ShopConfig.GAMEPASSES = {
    {
        Id          = "vip",
        Name        = "VIP",
        Description = "+15% luck, +25% coins, extra daily spin.",
        GamePassId  = 0,  -- Set real Roblox GamePass ID (also in GameConfig)
        Price       = 399,
    },
    {
        Id          = "auto_reel",
        Name        = "Auto Reel",
        Description = "Automatically reels your rod when a fish bites.",
        GamePassId  = 0,
        Price       = 199,
    },
    {
        Id          = "double_coins",
        Name        = "Coin Doubler",
        Description = "Permanently earn 2x coins from fishing.",
        GamePassId  = 0,
        Price       = 299,
    },
}

-- Helper: returns a pack table by Id.
function ShopConfig.GetPack(id)
    for _, p in ipairs(ShopConfig.PACKS) do
        if p.Id == id then return p end
    end
    return nil
end

-- Helper: returns a gamepass table by Id.
function ShopConfig.GetGamepass(id)
    for _, g in ipairs(ShopConfig.GAMEPASSES) do
        if g.Id == id then return g end
    end
    return nil
end

return ShopConfig
