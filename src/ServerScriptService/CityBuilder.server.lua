-- CityBuilder.server.lua
-- ServerScriptService
-- Procedurally builds the city map using BaseParts.
-- Districts: Civic, Residential, Commercial, Industrial, Park, Dealership Row.

-- ── Prevent characters from spawning until the world is fully built ───────────
-- This MUST be the first action in any server script that builds geometry.
-- CharacterAutoLoads is re-enabled at the bottom of this file after all parts
-- have been created, then any waiting players are loaded immediately.
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

local Workspace = game:GetService("Workspace")

-- ── Utility ───────────────────────────────────────────────────────────────────
local function makePart(props)
    local p = Instance.new("BasePart" and props.class or "Part")
    p.Anchored    = true
    p.CanCollide  = true
    p.CastShadow  = true
    for k, v in pairs(props) do
        if k ~= "class" and k ~= "parent" and k ~= "children" then
            p[k] = v
        end
    end
    if props.parent then p.Parent = props.parent end
    return p
end

local function makeModel(name, parent)
    local m  = Instance.new("Model")
    m.Name   = name
    m.Parent = parent
    return m
end

local function addLabel(part, text)
    local bg         = Instance.new("BillboardGui")
    bg.Size          = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset   = Vector3.new(0, part.Size.Y / 2 + 3, 0)
    bg.AlwaysOnTop   = false
    bg.Parent        = part

    local label      = Instance.new("TextLabel")
    label.Size       = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text       = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.Font       = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent     = bg
end

-- ── Map root folders ──────────────────────────────────────────────────────────
local mapFolder   = makeModel("CityMap", Workspace)
local plotsFolder = makeModel("PropertyPlots", Workspace)  -- needed by PropertySystem

-- Locate or create the SpawnLocation.
-- It is embedded as static geometry in the RBXLX; if for any reason it is not
-- present (e.g. older RBXLX format not recognised by the client), we create it
-- dynamically here before any player character is loaded.
local spawnPart = Workspace:FindFirstChild("Spawn")
if not spawnPart then
    spawnPart             = Instance.new("SpawnLocation")
    spawnPart.Name        = "Spawn"
    spawnPart.Size        = Vector3.new(20, 1, 20)
    spawnPart.CFrame      = CFrame.new(0, 1, 0)
    spawnPart.BrickColor  = BrickColor.new("Bright green")
    spawnPart.Material    = Enum.Material.SmoothPlastic
    spawnPart.Neutral     = true
    spawnPart.Duration    = 0
    spawnPart.Anchored    = true
    spawnPart.CanCollide  = true
    spawnPart.Parent      = Workspace
end

-- ── Road helper ───────────────────────────────────────────────────────────────
local function road(x, z, sx, sz)
    return makePart({
        Name       = "Road",
        Size       = Vector3.new(sx, 0.5, sz),
        CFrame     = CFrame.new(x, 0.25, z),
        BrickColor = BrickColor.new("Dark stone grey"),
        Material   = Enum.Material.SmoothPlastic,
        parent     = mapFolder,
    })
end

-- ── Main roads ────────────────────────────────────────────────────────────────
road(0,    0, 2048, 20)   -- East-West main road
road(0,    0, 20, 2048)   -- North-South main road

-- ── District builders ─────────────────────────────────────────────────────────

-- Generic building
local function building(folder, name, cx, cz, sx, sy, sz, color, material, label)
    material  = material  or Enum.Material.SmoothPlastic
    local m   = makeModel(name, folder)
    local p   = makePart({
        Name       = name .. "_Base",
        Size       = Vector3.new(sx, sy, sz),
        CFrame     = CFrame.new(cx, sy / 2, cz),
        BrickColor = BrickColor.new(color),
        Material   = material,
        parent     = m,
    })
    m.PrimaryPart = p
    if label then addLabel(p, label) end
    return m
end

