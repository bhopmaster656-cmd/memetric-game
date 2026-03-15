--[[
	DistrictData.lua
	Definitions for the city districts that guilds can capture.
]]

local Config = require(script.Parent:WaitForChild("Config"))

local DistrictData = {}

DistrictData.Districts = {
	Newtown = {
		DisplayName = "Newtown",
		Description = "The neon-lit starting district. Friendly streets and easy runs.",
		ThemeColor = Config.NEON_CYAN,
		Position = Vector3.new(0, 0, 0),
		Difficulty = 1,
		CaptureThreshold = Config.DISTRICT_CAPTURE_ENERGY,
		BonusXP = Config.DISTRICT_BONUS_XP,
	},
	Downtown = {
		DisplayName = "Downtown",
		Description = "Towering skyscrapers and dense traffic. Fast runs, tight lanes.",
		ThemeColor = Config.NEON_PURPLE,
		Position = Vector3.new(500, 0, 0),
		Difficulty = 2,
		CaptureThreshold = Config.DISTRICT_CAPTURE_ENERGY * 1.5,
		BonusXP = Config.DISTRICT_BONUS_XP + 0.1,
	},
	IndustrialZone = {
		DisplayName = "Industrial Zone",
		Description = "Gritty factories and grinding gears. Hazard blocks appear more often.",
		ThemeColor = Config.NEON_YELLOW,
		Position = Vector3.new(0, 0, 500),
		Difficulty = 3,
		CaptureThreshold = Config.DISTRICT_CAPTURE_ENERGY * 2,
		BonusXP = Config.DISTRICT_BONUS_XP + 0.2,
	},
	NeonHeights = {
		DisplayName = "Neon Heights",
		Description = "The highest rooftops of the city. Only the elite ride here.",
		ThemeColor = Config.NEON_PINK,
		Position = Vector3.new(500, 0, 500),
		Difficulty = 4,
		CaptureThreshold = Config.DISTRICT_CAPTURE_ENERGY * 2.5,
		BonusXP = Config.DISTRICT_BONUS_XP + 0.3,
	},
	TheCore = {
		DisplayName = "The Core",
		Description = "The beating heart of the city. Maximum speed, maximum glory.",
		ThemeColor = Color3.fromRGB(255, 0, 100),
		Position = Vector3.new(250, 0, 250),
		Difficulty = 5,
		CaptureThreshold = Config.DISTRICT_CAPTURE_ENERGY * 3,
		BonusXP = Config.DISTRICT_BONUS_XP + 0.5,
	},
}

function DistrictData.GetDistrict(name)
	return DistrictData.Districts[name]
end

function DistrictData.GetAllNames()
	local names = {}
	for name in pairs(DistrictData.Districts) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return DistrictData
