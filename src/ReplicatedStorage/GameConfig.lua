-- GameConfig.lua
-- Central configuration for Evergreen County
-- All tunable game constants live here.

local GameConfig = {}

-- ─── Economy ───────────────────────────────────────────────────────────────
GameConfig.StartingMoney = 500
GameConfig.TaxIntervalSeconds = 3600          -- Real 1 hour  (=1 in-game week)
GameConfig.TaxRatePercent = 2                 -- 2% of property value per cycle
GameConfig.BankInterestRatePercent = 1        -- 1% interest on savings per tax cycle
GameConfig.LoanInterestRatePercent = 5        -- 5% interest on loans per tax cycle
GameConfig.MaxLoan = 10000
GameConfig.AuctionFeePercent = 5              -- Platform cut on auction sales

-- ─── Market / Pricing ──────────────────────────────────────────────────────
-- Base prices for the government store (always available, slightly expensive)
GameConfig.BaseItemPrices = {
    -- Resources
    Wood        = 10,
    Stone       = 8,
    Iron        = 25,
    Coal        = 15,
    Gold        = 80,
    Diamond     = 250,
    -- Food
    Bread       = 5,
    Apple       = 3,
    Milk        = 4,
    Wheat       = 2,
    Corn        = 2,
    Mushroom    = 6,
    Berry       = 4,
    Fish        = 8,
    Meat        = 12,
    -- Drink
    Water       = 2,
    Juice       = 5,
    Coffee      = 8,
    -- Vehicles
    Bicycle     = 0,          -- Free starter
    Car_Basic   = 3000,
    Car_Sports  = 12000,
    Car_Truck   = 6000,
    -- Tools
    Pickaxe     = 50,
    Axe         = 40,
    FishingRod  = 30,
    WateringCan = 20,
    -- Building
    Foundation  = 50,
    Wall        = 30,
    Roof        = 40,
    Window      = 25,
    Door        = 35,
    Fireplace   = 150,
    Heater      = 120,
    Bed         = 200,
    Table       = 100,
    Chair       = 60,
    Lamp        = 45,
    Refrigerator = 300,
    Stove       = 250,
    Sofa        = 350,
    Wardrobe    = 220,
    -- Clothes
    Coat        = 80,
    Jacket      = 50,
    TShirt      = 20,
    Scarf       = 15,
    Hat         = 25,
    -- Farming
    SeedWheat   = 5,
    SeedCorn    = 5,
    SeedTomato  = 8,
    SeedPotato  = 6,
    Fertilizer  = 10,
    -- Medical
    Bandage     = 15,
    Medicine    = 30,
    -- Other
    TrashBag    = 5,
}

-- How many of a given item are being sold influences the gov price
-- SupplyPriceMult: if supply > threshold, multiply base price by this
GameConfig.SupplyThreshold = 50      -- Units across all players
GameConfig.SupplyDiscountMult = 0.7  -- Price drops to 70% if oversupplied
GameConfig.ScarcityMult = 1.5        -- Price rises to 150% if undersupplied

-- ─── Character Stats ───────────────────────────────────────────────────────
GameConfig.MaxHunger      = 100
GameConfig.MaxThirst      = 100
GameConfig.MaxEnergy      = 100
GameConfig.MaxHealth      = 100
GameConfig.MaxTemperature = 100   -- 50 = neutral, <20 = cold, >80 = hot

GameConfig.HungerDecayRate    = 0.5  -- per minute
GameConfig.ThirstDecayRate    = 0.8  -- per minute (faster than hunger)
GameConfig.EnergyDecayRate    = 1.0  -- per minute while working/running
GameConfig.EnergyRecoveryRate = 2.0  -- per minute while sleeping

-- Damage per minute when stat hits zero
GameConfig.HungerDamage       = 2
GameConfig.ThirstDamage       = 3
GameConfig.ColdDamage         = 1   -- per minute when temp < 15
GameConfig.HeatDamage         = 1   -- per minute when temp > 85

-- Temperature adjustment rates
GameConfig.TemperatureNeutral = 50
GameConfig.OutdoorTempCold    = 20   -- Base outdoor temp in winter
GameConfig.OutdoorTempHot     = 75   -- Base outdoor temp in summer
GameConfig.ClothingWarmth     = {
    TShirt = 0, Jacket = 10, Coat = 20, Scarf = 5, Hat = 5,
}
GameConfig.InsideWarmthBonus  = 15
GameConfig.FireplaceWarmth    = 25
GameConfig.HeaterWarmth       = 20

