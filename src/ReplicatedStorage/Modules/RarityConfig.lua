--[[
    RarityConfig.lua
    Defines the 9 brainrot collectible templates and their per-rarity variants.

    To add a new brainrot:
        1. Add an entry to BRAINROTS with a unique id, display Name and CoinValue.
        2. The rarity system will automatically create Normal / Golden / Diamond
           variants using RARITIES multipliers.

    To add a new rarity (e.g. "Rainbow"):
        1. Add an entry to RARITIES with a Weight (lower = rarer) and multipliers.
        2. Update SpinConfig / QuestConfig as needed.
--]]

local RarityConfig = {}

-- ─── Rarities ───────────────────────────────────────────────────────────────
-- Weight is relative (e.g. Normal=70, Golden=20, Diamond=10 → 70/100 chance)
RarityConfig.RARITIES = {
    {
        Name          = "Normal",
        Weight        = 70,
        Color         = Color3.fromRGB(200, 200, 200),
        CoinMultiplier = 1,
        LuckMultiplier = 1,
    },
    {
        Name          = "Golden",
        Weight        = 20,
        Color         = Color3.fromRGB(255, 215, 0),
        CoinMultiplier = 3,
        LuckMultiplier = 1,
    },
    {
        Name          = "Diamond",
        Weight        = 10,
        Color         = Color3.fromRGB(100, 220, 255),
        CoinMultiplier = 10,
        LuckMultiplier = 1,
    },
}

-- ─── Brainrot Templates ─────────────────────────────────────────────────────
-- CoinValue is the BASE value for a Normal catch; rarities multiply it.
RarityConfig.BRAINROTS = {
    {
        Id        = "tralalero_tralala",
        Name      = "Tralalero Tralala",
        CoinValue = 10,
        ModelId   = 0,  -- Replace with real Roblox asset ID
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "bombardiro_crocodilo",
        Name      = "Bombardiro Crocodilo",
        CoinValue = 12,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "tung_tung_tung_sahur",
        Name      = "Tung Tung Tung Sahur",
        CoinValue = 15,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "brrr_brrr_patapim",
        Name      = "Brrr Brrr Patapim",
        CoinValue = 18,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "lirili_larila",
        Name      = "Lirili Larila",
        CoinValue = 20,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "bobritto_bandito",
        Name      = "Bobritto Bandito",
        CoinValue = 25,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "glorbo_fischetto",
        Name      = "Glorbo Fischetto",
        CoinValue = 30,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "cappuccino_assassino",
        Name      = "Cappuccino Assassino",
        CoinValue = 40,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
    {
        Id        = "frigo_camelo",
        Name      = "Frigo Camelo",
        CoinValue = 50,
        ModelId   = 0,
        ImageId   = "rbxassetid://0",
    },
}

-- ─── Helpers ────────────────────────────────────────────────────────────────

-- Returns the rarity table by name (case-sensitive).
function RarityConfig.GetRarity(name)
    for _, r in ipairs(RarityConfig.RARITIES) do
        if r.Name == name then return r end
    end
    return RarityConfig.RARITIES[1]
end

-- Returns total weight sum for roll calculations.
function RarityConfig.TotalWeight()
    local total = 0
    for _, r in ipairs(RarityConfig.RARITIES) do
        total = total + r.Weight
    end
    return total
end

-- Returns a brainrot table by id.
function RarityConfig.GetBrainrot(id)
    for _, b in ipairs(RarityConfig.BRAINROTS) do
        if b.Id == id then return b end
    end
    return nil
end

return RarityConfig
