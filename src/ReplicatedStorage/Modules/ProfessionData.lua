-- Modules/ProfessionData.lua
-- Static data about each profession: description, work location, bonuses

local ProfessionData = {}

ProfessionData.List = {
    {
        Name        = "Unemployed",
        Icon        = "🪣",
        Description = "No fixed job. Collect trash for quick cash, switch professions freely.",
        WorkLocation= "Streets",
        License     = 0,
        Skills = {
            "Trash collecting (small income)",
            "Fast profession switching",
        },
        Bonus = "Can switch professions instantly without waiting.",
    },
    {
        Name        = "Miner",
        Icon        = "⛏️",
        Description = "Work in the mine. The deeper you dig, the rarer the ore.",
        WorkLocation= "Mine (Industrial Zone)",
        License     = 200,
        Skills = {
            "Ore detection (see veins through walls)",
            "Deep drilling mini-game",
            "Can carry more ore per trip",
        },
        Bonus = "Can detect ore nodes through terrain.",
    },
    {
        Name        = "Farmer",
        Icon        = "🌾",
        Description = "Grow crops and raise animals on rented or owned farmland.",
        WorkLocation= "Farm Fields (Industrial Zone)",
        License     = 150,
        Skills = {
            "Plant wheat, corn, tomatoes, potatoes",
            "Care for chickens and cows",
            "Craft food that restores more stats",
        },
        Bonus = "Home-grown food restores 25% more stats.",
    },
    {
        Name        = "Sheriff",
        Icon        = "⭐",
        Description = "Keep the peace. Arrest criminals and protect citizens.",
        WorkLocation= "Town Hall / City",
        License     = 0,
        Skills = {
            "Arrest players and NPCs",
            "Issue fines",
            "Free handcuffs and badge",
        },
        Bonus = "Immune to littering fines. +10 reputation on arrest.",
    },
    {
        Name        = "Mechanic",
        Icon        = "🔧",
        Description = "Repair and tune vehicles. Own the fastest rides.",
        WorkLocation= "Garage (Industrial Zone)",
        License     = 300,
        Skills = {
            "Repair vehicle durability",
            "Tune car speed/handling",
            "Paint custom colors",
        },
        Bonus = "Personal vehicles have +20% max speed.",
    },
    {
        Name        = "Builder",
        Icon        = "🏗️",
        Description = "Accept building commissions from other players.",
        WorkLocation= "Player Plots",
        License     = 250,
        Skills = {
            "Access Pro furniture catalog",
            "Build on any player's plot (with permission)",
            "No grid restriction on fine placement",
        },
        Bonus = "Unlocks Pro furniture catalog.",
    },
    {
        Name        = "Chef",
        Icon        = "👨‍🍳",
        Description = "Cook complex dishes that give temporary stat buffs.",
        WorkLocation= "Café / Food Kiosk",
        License     = 200,
        Skills = {
            "Cook advanced recipes",
            "Food gives temporary buffs (speed, energy, warmth)",
            "Run your own food stall",
        },
        Bonus = "Cooked food grants temporary stat buffs.",
    },
}

-- Quick lookup by name
ProfessionData.ByName = {}
for _, prof in ipairs(ProfessionData.List) do
    ProfessionData.ByName[prof.Name] = prof
end

return ProfessionData
