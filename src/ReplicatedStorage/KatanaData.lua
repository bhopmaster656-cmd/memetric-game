--[[
	KatanaData.lua
	Catalogue of katanas available in the game.
	Each entry defines appearance, sound, and unlock criteria.
]]

local Config = require(script.Parent:WaitForChild("Config"))

local KatanaData = {}

KatanaData.Katanas = {
	NeonBlade = {
		DisplayName = "Neon Blade",
		Description = "The default rider katana. Clean cuts, pure neon.",
		BladeColor = Config.NEON_CYAN,
		TrailColor = Config.NEON_CYAN,
		SlashSoundId = "rbxassetid://0", -- placeholder asset id
		Rarity = "Common",
		UnlockType = "Default",
		Price = 0,
	},
	PurpleHaze = {
		DisplayName = "Purple Haze",
		Description = "Leaves a misty purple trail with every swing.",
		BladeColor = Config.NEON_PURPLE,
		TrailColor = Config.NEON_PURPLE,
		SlashSoundId = "rbxassetid://0",
		Rarity = "Uncommon",
		UnlockType = "Currency",
		Price = 500,
	},
	PinkFury = {
		DisplayName = "Pink Fury",
		Description = "A blade forged in neon fire. Strikes leave a pink blaze.",
		BladeColor = Config.NEON_PINK,
		TrailColor = Config.NEON_PINK,
		SlashSoundId = "rbxassetid://0",
		Rarity = "Rare",
		UnlockType = "Currency",
		Price = 1500,
	},
	GoldenEdge = {
		DisplayName = "Golden Edge",
		Description = "The legendary katana. Blinding golden arcs.",
		BladeColor = Config.NEON_YELLOW,
		TrailColor = Config.NEON_YELLOW,
		SlashSoundId = "rbxassetid://0",
		Rarity = "Legendary",
		UnlockType = "Currency",
		Price = 5000,
	},
	ShadowCutter = {
		DisplayName = "Shadow Cutter",
		Description = "Dark energy radiates from this mysterious blade.",
		BladeColor = Color3.fromRGB(80, 0, 120),
		TrailColor = Color3.fromRGB(80, 0, 120),
		SlashSoundId = "rbxassetid://0",
		Rarity = "Epic",
		UnlockType = "Currency",
		Price = 3000,
	},
}

-- Rarity sort order
KatanaData.RarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
}

-- Rarity colours for UI
KatanaData.RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(46, 204, 113),
	Rare = Color3.fromRGB(52, 152, 219),
	Epic = Color3.fromRGB(155, 89, 182),
	Legendary = Color3.fromRGB(241, 196, 15),
}

function KatanaData.GetKatana(name)
	return KatanaData.Katanas[name]
end

function KatanaData.GetSortedList()
	local list = {}
	for name, data in pairs(KatanaData.Katanas) do
		table.insert(list, {Name = name, Data = data})
	end
	table.sort(list, function(a, b)
		local orderA = KatanaData.RarityOrder[a.Data.Rarity] or 0
		local orderB = KatanaData.RarityOrder[b.Data.Rarity] or 0
		return orderA < orderB
	end)
	return list
end

return KatanaData
