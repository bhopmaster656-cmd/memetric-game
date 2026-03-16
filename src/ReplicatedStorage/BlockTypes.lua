--[[
	BlockTypes.lua
	Definitions for the neon blocks that fly towards the player.
	Each type specifies visual properties and slice behaviour.
]]

local Config = require(script.Parent:WaitForChild("Config"))

local BlockTypes = {}

BlockTypes.Types = {
	Standard = {
		Name = "Standard",
		Color = Config.NEON_PURPLE,
		Points = Config.POINTS_PER_SLICE,
		Energy = Config.ENERGY_PER_SLICE,
		Size = Config.BLOCK_SIZE,
		SliceDirection = "Any", -- horizontal, vertical, diagonal, or any
		Material = Enum.Material.Neon,
		SpawnWeight = 50,
	},
	Horizontal = {
		Name = "Horizontal",
		Color = Config.NEON_BLUE,
		Points = Config.POINTS_PER_SLICE * 1.5,
		Energy = Config.ENERGY_PER_SLICE,
		Size = Vector3.new(6, 2, 1),
		SliceDirection = "Horizontal",
		Material = Enum.Material.Neon,
		SpawnWeight = 20,
	},
	Vertical = {
		Name = "Vertical",
		Color = Config.NEON_PINK,
		Points = Config.POINTS_PER_SLICE * 1.5,
		Energy = Config.ENERGY_PER_SLICE,
		Size = Vector3.new(2, 6, 1),
		SliceDirection = "Vertical",
		Material = Enum.Material.Neon,
		SpawnWeight = 20,
	},
	Bonus = {
		Name = "Bonus",
		Color = Config.NEON_YELLOW,
		Points = Config.POINTS_PER_SLICE * 3,
		Energy = Config.ENERGY_PER_SLICE * 3,
		Size = Vector3.new(3, 3, 1),
		SliceDirection = "Any",
		Material = Enum.Material.Neon,
		SpawnWeight = 8,
	},
	Hazard = {
		Name = "Hazard",
		Color = Color3.fromRGB(255, 50, 50),
		Points = 0,
		Energy = 0,
		Size = Vector3.new(4, 4, 1),
		SliceDirection = "None", -- must be dodged, not sliced
		Material = Enum.Material.Neon,
		SpawnWeight = 10,
	},
}

-- Weighted random selection helper
function BlockTypes.GetRandomType()
	local totalWeight = 0
	for _, data in pairs(BlockTypes.Types) do
		totalWeight = totalWeight + data.SpawnWeight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for name, data in pairs(BlockTypes.Types) do
		cumulative = cumulative + data.SpawnWeight
		if roll <= cumulative then
			return name, data
		end
	end

	-- Fallback
	return "Standard", BlockTypes.Types.Standard
end

return BlockTypes
