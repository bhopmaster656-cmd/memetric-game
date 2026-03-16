-- Modules/ItemData.lua
-- Catalog of all purchasable / obtainable items

local ItemData = {}

-- Category constants
ItemData.CATEGORY = {
    RESOURCE  = "Resource",
    FOOD      = "Food",
    DRINK     = "Drink",
    CLOTHING  = "Clothing",
    FURNITURE = "Furniture",
    VEHICLE   = "Vehicle",
    TOOL      = "Tool",
    SEED      = "Seed",
    MEDICAL   = "Medical",
    OTHER     = "Other",
}

-- Full item catalog
-- stackable: can multiple fit in one inventory slot
-- consumable: disappears on use
ItemData.Catalog = {
    -- Resources
    { id="Wood",       name="Wood",        category=ItemData.CATEGORY.RESOURCE,  stackable=true,  consumable=false, description="Used in construction." },
    { id="Stone",      name="Stone",       category=ItemData.CATEGORY.RESOURCE,  stackable=true,  consumable=false, description="Durable building material." },
    { id="Iron",       name="Iron Ore",    category=ItemData.CATEGORY.RESOURCE,  stackable=true,  consumable=false, description="Smelted into iron bars." },
    { id="Coal",       name="Coal",        category=ItemData.CATEGORY.RESOURCE,  stackable=true,  consumable=false, description="Fuel for fireplaces." },
    { id="Gold",       name="Gold Ore",    category=ItemData.CATEGORY.RESOURCE,  stackable=true,  consumable=false, description="Rare. High value." },
    { id="Diamond",    name="Diamond",     category=ItemData.CATEGORY.RESOURCE,  stackable=true,  consumable=false, description="Very rare gem." },

    -- Food
    { id="Bread",      name="Bread",       category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  hungerRestore=25, description="Basic food." },
    { id="Apple",      name="Apple",       category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  hungerRestore=10, thirstRestore=5, description="Juicy apple." },
    { id="Milk",       name="Milk",        category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  thirstRestore=20, description="Fresh milk." },
    { id="Wheat",      name="Wheat",       category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=false, description="Raw grain. Craft into bread." },
    { id="Corn",       name="Corn",        category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  hungerRestore=12, description="Sweet corn." },
    { id="Mushroom",   name="Mushroom",    category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  hungerRestore=8,  description="Found in the forest." },
    { id="Berry",      name="Berry",       category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  hungerRestore=5,  thirstRestore=5, description="Wild berries." },
    { id="Fish",       name="Fish",        category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  hungerRestore=20, description="Caught while fishing." },
    { id="Meat",       name="Meat",        category=ItemData.CATEGORY.FOOD,     stackable=true,  consumable=true,  hungerRestore=30, description="From hunting." },

    -- Drinks
    { id="Water",      name="Water Bottle",category=ItemData.CATEGORY.DRINK,    stackable=true,  consumable=true,  thirstRestore=30, description="Clean water." },
    { id="Juice",      name="Juice",       category=ItemData.CATEGORY.DRINK,    stackable=true,  consumable=true,  thirstRestore=20, hungerRestore=5, description="Fruit juice." },
    { id="Coffee",     name="Coffee",      category=ItemData.CATEGORY.DRINK,    stackable=true,  consumable=true,  thirstRestore=10, energyRestore=15, description="Keeps you energized." },

    -- Clothing
    { id="TShirt",     name="T-Shirt",     category=ItemData.CATEGORY.CLOTHING, stackable=false, consumable=false, warmth=0,  description="Basic top." },
    { id="Jacket",     name="Jacket",      category=ItemData.CATEGORY.CLOTHING, stackable=false, consumable=false, warmth=10, description="Light warmth." },
    { id="Coat",       name="Winter Coat", category=ItemData.CATEGORY.CLOTHING, stackable=false, consumable=false, warmth=20, description="Best protection from cold." },
    { id="Scarf",      name="Scarf",       category=ItemData.CATEGORY.CLOTHING, stackable=false, consumable=false, warmth=5,  description="Neck warmer." },
    { id="Hat",        name="Hat",         category=ItemData.CATEGORY.CLOTHING, stackable=false, consumable=false, warmth=5,  description="Keeps your head warm." },

    -- Tools
    { id="Pickaxe",    name="Pickaxe",     category=ItemData.CATEGORY.TOOL,     stackable=false, consumable=false, description="Mine ore and stone." },
    { id="Axe",        name="Axe",         category=ItemData.CATEGORY.TOOL,     stackable=false, consumable=false, description="Chop trees." },
    { id="FishingRod", name="Fishing Rod", category=ItemData.CATEGORY.TOOL,     stackable=false, consumable=false, description="Fish in ponds and rivers." },
    { id="WateringCan",name="Watering Can",category=ItemData.CATEGORY.TOOL,     stackable=false, consumable=false, description="Water your crops." },
    { id="TrashBag",   name="Trash Bag",   category=ItemData.CATEGORY.TOOL,     stackable=true,  consumable=true,  description="Collect litter for cash." },

    -- Medical
    { id="Bandage",    name="Bandage",     category=ItemData.CATEGORY.MEDICAL,  stackable=true,  consumable=true,  healthRestore=15, description="Stops bleeding." },
    { id="Medicine",   name="Medicine",    category=ItemData.CATEGORY.MEDICAL,  stackable=true,  consumable=true,  healthRestore=40, description="Heals major injuries." },

    -- Seeds
    { id="SeedWheat",  name="Wheat Seed",  category=ItemData.CATEGORY.SEED,     stackable=true,  consumable=true,  description="Plant in spring or summer." },
    { id="SeedCorn",   name="Corn Seed",   category=ItemData.CATEGORY.SEED,     stackable=true,  consumable=true,  description="Plant in summer." },
    { id="SeedTomato", name="Tomato Seed", category=ItemData.CATEGORY.SEED,     stackable=true,  consumable=true,  description="Plant in summer." },
    { id="SeedPotato", name="Potato Seed", category=ItemData.CATEGORY.SEED,     stackable=true,  consumable=true,  description="Grows in any season except winter." },
    { id="Fertilizer", name="Fertilizer",  category=ItemData.CATEGORY.OTHER,    stackable=true,  consumable=true,  description="Doubles crop yield." },

    -- Vehicles
    { id="Bicycle",      name="Bicycle",       category=ItemData.CATEGORY.VEHICLE, stackable=false, consumable=false, speed=20,  description="Free starter vehicle." },
    { id="Car_Basic",    name="Family Car",     category=ItemData.CATEGORY.VEHICLE, stackable=false, consumable=false, speed=60,  description="Reliable city car." },
    { id="Car_Sports",   name="Sports Car",     category=ItemData.CATEGORY.VEHICLE, stackable=false, consumable=false, speed=120, description="Fast but fragile." },
    { id="Car_Truck",    name="Pickup Truck",   category=ItemData.CATEGORY.VEHICLE, stackable=false, consumable=false, speed=45,  description="Rugged and practical." },

    -- Furniture (building mode items)
    { id="Foundation",   name="Foundation",     category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Base for construction." },
    { id="Wall",         name="Wall",           category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Standard wall panel." },
    { id="Roof",         name="Roof Panel",     category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Covers your building." },
    { id="Window",       name="Window",         category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Lets in natural light." },
    { id="Door",         name="Door",           category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Entry point." },
    { id="Fireplace",    name="Fireplace",      category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, warmth=25, description="Heats your home in winter." },
    { id="Heater",       name="Electric Heater",category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, warmth=20, description="Modern home heating." },
    { id="Bed",          name="Bed",            category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Sleep to restore Energy." },
    { id="Table",        name="Table",          category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Dining table." },
    { id="Chair",        name="Chair",          category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Standard chair." },
    { id="Lamp",         name="Floor Lamp",     category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Lights up a room." },
    { id="Refrigerator", name="Refrigerator",   category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Stores food." },
    { id="Stove",        name="Stove",          category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Cook complex recipes." },
    { id="Sofa",         name="Sofa",           category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Comfortable seating." },
    { id="Wardrobe",     name="Wardrobe",       category=ItemData.CATEGORY.FURNITURE, stackable=true,  consumable=false, description="Stores clothing." },
}

-- Build quick lookup by id
ItemData.ById = {}
for _, item in ipairs(ItemData.Catalog) do
    ItemData.ById[item.id] = item
end

return ItemData
