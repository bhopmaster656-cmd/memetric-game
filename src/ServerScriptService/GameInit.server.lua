-- ServerScriptService/GameInit.server.lua
-- Evergreen County — World initialization
-- Runs once on server start: builds the physical world, sets up locations,
-- places bus stops, spawns NPCs and initial resources.

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local ServerStorage    = game:GetService("ServerStorage")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

print("[GameInit] Starting Evergreen County world build…")

-- ─── Terrain Setup ──────────────────────────────────────────────────────────
-- We programmatically fill the terrain with basic biomes.
-- In production you would load a saved terrain file; here we generate it
-- so the place is self-contained with no external assets required.

local terrain = Workspace.Terrain

local function fillBlock(cf, size, material)
    terrain:FillBlock(cf, size, material)
end

local function createBaseMap()
    -- Grass base
    fillBlock(
        CFrame.new(0, -4, 0),
        Vector3.new(2048, 8, 2048),
        Enum.Material.Grass
    )
    -- Roads (grey strips through Downtown and Industrial)
    fillBlock(CFrame.new(0, 1, 0),  Vector3.new(2048, 2, 20), Enum.Material.Concrete)  -- main road EW
    fillBlock(CFrame.new(0, 1, 0),  Vector3.new(20, 2, 2048), Enum.Material.Concrete)  -- main road NS
    -- Pond in Suburbs park
    fillBlock(CFrame.new(-200, -1, -200), Vector3.new(80, 4, 80), Enum.Material.Water)
    -- Mountains (North region)
    fillBlock(CFrame.new(0, 50, -800), Vector3.new(600, 100, 400), Enum.Material.Rock)
    -- Beach (South)
    fillBlock(CFrame.new(0, 0, 800), Vector3.new(800, 2, 100), Enum.Material.Sand)
    -- Mine entrance (Industrial, East)
    fillBlock(CFrame.new(400, -20, 200), Vector3.new(100, 40, 100), Enum.Material.Rock)
    print("[GameInit] Terrain generated")
end

-- ─── Helper: Create a Part ───────────────────────────────────────────────────
local function makePart(props)
    local p = Instance.new("Part")
    p.Anchored    = true
    p.CanCollide  = props.collide ~= false
    p.Size        = props.size or Vector3.new(4, 4, 4)
    p.CFrame      = props.cframe or CFrame.new(props.pos or Vector3.new(0, 2, 0))
    p.BrickColor  = props.color or BrickColor.new("Light grey")
    p.Material    = props.material or Enum.Material.SmoothPlastic
    p.Name        = props.name or "Part"
    if props.parent then p.Parent = props.parent end
    return p
end

-- ─── Helper: Create a labeled building block ─────────────────────────────────
local function makeBuilding(name, pos, size, color, parent)
    local model = Instance.new("Model")
    model.Name  = name
    local body = makePart({
        name     = "Body",
        pos      = pos,
        size     = size,
        color    = color,
        material = Enum.Material.SmoothPlastic,
        parent   = model,
    })
    -- Roof
    makePart({
        name   = "Roof",
        cframe = CFrame.new(pos) * CFrame.new(0, size.Y / 2 + 2, 0),
        size   = Vector3.new(size.X + 2, 2, size.Z + 2),
        color  = BrickColor.new("Dark red"),
        parent = model,
    })
    -- Label
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.StudsOffset = Vector3.new(0, size.Y / 2 + 5, 0)
    gui.AlwaysOnTop = false
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui
    gui.Parent = body
    model.PrimaryPart = body
    model.Parent = parent or Workspace
    return model
end

-- ─── Build Downtown ──────────────────────────────────────────────────────────
local function buildDowntown()
    local downtown = Instance.new("Folder")
    downtown.Name  = "Downtown"
    downtown.Parent = Workspace

    makeBuilding("Town Hall",    Vector3.new(-50, 10, 0),  Vector3.new(30, 20, 30), BrickColor.new("Bright yellow"), downtown)
    makeBuilding("Bank",         Vector3.new(50,  8,  0),  Vector3.new(25, 16, 25), BrickColor.new("Bright blue"),   downtown)
    makeBuilding("Clothing Shop",Vector3.new(-50, 6,  60), Vector3.new(20, 12, 20), BrickColor.new("Bright pink"),   downtown)
    makeBuilding("Furniture Shop",Vector3.new(50, 6,  60), Vector3.new(20, 12, 20), BrickColor.new("Bright orange"), downtown)
    makeBuilding("Café",         Vector3.new(0,   5,  80), Vector3.new(25, 10, 20), BrickColor.new("Medium brown"),  downtown)
    makeBuilding("Government Store", Vector3.new(0, 8, -60), Vector3.new(30, 16, 25), BrickColor.new("Bright green"), downtown)
    makeBuilding("Police Station",Vector3.new(-100, 8, 0), Vector3.new(25, 16, 20), BrickColor.new("Reddish brown"), downtown)
    makeBuilding("Hospital",     Vector3.new(100,  8, 0),  Vector3.new(30, 16, 25), BrickColor.new("White"),         downtown)

    print("[GameInit] Downtown built")
end