-- Windows stripe
local function windows(folder, cx, cz, sx, sy, sz, floorH, offsetY)
    for y = floorH, sy - floorH, floorH do
        makePart({
            Name        = "Window",
            Size        = Vector3.new(sx + 0.2, 1.5, sz + 0.2),
            CFrame      = CFrame.new(cx, offsetY + y, cz),
            BrickColor  = BrickColor.new("Bright blue"),
            Material    = Enum.Material.Glass,
            Transparency = 0.4,
            parent      = folder,
        })
    end
end

-- ── 1. CIVIC DISTRICT ─────────────────────────────────────────────────────────
local civicFolder = makeModel("CivicDistrict", mapFolder)

-- Fire Station
local fsModel = building(civicFolder, "FireStation", -300, -300, 40, 20, 30, "Bright red", Enum.Material.SmoothPlastic, "🔥 Fire Station")
building(civicFolder, "FireStation_Tower", -300, -300, 8, 40, 8, "Bright red", Enum.Material.SmoothPlastic)

-- Police Station
building(civicFolder, "PoliceStation", -200, -300, 40, 20, 30, "Bright blue", Enum.Material.SmoothPlastic, "🚓 Police Station")

-- Hospital
local hospModel = building(civicFolder, "Hospital", -100, -300, 50, 30, 40, "White", Enum.Material.SmoothPlastic, "🏥 Hospital")
windows(civicFolder, -100, -300, 50, 30, 40, 5, 1)

-- School
building(civicFolder, "School", 50, -300, 60, 18, 50, "Bright yellow", Enum.Material.SmoothPlastic, "🏫 School")

-- City Hall
local hallModel = building(civicFolder, "CityHall", 200, -300, 50, 25, 40, "Light stone grey", Enum.Material.Marble, "🏛️ City Hall")

-- Courthouse
building(civicFolder, "Courthouse", 320, -300, 40, 22, 35, "Sand yellow", Enum.Material.Marble, "⚖️ Courthouse")

-- ── 2. RESIDENTIAL DISTRICT ───────────────────────────────────────────────────
local resFolder   = makeModel("ResidentialDistrict", mapFolder)
local plotSeq     = 0

local function residentialPlot(cx, cz, propType, model)
    plotSeq = plotSeq + 1
    local plotId = "plot_" .. plotSeq

    local plot = makePart({
        Name        = plotId,
        Size        = Vector3.new(model.x, 0.3, model.z),
        CFrame      = CFrame.new(cx, 0.15, cz),
        BrickColor  = BrickColor.new("Bright green"),
        Material    = Enum.Material.SmoothPlastic,
        Transparency = 0.6,
        parent       = plotsFolder,
    })

    local tv = Instance.new("StringValue")
    tv.Name  = "PropertyType"
    tv.Value = propType
    tv.Parent = plot

    local ov = Instance.new("StringValue")
    ov.Name  = "Owned"
    ov.Value = ""
    ov.Parent = plot

    return plot
end

-- Studio apartments (small blocks, 4-story)
local function studio(cx, cz)
    residentialPlot(cx, cz, "studio", {x=20, z=20})
    building(resFolder, "Studio_"..plotSeq, cx, cz, 20, 16, 20, "Pastel brown", Enum.Material.SmoothPlastic)
end

-- Houses
local function house(cx, cz)
    residentialPlot(cx, cz, "house", {x=30, z=25})
    building(resFolder, "House_"..plotSeq, cx, cz, 30, 12, 25, "Bright orange", Enum.Material.SmoothPlastic, "🏠 House")
    -- Roof
    makePart({
        Name       = "Roof_"..plotSeq,
        Size       = Vector3.new(34, 6, 29),
        CFrame     = CFrame.new(cx, 12 + 3, cz) * CFrame.Angles(0, 0, math.rad(45)),
        BrickColor = BrickColor.new("Dark orange"),
        Material   = Enum.Material.SmoothPlastic,
        parent     = resFolder,
    })
