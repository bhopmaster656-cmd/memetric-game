--[[
    FishingHandler.server.lua
    Server-side fishing logic.

    Flow:
        1. Client fires CastRod.
        2. Server waits a random bite delay, then fires BiteAlert to that client.
        3. Client has REEL_WINDOW seconds to fire ReelIn.
        4. If ReelIn arrives in time → SimulateCatch, reward player, fire CatchResult.
        5. If timeout → fire CatchResult with Success=false.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules        = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames    = require(Modules.RemoteEvents)
local FishingSystem  = require(Modules.FishingSystem)
local GameConfig     = require(Modules.GameConfig)

local DataStore      = require(script.Parent.DataStore)
local QuestHandler   = require(script.Parent.QuestHandler)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

local function RE(name) return reFolder:WaitForChild(name) end

-- Track active casts: [player] = { biteTime, reaped }
local activeCasts = {}

-- Helpers ─────────────────────────────────────────────────────────────────────

local function getLuckMultiplier(data)
    local base  = 1 + (data.RebirthLevel * GameConfig.REBIRTH_LUCK_BONUS)
    -- Add active luck boosts
    local now = os.time()
    for _, boost in ipairs(data.Boosts or {}) do
        if boost.BoostType == "luck" and boost.ExpiresAt > now then
            base = base * boost.Multiplier
        end
    end
    return base
end

local function getCoinMultiplier(data, hasVIP, hasCoinDoubler)
    local base = 1 + (data.RebirthLevel * GameConfig.REBIRTH_COIN_BONUS)
    if hasVIP then
        base = base + GameConfig.VIP_COIN_BONUS
    end
    if hasCoinDoubler then
        base = base * 2
    end
    return base
end

local function hasGamepass(player, gamepassId)
    if gamepassId == 0 then return false end
    local ok, result = pcall(function()
        return game:GetService("MarketplaceService"):UserOwnsGamePassAsync(
            player.UserId, gamepassId
        )
    end)
    return ok and result
end

local function rewardCatch(player, result)
    local data = DataStore.Get(player.UserId)
    if not data then return end

    -- Add to inventory
    local key = result.brainrot.Id .. "_" .. result.rarity.Name
    data.Inventory[key] = (data.Inventory[key] or 0) + 1

    -- Award coins
    data.Coins       = data.Coins       + result.coins
    data.TotalCaught = data.TotalCaught + 1
    data.TotalEarned = data.TotalEarned + result.coins

    -- Update leaderstats
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        ls.Coins.Value   = data.Coins
        ls.Caught.Value  = data.TotalCaught
    end

    -- Notify client
    RE(RemoteNames.UpdateCoins):FireClient(player, data.Coins)
    RE(RemoteNames.UpdateInventory):FireClient(player, data.Inventory)

    -- Quest progress
    QuestHandler.OnCatch(player, result.brainrot.Id, result.rarity.Name, result.coins)
end

-- Cast handler ────────────────────────────────────────────────────────────────

RE(RemoteNames.CastRod).OnServerEvent:Connect(function(player)
    if activeCasts[player] then return end  -- already casting

    local data = DataStore.Get(player.UserId)
    if not data then return end

    activeCasts[player] = { reaped = false }

    -- Determine multipliers
    local vip         = hasGamepass(player, GameConfig.VIP_GAMEPASS_ID)
    local luck        = getLuckMultiplier(data)
        + (vip and GameConfig.VIP_LUCK_BONUS or 0)
    local coinMult    = getCoinMultiplier(data, vip, false)

    -- Wait for bite
    local delay = FishingSystem.GetBiteDelay()
    task.wait(delay)

    if not activeCasts[player] then return end  -- cast cancelled

    -- Send bite alert
    RE(RemoteNames.BiteAlert):FireClient(player)

    -- Wait for reel
    local reeled = false
    local reelConn
    reelConn = RE(RemoteNames.ReelIn).OnServerEvent:Connect(function(p)
        if p == player then
            reeled = true
            reelConn:Disconnect()
        end
    end)

    task.wait(GameConfig.REEL_WINDOW)
    reelConn:Disconnect()

    activeCasts[player] = nil

    if reeled then
        local result = FishingSystem.SimulateCatch(luck, coinMult)
        rewardCatch(player, result)
        RE(RemoteNames.CatchResult):FireClient(player, {
            Success  = true,
            Brainrot = result.brainrot,
            Rarity   = result.rarity.Name,
            Coins    = result.coins,
        })
    else
        RE(RemoteNames.CatchResult):FireClient(player, { Success = false })
    end
end)

-- Cancel handler ──────────────────────────────────────────────────────────────
RE(RemoteNames.CancelCast).OnServerEvent:Connect(function(player)
    activeCasts[player] = nil
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
    activeCasts[player] = nil
end)