-- ─── Reputation ────────────────────────────────────────────────────────────
GameConfig.ReputationMin         = -100
GameConfig.ReputationMax         = 100
GameConfig.ReputationStarting    = 0
GameConfig.ReputationShopDiscount = 0.1  -- 10% discount per 50 reputation
GameConfig.ReputationBannedBelow = -75   -- Shops refuse service below this

-- ─── Professions ───────────────────────────────────────────────────────────
GameConfig.Professions = {
    "Unemployed", "Miner", "Farmer", "Sheriff",
    "Mechanic", "Builder", "Chef",
}
GameConfig.ProfessionLicenseCost = {
    Unemployed = 0,
    Miner      = 200,
    Farmer     = 150,
    Sheriff    = 0,    -- Appointed by Town Hall
    Mechanic   = 300,
    Builder    = 250,
    Chef       = 200,
}

-- ─── Vehicles ──────────────────────────────────────────────────────────────
GameConfig.VehicleMaxDurability = 100
GameConfig.VehicleDurabilityDecayPerStud = 0.002  -- wear per stud traveled
GameConfig.VehicleRepairCostPerPoint = 5           -- cost to repair 1 durability
GameConfig.BicycleSpeed   = 20
GameConfig.CarBasicSpeed  = 60
GameConfig.CarSportsSpeed = 120
GameConfig.CarTruckSpeed  = 45

-- ─── Weather / Seasons ─────────────────────────────────────────────────────
-- 1 season = 3600 real seconds (1 hour) — easy to tune
GameConfig.SeasonDurationSeconds = 3600
GameConfig.Seasons = { "Spring", "Summer", "Autumn", "Winter" }
GameConfig.WeatherTypes = { "Clear", "Cloudy", "Rainy", "Snowy", "Foggy" }
GameConfig.WeatherChangeProbability = {
    Spring = { Clear=0.4, Cloudy=0.3, Rainy=0.3, Snowy=0.0, Foggy=0.0 },
    Summer = { Clear=0.6, Cloudy=0.2, Rainy=0.15, Snowy=0.0, Foggy=0.05 },
    Autumn = { Clear=0.3, Cloudy=0.35, Rainy=0.3, Snowy=0.0, Foggy=0.05 },
    Winter = { Clear=0.3, Cloudy=0.3, Rainy=0.0, Snowy=0.35, Foggy=0.05 },
}
GameConfig.AutumnFarmBonus   = 2.0   -- Double farm yield in Autumn
GameConfig.SummerThirstMult  = 1.5   -- Thirst decays 50% faster in Summer
GameConfig.WinterEnergyMult  = 1.3   -- Energy decays 30% faster in Winter

-- ─── Building ──────────────────────────────────────────────────────────────
GameConfig.PlotSizes = {
    Small  = Vector3.new(30, 50, 30),
    Medium = Vector3.new(45, 50, 45),
    Large  = Vector3.new(60, 50, 60),
}
GameConfig.PlotPrices = { Small=5000, Medium=9000, Large=15000 }
GameConfig.MaxBuildHeight = 100
GameConfig.GridSize = 2          -- Default snap grid in studs
GameConfig.FineGridSize = 0.25   -- Fine grid size
GameConfig.MaxObjectsPerPlot = 1000

-- ─── Criminal / Law ────────────────────────────────────────────────────────
GameConfig.JailTime = 120        -- seconds in jail per crime severity level
GameConfig.BailCost = 500        -- cost to bail out
GameConfig.CrimeSeverity = {
    Littering = 1,
    Theft     = 3,
    Assault   = 5,
    Murder    = 10,
}
GameConfig.ArrestRange = 10      -- studs, sheriff arrest range

-- ─── NPC ───────────────────────────────────────────────────────────────────
GameConfig.NPCWalkSpeed   = 8
GameConfig.NPCCount       = 20
GameConfig.BanditSpawnMax = 5

-- ─── Transport ─────────────────────────────────────────────────────────────
GameConfig.BusStopCount   = 8
GameConfig.BusLoopSeconds = 120   -- One full bus circuit

-- ─── DataStore ─────────────────────────────────────────────────────────────
GameConfig.DataVersion = 1
GameConfig.AutoSaveInterval = 60  -- seconds between autosaves

return GameConfig