end

-- Apartments (tall)
local function apartment(cx, cz)
    residentialPlot(cx, cz, "apartment", {x=25, z=25})
    local h = 45
    building(resFolder, "Apartment_"..plotSeq, cx, cz, 25, h, 25, "Light stone grey", Enum.Material.SmoothPlastic, "🏢 Apartment")
    windows(resFolder, cx, cz, 25, h, 25, 5, 1)
end

-- Mansions (large)
local function mansion(cx, cz)
    residentialPlot(cx, cz, "mansion", {x=70, z=60})
    building(resFolder, "Mansion_"..plotSeq, cx, cz, 70, 20, 60, "Pearl", Enum.Material.Marble, "🏰 Mansion")
    -- Front pillars
    for i = -2, 2 do
        makePart({
            Name   = "Pillar",
            Size   = Vector3.new(3, 22, 3),
            CFrame = CFrame.new(cx + i * 12, 11, cz - 32),
            BrickColor = BrickColor.new("White"),
            Material   = Enum.Material.Marble,
            parent     = resFolder,
        })
    end
end

-- Lay out residential grid
local startX, startZ = -600, 50
for row = 0, 3 do
    for col = 0, 5 do
        local cx = startX + col * 55
        local cz = startZ + row * 60
        if row == 0 then studio(cx, cz)
        elseif row == 1 then house(cx, cz)
        elseif row == 2 then apartment(cx, cz)
        else mansion(cx, cz) end
    end
end

-- ── 3. COMMERCIAL DISTRICT ────────────────────────────────────────────────────
local commFolder = makeModel("CommercialDistrict", mapFolder)

local shops = {
    { name="GroceryStore",   label="🛒 Grocery Store",   color="Medium green",     x=40, y=18, z=35 },
    { name="Restaurant",     label="🍽️ Restaurant",      color="Bright red",       x=35, y=15, z=30 },
    { name="CoffeeShop",     label="☕ Coffee Shop",      color="Reddish brown",    x=25, y=12, z=25 },
    { name="ClothingStore",  label="👗 Clothing Store",   color="Hot pink",         x=30, y=14, z=28 },
    { name="Pharmacy",       label="💊 Pharmacy",         color="White",            x=30, y=14, z=28 },
    { name="Bank",           label="🏦 Bank",             color="Gold",             x=45, y=22, z=40 },
    { name="Mall",           label="🛍️ Shopping Mall",   color="Linen",            x=80, y=25, z=70 },
}

for i, s in ipairs(shops) do
    local cx = 100 + (i - 1) * 100
    local cz = -50
    building(commFolder, s.name, cx, cz, s.x, s.y, s.z, s.color, Enum.Material.SmoothPlastic, s.label)
    road(cx, cz + s.z/2 + 10, s.x + 10, 20)
end

-- ── 4. INDUSTRIAL DISTRICT ────────────────────────────────────────────────────
local indFolder  = makeModel("IndustrialDistrict", mapFolder)

local function autoRepairShop(cx, cz, idx)
    local bz = makeModel("AutoRepairShop_"..idx, indFolder)
    makePart({ Name="Floor",  Size=Vector3.new(40,1,35), CFrame=CFrame.new(cx, 0.5, cz), BrickColor=BrickColor.new("Medium stone grey"), Material=Enum.Material.Concrete, parent=bz })
    makePart({ Name="Walls",  Size=Vector3.new(40,15,35), CFrame=CFrame.new(cx, 8, cz), BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.Metal, Transparency=0, parent=bz })
    makePart({ Name="Sign",   Size=Vector3.new(30,5,1),   CFrame=CFrame.new(cx, 16, cz-17), BrickColor=BrickColor.new("Bright red"),   Material=Enum.Material.Neon,   parent=bz })
    addLabel(bz:FindFirstChildWhichIsA("BasePart", true), "🔧 Auto Repair Shop")
end

