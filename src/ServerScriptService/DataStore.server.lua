-- DataStore.server.lua
-- ServerScriptService
-- Persists and loads player data using DataStoreService.

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")
local RS               = game:GetService("ReplicatedStorage")

-- During Studio testing DataStoreService can raise errors; guard gracefully.
local playerStore = DataStoreService:GetDataStore("CityLife_v1")

-- In-memory cache: [userId] = playerData table
local cache = {}

-- Default data template for new players
local function defaultData()
    return {
        cash             = 5000,
        job              = nil,
        properties       = {},   -- list of { type, plotId }
        businesses       = {},   -- list of { type, businessId, open }
        lastTaxTime      = os.time(),
        totalEarned      = 0,
        totalSpent       = 0,
        hasPremium       = false,
        hasVIP           = false,
        hasBusinessTycoon = false,
    }
end

-- Safely load data for a player
local function loadData(player)
    local userId = tostring(player.UserId)
    local ok, data = pcall(function()
        return playerStore:GetAsync(userId)
    end)
    if ok and type(data) == "table" then
        -- Merge defaults for any missing keys (handle version upgrades)
        local def = defaultData()
        for k, v in pairs(def) do
            if data[k] == nil then
                data[k] = v
            end
        end
        cache[userId] = data
    else
        cache[userId] = defaultData()
    end
    return cache[userId]
end

-- Safely save data for a player
local function saveData(player)
    local userId = tostring(player.UserId)
    local data   = cache[userId]
    if not data then return end
    local ok, err = pcall(function()
        playerStore:SetAsync(userId, data)
    end)
    if not ok then
        warn("[DataStore] Failed to save data for", player.Name, ":", err)
    end
end

-- ── Public API (accessed via _G so other server scripts can use it) ──────────

_G.PlayerData = {}

function _G.PlayerData.get(player)
    local userId = tostring(player.UserId)
    return cache[userId]
end

function _G.PlayerData.save(player)
    saveData(player)
end

function _G.PlayerData.addCash(player, amount)
    local data = _G.PlayerData.get(player)
    if not data then return end
    data.cash = data.cash + amount
    if amount > 0 then
        data.totalEarned = data.totalEarned + amount
    else
        data.totalSpent = data.totalSpent + math.abs(amount)
    end
    -- Notify client HUD
    local RE = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))
    RE.UpdateHUD:FireClient(player, { cash = data.cash })
end

function _G.PlayerData.getCash(player)
    local data = _G.PlayerData.get(player)
    return data and data.cash or 0
end

-- ── Player lifecycle ──────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    local data = loadData(player)
    -- Push initial HUD update after character loads
    player.CharacterAdded:Connect(function()
        task.wait(1)
        local RE = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))
        RE.UpdateHUD:FireClient(player, { cash = data.cash, job = data.job })
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    saveData(player)
    cache[tostring(player.UserId)] = nil
end)

-- Auto-save every 60 seconds
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            saveData(player)
        end
    end
end)

-- Bind to close (best effort save when server shuts down)
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        saveData(player)
    end
end)

print("[DataStore] Initialized.")
