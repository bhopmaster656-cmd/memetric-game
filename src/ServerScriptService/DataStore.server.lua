--[[
    DataStore.server.lua
    Handles loading and saving all player data via DataStoreService.

    Data schema:
    {
        Coins        = number,
        TotalCaught  = number,
        TotalEarned  = number,
        RebirthLevel = number,
        Inventory    = { [{brainrotId}_{rarityName}] = count, ... },
        Quests       = { [questId] = { Progress=N, Completed=bool, LastReset=tick } },
        LastSpin     = tick (os.time),
        LastDailyReset = tick (os.time),
        Boosts       = { { BoostType=string, Multiplier=number, ExpiresAt=tick } },
        OwnedPacks   = { [packId] = true },
    }
--]]

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local GameConfig       = require(game.ReplicatedStorage.Modules.GameConfig)

local store = DataStoreService:GetDataStore(GameConfig.DATA_STORE_NAME)

-- In-memory cache: [userId] = data table
local cache = {}

local DEFAULT_DATA = {
    Coins           = 0,
    TotalCaught     = 0,
    TotalEarned     = 0,
    RebirthLevel    = 0,
    Inventory       = {},
    Quests          = {},
    LastSpin        = 0,
    LastDailyReset  = 0,
    Boosts          = {},
    OwnedPacks      = {},
}

local function deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function loadData(userId)
    local key = tostring(userId)
    local ok, result = pcall(function()
        return store:GetAsync(key)
    end)
    if ok and result then
        -- Merge with defaults to handle new keys added in updates
        local data = deepCopy(DEFAULT_DATA)
        for k, v in pairs(result) do
            data[k] = v
        end
        return data
    else
        return deepCopy(DEFAULT_DATA)
    end
end

local function saveData(userId)
    local key  = tostring(userId)
    local data = cache[userId]
    if not data then return end
    local ok, err = pcall(function()
        store:SetAsync(key, data)
    end)
    if not ok then
        warn("[DataStore] Failed to save data for", userId, err)
    end
end

-- Public API ─────────────────────────────────────────────────────────────────

local DataStore = {}

function DataStore.Get(userId)
    return cache[userId]
end

function DataStore.Save(userId)
    saveData(userId)
end

-- Player lifecycle ────────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    local data = loadData(player.UserId)
    cache[player.UserId] = data
end)

Players.PlayerRemoving:Connect(function(player)
    saveData(player.UserId)
    cache[player.UserId] = nil
end)

-- Auto-save every 60 seconds
game:GetService("RunService").Heartbeat:Connect(function()
    -- Use a simple timer approach
end)

local function autoSaveLoop()
    while true do
        task.wait(60)
        for userId in pairs(cache) do
            saveData(userId)
        end
    end
end
task.spawn(autoSaveLoop)

-- Bind-to-close safety save
game:BindToClose(function()
    for userId in pairs(cache) do
        saveData(userId)
    end
end)

return DataStore