for i = 1, 4 do
    autoRepairShop(-400 + (i-1)*90, 200, i)
end

-- Gas Stations
for i = 1, 3 do
    local cx = -400 + (i-1)*100
    local cz = 320
    local gs = makeModel("GasStation_"..i, indFolder)
    makePart({ Name="Canopy",  Size=Vector3.new(30,4,20), CFrame=CFrame.new(cx, 10, cz), BrickColor=BrickColor.new("Bright yellow"), Material=Enum.Material.SmoothPlastic, parent=gs })
    makePart({ Name="Building",Size=Vector3.new(12,8,10), CFrame=CFrame.new(cx, 4, cz),  BrickColor=BrickColor.new("White"),        Material=Enum.Material.SmoothPlastic, parent=gs })
    makePart({ Name="Pump1",   Size=Vector3.new(2,5,1),   CFrame=CFrame.new(cx-8, 2.5, cz-5), BrickColor=BrickColor.new("Medium green"), Material=Enum.Material.Metal, parent=gs })
    makePart({ Name="Pump2",   Size=Vector3.new(2,5,1),   CFrame=CFrame.new(cx+8, 2.5, cz-5), BrickColor=BrickColor.new("Medium green"), Material=Enum.Material.Metal, parent=gs })
    addLabel(gs:FindFirstChildWhichIsA("BasePart", true), "⛽ Gas Station")
end

-- ── 5. CAR DEALERSHIP ROW ─────────────────────────────────────────────────────
local dealFolder = makeModel("DealershipRow", mapFolder)

local dealerships = {
    { name="SpeedMotors",    color="Bright red",   label="🚗 Speed Motors" },
    { name="LuxuryCars",     color="Gold",         label="🏎️ Luxury Cars" },
    { name="FamilyAutos",    color="Bright blue",  label="🚙 Family Autos" },
}

for i, d in ipairs(dealerships) do
    local cx = 400 + (i-1)*150
    local cz = -200
    local dm = makeModel(d.name, dealFolder)
    -- Showroom
    makePart({ Name="Showroom", Size=Vector3.new(60,16,50), CFrame=CFrame.new(cx, 8, cz), BrickColor=BrickColor.new(d.color), Material=Enum.Material.Glass, Transparency=0.3, parent=dm })
    -- Lot
    makePart({ Name="Lot",      Size=Vector3.new(120,0.5,80), CFrame=CFrame.new(cx, 0.25, cz+60), BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.Concrete, parent=dm })
    addLabel(dm:FindFirstChildWhichIsA("BasePart", true), d.label)
end

-- ── 6. PARK DISTRICT ─────────────────────────────────────────────────────────
local parkFolder = makeModel("ParkDistrict", mapFolder)

-- Main park
makePart({ Name="ParkGround", Size=Vector3.new(200,0.5,180), CFrame=CFrame.new(300, 0.25, 200), BrickColor=BrickColor.new("Bright green"), Material=Enum.Material.Grass, parent=parkFolder })

-- Trees (cylinders + spheres)
local function tree(cx, cz)
    makePart({ Name="Trunk", Size=Vector3.new(3,10,3),  CFrame=CFrame.new(cx, 5, cz),  BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.Wood,  Shape=Enum.PartType.Cylinder, parent=parkFolder })
    makePart({ Name="Leaves",Size=Vector3.new(10,10,10), CFrame=CFrame.new(cx, 14, cz), BrickColor=BrickColor.new("Bright green"),  Material=Enum.Material.Grass, Shape=Enum.PartType.Ball,     parent=parkFolder })
end

local treePositions = {
    {260,160},{340,160},{260,240},{340,240},{300,200},
    {280,180},{320,180},{280,220},{320,220},{300,170},
    {270,200},{330,200},{300,230},
}
for _, pos in ipairs(treePositions) do tree(pos[1], pos[2]) end