-- ─── Build Industrial Zone ───────────────────────────────────────────────────
local function buildIndustrial()
    local industrial = Instance.new("Folder")
    industrial.Name  = "IndustrialZone"
    industrial.Parent = Workspace

    makeBuilding("Mine Entrance",   Vector3.new(400, 8, 200),  Vector3.new(30, 16, 30), BrickColor.new("Dark grey"),   industrial)
    makeBuilding("Mechanic Garage", Vector3.new(350, 6, 100),  Vector3.new(35, 12, 35), BrickColor.new("Bright red"),  industrial)
    makeBuilding("Warehouse",       Vector3.new(450, 6, 100),  Vector3.new(50, 12, 40), BrickColor.new("Sand yellow"), industrial)
    makeBuilding("Farm Supply",     Vector3.new(300, 5, 250),  Vector3.new(25, 10, 20), BrickColor.new("Bright green"),industrial)

    -- Farming plots (flat ground)
    local farmFolder = Instance.new("Folder")
    farmFolder.Name   = "FarmPlots"
    farmFolder.Parent = industrial
    for i = 1, 6 do
        local plot = makePart({
            name     = "FarmPlot_" .. i,
            pos      = Vector3.new(280 + (i - 1) * 35, 1, 300),
            size     = Vector3.new(30, 2, 30),
            color    = BrickColor.new("Brown"),
            material = Enum.Material.Ground,
            parent   = farmFolder,
        })
        plot:SetAttribute("PlotIndex", i)
        plot:SetAttribute("CropType",  "None")
        plot:SetAttribute("GrowthStage", 0)
        plot:SetAttribute("Occupied",  false)
        plot:SetAttribute("OwnerId",   0)
    end
    print("[GameInit] Industrial zone built")
end

