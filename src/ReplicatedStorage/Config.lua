--[[
	Config.lua
	Shared configuration constants for NEON SLICE.
	Accessed by both server and client scripts.
]]

local Config = {}

-- Game identity
Config.GAME_NAME = "NEON SLICE"
Config.VERSION = "1.0.0"

-- Track / runner settings
Config.BASE_SPEED = 80            -- studs per second while running
Config.MAX_SPEED = 160            -- maximum speed after boosts
Config.SPEED_BOOST_AMOUNT = 20    -- speed gained per perfect slice
Config.SPEED_LOSS_ON_HIT = 30     -- speed lost when hit by a block
Config.LANE_COUNT = 3             -- left / center / right
Config.LANE_WIDTH = 8             -- studs between lane centres
Config.TRACK_SEGMENT_LENGTH = 200 -- studs per procedural segment

-- Block spawning
Config.BLOCK_SPAWN_DISTANCE = 150 -- studs ahead of the player
Config.BLOCK_MIN_INTERVAL = 0.4   -- seconds between blocks at base speed
Config.BLOCK_MAX_INTERVAL = 1.2
Config.BLOCK_SIZE = Vector3.new(4, 4, 1)
Config.SLICE_LINE_TOLERANCE = 2.5 -- studs of allowed error for a cut

-- Scoring
Config.POINTS_PER_SLICE = 10
Config.COMBO_MULTIPLIER_STEP = 5  -- every N consecutive slices increases multiplier
Config.MAX_COMBO_MULTIPLIER = 8
Config.ENERGY_PER_SLICE = 1

-- Raid settings
Config.RAID_TEAM_SIZE = 3         -- players per team (3v3)
Config.RAID_DURATION = 120        -- seconds
Config.RAID_QUEUE_TIMEOUT = 60    -- seconds to wait for match

-- District settings
Config.DISTRICT_CAPTURE_ENERGY = 500 -- total energy needed to capture a district
Config.DISTRICT_BONUS_XP = 1.25       -- 25 percent XP bonus for owning a district

-- Katana defaults
Config.DEFAULT_KATANA = "NeonBlade"

-- Trail settings
Config.TRAIL_LIFETIME = 0.5
Config.TRAIL_MIN_LENGTH = 0.1

-- Camera
Config.CAMERA_OFFSET = Vector3.new(0, 12, -18)
Config.CAMERA_FOV = 75

-- Colours (cyberpunk palette)
Config.NEON_PURPLE = Color3.fromRGB(155, 89, 182)
Config.NEON_BLUE   = Color3.fromRGB(52, 152, 219)
Config.NEON_PINK   = Color3.fromRGB(255, 71, 148)
Config.NEON_CYAN   = Color3.fromRGB(0, 255, 255)
Config.NEON_YELLOW = Color3.fromRGB(241, 196, 15)
Config.BG_DARK     = Color3.fromRGB(15, 15, 30)

return Config