-- Fountain
makePart({ Name="FountainBase", Size=Vector3.new(12,2,12), CFrame=CFrame.new(300, 1, 200), BrickColor=BrickColor.new("Light stone grey"), Material=Enum.Material.Marble,    Shape=Enum.PartType.Cylinder, parent=parkFolder })
makePart({ Name="FountainWater",Size=Vector3.new(8,1,8),   CFrame=CFrame.new(300, 2.5,200), BrickColor=BrickColor.new("Bright blue"),      Material=Enum.Material.Neon,     Transparency=0.3, Shape=Enum.PartType.Cylinder, parent=parkFolder })

-- Park benches
local function bench(cx, cz)
    makePart({ Name="Bench_Seat", Size=Vector3.new(6,0.5,2),  CFrame=CFrame.new(cx, 1.5, cz), BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.Wood, parent=parkFolder })
    makePart({ Name="Bench_Back", Size=Vector3.new(6,1.5,0.5),CFrame=CFrame.new(cx, 2.5, cz-0.8), BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.Wood, parent=parkFolder })
end
bench(280, 170) bench(320, 170) bench(280, 230) bench(320, 230)

-- Playground
makePart({ Name="PlaySurface", Size=Vector3.new(30,0.5,25), CFrame=CFrame.new(380, 0.25, 200), BrickColor=BrickColor.new("Sand yellow"), Material=Enum.Material.Sand, parent=parkFolder })
-- Slide
makePart({ Name="Slide", Size=Vector3.new(3,8,12), CFrame=CFrame.new(380, 4, 200) * CFrame.Angles(math.rad(30),0,0), BrickColor=BrickColor.new("Bright red"), Material=Enum.Material.SmoothPlastic, parent=parkFolder })

-- Community garden
makePart({ Name="GardenBed1", Size=Vector3.new(15,0.5,8), CFrame=CFrame.new(220, 0.25, 200), BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.Mud, parent=parkFolder })
makePart({ Name="GardenBed2", Size=Vector3.new(15,0.5,8), CFrame=CFrame.new(220, 0.25, 215), BrickColor=BrickColor.new("Reddish brown"), Material=Enum.Material.Mud, parent=parkFolder })

-- ── 7. WELCOME SIGN ──────────────────────────────────────────────────────────
addLabel(spawnPart, "🏙️ Welcome to CityLife!")

-- ── 8. STREET LIGHTS ─────────────────────────────────────────────────────────
local function streetLight(cx, cz)
    local pole = makePart({ Name="Pole",   Size=Vector3.new(1,15,1),  CFrame=CFrame.new(cx, 7.5, cz), BrickColor=BrickColor.new("Dark stone grey"), Material=Enum.Material.Metal,        parent=mapFolder })
    local bulb = makePart({ Name="Light",  Size=Vector3.new(2,2,2),   CFrame=CFrame.new(cx, 16, cz),  BrickColor=BrickColor.new("Bright yellow"),   Material=Enum.Material.Neon,         parent=mapFolder })
    local pt   = Instance.new("PointLight")
    pt.Range      = 30
    pt.Brightness = 3
    pt.Color      = Color3.new(1, 0.95, 0.8)
    pt.Parent     = bulb
end

for i = -10, 10 do streetLight(i * 80, -12) end
for i = -10, 10 do streetLight(i * 80,  12) end
for i = -10, 10 do streetLight(-12, i * 80) end
for i = -10, 10 do streetLight( 12, i * 80) end

print("[CityBuilder] City generated.")

-- ── Re-enable character loading now that the world is ready ───────────────────
-- Any player who joined while the world was being built gets loaded now.
-- Future players are handled by the PlayerAdded connection below.
Players.CharacterAutoLoads = true

for _, player in ipairs(Players:GetPlayers()) do
    if not player.Character then
        player:LoadCharacter()
    end
end

Players.PlayerAdded:Connect(function(player)
    player:LoadCharacter()
end)

print("[CityBuilder] Character loading enabled.")
