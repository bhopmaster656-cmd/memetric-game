-- GameConfig.lua
-- ReplicatedStorage > Modules > GameConfig
-- Central configuration for all game systems.

local GameConfig = {}

-- ──────────────────────────────────────────────
-- ECONOMY
-- ──────────────────────────────────────────────
GameConfig.StartingCash   = 5000          -- Cash given to brand‑new players
GameConfig.SalaryInterval = 60            -- Seconds between salary payments
GameConfig.TaxInterval    = 300           -- Seconds between tax collection cycles

-- ──────────────────────────────────────────────
-- JOBS
-- ──────────────────────────────────────────────
-- salary: cash awarded every SalaryInterval seconds
-- color:  team / uniform BrickColor name
GameConfig.Jobs = {
    {
        id       = "firefighter",
        name     = "Firefighter",
        salary   = 150,
        color    = "Bright red",
        maxSlots = 10,
        tools    = {"FireHose"},
    },
    {
        id       = "police",
        name     = "Police Officer",
        salary   = 175,
        color    = "Bright blue",
        maxSlots = 10,
        tools    = {"Handcuffs", "Radio"},
    },
    {
        id       = "construction",
        name     = "Construction Worker",
        salary   = 120,
        color    = "Bright yellow",
        maxSlots = 15,
        tools    = {"Hammer"},
    },
    {
        id       = "mechanic",
        name     = "Mechanic",
        salary   = 140,
        color    = "Medium stone grey",
        maxSlots = 12,
        tools    = {"Wrench"},
    },
    {
        id       = "plumber",
        name     = "Plumber",
        salary   = 130,
        color    = "White",
        maxSlots = 10,
        tools    = {"Plunger"},
    },
    {
        id       = "deputy",
        name     = "Deputy Sheriff",
        salary   = 160,
        color    = "Reddish brown",
        maxSlots = 8,
        tools    = {"Handcuffs"},
    },
    {
        id       = "doctor",
        name     = "Doctor",
        salary   = 250,
        color    = "White",
        maxSlots = 8,
        tools    = {"MedKit"},
    },
    {
        id       = "teacher",
        name     = "Teacher",
        salary   = 145,
        color    = "Medium green",
        maxSlots = 8,
        tools    = {},
    },
    {
        id       = "chef",
        name     = "Chef",
        salary   = 135,
        color    = "White",
        maxSlots = 10,
        tools    = {},
    },
    {
        id       = "mayor",
        name     = "Mayor",
        salary   = 400,
        color    = "Dark orange",
        maxSlots = 1,
        tools    = {},
    },
}

-- ──────────────────────────────────────────────
-- PROPERTIES  (homes)
-- ──────────────────────────────────────────────
-- price:    purchase price
-- taxRate:  fraction of price collected each TaxInterval
-- maxOwned: how many of this type a single player may own
GameConfig.Properties = {
    {
        id       = "studio",
        name     = "Studio Apartment",
        price    = 10000,
        taxRate  = 0.02,
        maxOwned = 3,
    },
    {
        id       = "apartment",
        name     = "Apartment",
        price    = 50000,
        taxRate  = 0.018,
        maxOwned = 3,
    },
    {
        id       = "house",
        name     = "House",
        price    = 150000,
        taxRate  = 0.015,
        maxOwned = 2,
    },
    {
        id       = "mansion",
        name     = "Mansion",
        price    = 500000,
        taxRate  = 0.012,
        maxOwned = 1,
    },
    {
        id       = "land",
        name     = "Land Plot",
        price    = 25000,
        taxRate  = 0.01,
        maxOwned = 5,
    },
}

-- ──────────────────────────────────────────────
-- BUSINESSES
-- ──────────────────────────────────────────────
-- cost:        upfront purchase price
-- incomePerMin: passive income each minute the business is open
-- taxRate:     fraction of incomePerMin * 60 collected per TaxInterval
GameConfig.Businesses = {
    {
        id          = "autorepair",
        name        = "Auto Repair Shop",
        cost        = 75000,
        incomePerMin = 250,
        taxRate     = 0.05,
        maxOwned    = 2,
    },
    {
        id          = "dealership",
        name        = "Car Dealership",
        cost        = 200000,
        incomePerMin = 600,
        taxRate     = 0.06,
        maxOwned    = 1,
    },
    {
        id          = "restaurant",
        name        = "Restaurant",
        cost        = 100000,
        incomePerMin = 350,
        taxRate     = 0.05,
        maxOwned    = 2,
    },
    {
        id          = "gasstation",
        name        = "Gas Station",
        cost        = 80000,
        incomePerMin = 280,
        taxRate     = 0.05,
        maxOwned    = 2,
    },
    {
        id          = "grocery",
        name        = "Grocery Store",
        cost        = 120000,
        incomePerMin = 400,
        taxRate     = 0.055,
        maxOwned    = 2,
    },
    {
        id          = "realestate",
        name        = "Real Estate Agency",
        cost        = 160000,
        incomePerMin = 500,
        taxRate     = 0.06,
        maxOwned    = 1,
    },
}

-- ──────────────────────────────────────────────
-- MONETIZATION  (Developer Products & Game Passes)
-- ──────────────────────────────────────────────
-- NOTE: Replace 0 placeholders with real asset IDs from the Roblox Creator Dashboard.
GameConfig.DevProducts = {
    { id = 0, name = "Cash Pack Small",  cash = 5000,   price = 75  },
    { id = 0, name = "Cash Pack Medium", cash = 15000,  price = 175 },
    { id = 0, name = "Cash Pack Large",  cash = 50000,  price = 499 },
    { id = 0, name = "Cash Pack Mega",   cash = 150000, price = 999 },
}

GameConfig.GamePasses = {
    { id = 0, name = "Premium Citizen",  description = "Double salary income",        salaryMultiplier = 2 },
    { id = 0, name = "VIP Resident",     description = "Access to VIP Mansion District and gold name tag", salaryMultiplier = 1 },
    { id = 0, name = "Business Tycoon",  description = "Reduced business tax (50%) and +1 extra business slot", salaryMultiplier = 1 },
}

-- ──────────────────────────────────────────────
-- AUCTION
-- ──────────────────────────────────────────────
GameConfig.AuctionDuration    = 120   -- seconds an auction listing stays active
GameConfig.AuctionMinBidRaise = 0.05  -- minimum raise fraction over current bid (5 %)

return GameConfig