-- ─── Build Suburbs (Player Plots) ────────────────────────────────────────────
local function buildSuburbs()
    local suburbs = Instance.new("Folder")
    suburbs.Name  = "Suburbs"
    suburbs.Parent = Workspace

    -- Pre-made empty plots for purchase
    local plotPositions = {
        Vector3.new(-200, 1, 200),
        Vector3.new(-260, 1, 200),
        Vector3.new(-320, 1, 200),
        Vector3.new(-200, 1, 270),
        Vector3.new(-260, 1, 270),
        Vector3.new(-320, 1, 270),
        Vector3.new(-200, 1, 340),
        Vector3.new(-260, 1, 340),
        Vector3.new(-320, 1, 340),
    }
    for i, pos in ipairs(plotPositions) do
        local plot = makePart({
            name     = "Plot_" .. i,
            pos      = pos,
            size     = Vector3.new(30, 1, 30),
            color    = BrickColor.new("Bright green"),
            material = Enum.Material.Grass,
            parent   = suburbs,
        })
        plot:SetAttribute("PlotIndex",  i)
        plot:SetAttribute("OwnerId",    0)
        plot:SetAttribute("CoOwnerId",  0)
        plot:SetAttribute("ForSale",    true)
        plot:SetAttribute("Price",      GameConfig.PlotPrices.Small)
        plot:SetAttribute("PlotSize",   "Small")

        -- "FOR SALE" sign
        local gui = Instance.new("SurfaceGui")
        gui.Face   = Enum.NormalId.Top
        gui.Name   = "PlotSign"
        local lbl  = Instance.new("TextLabel")
        lbl.Size   = UDim2.new(1, 0, 1, 0)
        lbl.Text   = "🏡 Plot " .. i .. "\nFOR SALE\n" .. tostring(GameConfig.PlotPrices.Small) .. " $"
        lbl.TextColor3 = Color3.new(0, 0, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(255, 255, 180)
        lbl.Font   = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Parent = gui
        gui.Parent = plot
    end
    print("[GameInit] Suburbs with " .. #plotPositions .. " plots built")
end

-- ─── Build Wilderness ─────────────────────────────────────────────────────────
local function buildWilderness()
    local wild = Instance.new("Folder")
    wild.Name  = "Wilderness"
    wild.Parent = Workspace

    -- Forest trees (simple cylinders as proxies)
    local treeFolder = Instance.new("Folder")
    treeFolder.Name = "Trees"
    treeFolder.Parent = wild
    for i = 1, 30 do
        local x = math.random(-600, -200)
        local z = math.random(-600, -200)
        local trunk = makePart({
            name     = "Tree_" .. i,
            pos      = Vector3.new(x, 8, z),
            size     = Vector3.new(4, 16, 4),
            color    = BrickColor.new("Brown"),
            material = Enum.Material.Wood,
            parent   = treeFolder,
        })
        trunk:SetAttribute("ResourceType", "Wood")
        trunk:SetAttribute("HasResource",  true)
        -- Canopy
        makePart({
            name     = "Canopy_" .. i,
            cframe   = CFrame.new(x, 20, z),
            size     = Vector3.new(12, 10, 12),
            color    = BrickColor.new("Bright green"),
            material = Enum.Material.Neon,
            parent   = treeFolder,
        })
    end

    -- Ore rocks in wilderness
    local oreFolder = Instance.new("Folder")
    oreFolder.Name = "OreNodes"
    oreFolder.Parent = wild
    local oreTypes = { "Iron", "Coal", "Stone" }
    for i = 1, 15 do
        local x = math.random(200, 600)
        local z = math.random(-600, 600)
        local rock = makePart({
            name     = "OreRock_" .. i,
            pos      = Vector3.new(x, 4, z),
            size     = Vector3.new(6, 6, 6),
            color    = BrickColor.new("Dark grey"),
            material = Enum.Material.Rock,
            parent   = oreFolder,
        })
        rock:SetAttribute("ResourceType", oreTypes[math.random(#oreTypes)])
        rock:SetAttribute("HasResource",  true)
        rock:SetAttribute("Quantity",     math.random(3, 8))
    end

    -- Beach / Lighthouse
    makeBuilding("Lighthouse", Vector3.new(0, 20, 900), Vector3.new(8, 40, 8), BrickColor.new("White"), wild)

    -- Mountain ski resort
    local resort = Instance.new("Folder")
    resort.Name  = "SkiResort"
    resort.Parent = wild
    makeBuilding("Ski Lodge", Vector3.new(-50, 60, -850), Vector3.new(40, 20, 30), BrickColor.new("Medium brown"), resort)

    print("[GameInit] Wilderness built")
end

-- ─── Bus Stops ────────────────────────────────────────────────────────────────
local function placeBusStops()
    local busFolder = Instance.new("Folder")
    busFolder.Name  = "BusStops"
    busFolder.Parent = Workspace

    local stops = {
        { name="Downtown Central",  pos=Vector3.new(0,   2,  20) },
        { name="Town Hall",         pos=Vector3.new(-55, 2,  25) },
        { name="Bank Stop",         pos=Vector3.new(55,  2,  25) },
        { name="Suburbs North",     pos=Vector3.new(-200,2, 160) },
        { name="Suburbs South",     pos=Vector3.new(-200,2, 370) },
        { name="Industrial Entry",  pos=Vector3.new(280, 2, 150) },
        { name="Mine Stop",         pos=Vector3.new(395, 2, 170) },
        { name="Wilderness Gate",   pos=Vector3.new(-400,2,-180) },
    }

    for i, stopData in ipairs(stops) do
        local sign = makePart({
            name   = "BusStop_" .. i,
            pos    = stopData.pos,
            size   = Vector3.new(4, 8, 1),
            color  = BrickColor.new("Bright yellow"),
            parent = busFolder,
        })
        sign:SetAttribute("StopName",  stopData.name)
        sign:SetAttribute("StopIndex", i)
        local gui = Instance.new("BillboardGui")
        gui.Size = UDim2.new(0, 150, 0, 60)
        gui.StudsOffset = Vector3.new(0, 5, 0)
        local lbl = Instance.new("TextLabel")
        lbl.Size  = UDim2.new(1, 0, 1, 0)
        lbl.Text  = "🚌 " .. stopData.name
        lbl.TextColor3 = Color3.new(0, 0, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(255, 230, 50)
        lbl.Font  = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Parent = gui
        gui.Parent = sign
    end
    print("[GameInit] " .. #stops .. " bus stops placed")
end

-- ─── Spawn Points ─────────────────────────────────────────────────────────────
local function createSpawns()
    -- Main spawn for new players near Downtown
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawn then
        spawn = Instance.new("SpawnLocation")
        spawn.Name      = "SpawnLocation"
        spawn.Anchored  = true
        spawn.Size      = Vector3.new(6, 1, 6)
        spawn.CFrame    = CFrame.new(0, 2, 150)
        spawn.BrickColor= BrickColor.new("Bright green")
        spawn.Parent    = Workspace
    else
        spawn.CFrame = CFrame.new(0, 2, 150)
    end
    spawn:SetAttribute("SpawnType", "NewPlayer")
end

-- ─── Ambient Lighting Setup ───────────────────────────────────────────────────
local function setupLighting()
    Lighting.Ambient     = Color3.fromRGB(100, 100, 100)
    Lighting.Brightness  = 2
    Lighting.ClockTime   = 10
    Lighting.FogEnd      = 2000
    Lighting.GlobalShadows = true
    Lighting.OutdoorAmbient= Color3.fromRGB(120, 120, 120)

    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
    sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
    sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
    sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
    sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
    sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
    sky.Parent   = Lighting

    -- Atmosphere for realism
    local atmos = Instance.new("Atmosphere")
    atmos.Density    = 0.3
    atmos.Offset     = 0.25
    atmos.Color      = Color3.fromRGB(199, 170, 140)
    atmos.Decay      = Color3.fromRGB(108, 76,  59)
    atmos.Glare      = 0
    atmos.Haze       = 1.5
    atmos.Parent     = Lighting
    print("[GameInit] Lighting configured")
end

-- ─── Run All Setup ────────────────────────────────────────────────────────────
setupLighting()
createBaseMap()
buildDowntown()
buildIndustrial()
buildSuburbs()
buildWilderness()
placeBusStops()
createSpawns()

-- Tag world as ready
Workspace:SetAttribute("WorldReady", true)
print("[GameInit] ✅ Evergreen County world ready!")
