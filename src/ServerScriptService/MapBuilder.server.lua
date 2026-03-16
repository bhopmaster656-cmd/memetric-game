--[[
	MapBuilder.server.lua
	Builds the static neon cityscape environment around the track.
	Creates skybox lighting, ambient decorations, and the spawn area.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

--------------------------------------------------------------------
-- Lighting / Atmosphere
--------------------------------------------------------------------
Lighting.Ambient = Color3.fromRGB(20, 10, 40)
Lighting.OutdoorAmbient = Color3.fromRGB(30, 15, 50)
Lighting.Brightness = 0.3
Lighting.ClockTime = 22  -- night time
Lighting.FogColor = Color3.fromRGB(10, 5, 25)
Lighting.FogEnd = 800
Lighting.FogStart = 100

-- Atmosphere effect
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.4
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(40, 20, 80)
atmosphere.Decay = Color3.fromRGB(20, 10, 40)
atmosphere.Glare = 0.3
atmosphere.Haze = 2
atmosphere.Parent = Lighting

-- Bloom effect
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.8
bloom.Size = 30
bloom.Threshold = 0.8
bloom.Parent = Lighting

-- Color correction for cyberpunk feel
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Brightness = 0.05
colorCorrection.Contrast = 0.15
colorCorrection.Saturation = 0.3
colorCorrection.TintColor = Color3.fromRGB(200, 180, 255)
colorCorrection.Parent = Lighting

--------------------------------------------------------------------
-- Spawn Platform
--------------------------------------------------------------------
local spawnFolder = Instance.new("Folder")
spawnFolder.Name = "SpawnArea"
spawnFolder.Parent = Workspace

-- Main spawn platform
local spawnPlatform = Utilities.CreateNeonPart(
	Vector3.new(40, 1, 40),
	Config.BG_DARK,
	Vector3.new(0, 0, -10)
)
spawnPlatform.Material = Enum.Material.SmoothPlastic
spawnPlatform.CanCollide = true
spawnPlatform.Name = "SpawnPlatform"
spawnPlatform.Parent = spawnFolder

-- Neon grid lines on spawn platform
for i = -18, 18, 4 do
	local lineX = Utilities.CreateNeonPart(
		Vector3.new(0.15, 0.15, 40),
		Config.NEON_CYAN,
		Vector3.new(i, 0.6, -10)
	)
	lineX.Transparency = 0.5
	lineX.Name = "GridX_" .. tostring(i)
	lineX.Parent = spawnFolder

	local lineZ = Utilities.CreateNeonPart(
		Vector3.new(40, 0.15, 0.15),
		Config.NEON_CYAN,
		Vector3.new(0, 0.6, -10 + i)
	)
	lineZ.Transparency = 0.5
	lineZ.Name = "GridZ_" .. tostring(i)
	lineZ.Parent = spawnFolder
end

-- Spawn point
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Size = Vector3.new(6, 1, 6)
spawnLocation.Position = Vector3.new(0, 1, -10)
spawnLocation.Anchored = true
spawnLocation.CanCollide = true
spawnLocation.Material = Enum.Material.Neon
spawnLocation.Color = Config.NEON_PURPLE
spawnLocation.Transparency = 0.5
spawnLocation.Name = "NeonSpawn"
spawnLocation.Parent = spawnFolder

--------------------------------------------------------------------
-- Background cityscape buildings (decorative)
--------------------------------------------------------------------
local cityFolder = Instance.new("Folder")
cityFolder.Name = "Cityscape"
cityFolder.Parent = Workspace

local buildingColors = {
	Color3.fromRGB(20, 15, 40),
	Color3.fromRGB(25, 20, 45),
	Color3.fromRGB(15, 10, 35),
	Color3.fromRGB(30, 25, 50),
}

local neonAccents = {
	Config.NEON_PURPLE,
	Config.NEON_BLUE,
	Config.NEON_PINK,
	Config.NEON_CYAN,
}

math.randomseed(42) -- deterministic city layout

for side = -1, 1, 2 do
	for i = 1, 30 do
		local x = side * (30 + math.random(5, 50))
		local z = (i - 1) * 40 + math.random(-10, 10)
		local width = math.random(8, 20)
		local depth = math.random(8, 20)
		local height = math.random(20, 80)

		-- Building body
		local building = Utilities.CreateNeonPart(
			Vector3.new(width, height, depth),
			buildingColors[math.random(1, #buildingColors)],
			Vector3.new(x, height / 2, z)
		)
		building.Material = Enum.Material.SmoothPlastic
		building.Transparency = 0.1
		building.Name = "Building_" .. tostring(side) .. "_" .. tostring(i)
		building.Parent = cityFolder

		-- Neon window strips
		local stripCount = math.random(1, 3)
		for s = 1, stripCount do
			local stripHeight = math.random(2, height - 2)
			local accentColor = neonAccents[math.random(1, #neonAccents)]
			local strip = Utilities.CreateNeonPart(
				Vector3.new(width + 0.5, 0.4, 0.4),
				accentColor,
				Vector3.new(x, stripHeight, z + depth / 2 + 0.2)
			)
			strip.Name = "Strip_" .. tostring(s)
			strip.Parent = cityFolder
		end

		-- Rooftop neon light
		if math.random() > 0.5 then
			local roofLight = Utilities.CreateNeonPart(
				Vector3.new(2, 2, 2),
				neonAccents[math.random(1, #neonAccents)],
				Vector3.new(x, height + 1.5, z)
			)
			roofLight.Shape = Enum.PartType.Ball
			roofLight.Name = "RoofLight"
			roofLight.Parent = cityFolder
		end
	end
end

--------------------------------------------------------------------
-- Floor plane (distant ground)
--------------------------------------------------------------------
local ground = Utilities.CreateNeonPart(
	Vector3.new(2000, 1, 2000),
	Config.BG_DARK,
	Vector3.new(0, -1, 500)
)
ground.Material = Enum.Material.SmoothPlastic
ground.CanCollide = true
ground.Name = "GroundPlane"
ground.Parent = Workspace

print("[NEON SLICE] MapBuilder loaded ✓")
