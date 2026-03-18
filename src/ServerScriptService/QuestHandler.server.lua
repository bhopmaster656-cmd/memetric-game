--[[
    QuestHandler.server.lua
    Tracks and completes quests for every player.

    Called by FishingHandler after each catch.
    Called by MainHandler on player join to send initial quest state.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames  = require(Modules.RemoteEvents)
local QuestConfig  = require(Modules.QuestConfig)
local GameConfig   = require(Modules.GameConfig)

local DataStore    = require(script.Parent.DataStore)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local QuestHandler = {}

-- Reset daily quests if the 24h window has elapsed ───────────────────────────
local function checkDailyReset(data)
    local now  = os.time()
    local diff = now - (data.LastDailyReset or 0)
    if diff >= GameConfig.DAILY_RESET_HOURS * 3600 then
        data.LastDailyReset = now
        for _, q in ipairs(QuestConfig.QUESTS) do
            if q.ResetType == "daily" then
                if data.Quests[q.Id] then
                    data.Quests[q.Id].Progress  = 0
                    data.Quests[q.Id].Completed = false
                end
            end
        end
    end
end

-- Send updated quest state to client ─────────────────────────────────────────
local function syncQuests(player)
    local data = DataStore.Get(player.UserId)
    if not data then return end
    RE(RemoteNames.UpdateQuests):FireClient(player, data.Quests)
end

-- Advance progress on matching quests ────────────────────────────────────────
function QuestHandler.OnCatch(player, brainrotId, rarityName, coinsEarned)
    local data = DataStore.Get(player.UserId)
    if not data then return end

    checkDailyReset(data)

    for _, q in ipairs(QuestConfig.QUESTS) do
        local qd = data.Quests[q.Id]
        if not qd then
            qd = { Progress = 0, Completed = false, LastReset = 0 }
            data.Quests[q.Id] = qd
        end

        if not qd.Completed then
            -- Increment based on quest type
            local increment = 0
            if q.Type == "catch_total" then
                increment = 1
            elseif q.Type == "catch_rarity" and rarityName == q.RarityName then
                increment = 1
            elseif q.Type == "catch_type" and brainrotId == q.BrainrotId then
                increment = 1
            elseif q.Type == "earn_coins" then
                increment = coinsEarned
            end

            qd.Progress = qd.Progress + increment

            if qd.Progress >= q.Goal then
                qd.Progress  = q.Goal
                qd.Completed = true

                -- Grant reward
                data.Coins = data.Coins + (q.Reward.Coins or 0)

                local ls = player:FindFirstChild("leaderstats")
                if ls then
                    ls.Coins.Value = data.Coins
                end
                RE(RemoteNames.UpdateCoins):FireClient(player, data.Coins)
                RE(RemoteNames.QuestComplete):FireClient(player, q.Id, q.Reward)
            end
        end
    end

    syncQuests(player)
end

-- Send quests on join ─────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)  -- wait for DataStore cache to be populated
    local data = DataStore.Get(player.UserId)
    if data then
        checkDailyReset(data)
        -- Ensure all quest entries exist
        for _, q in ipairs(QuestConfig.QUESTS) do
            if not data.Quests[q.Id] then
                data.Quests[q.Id] = { Progress = 0, Completed = false, LastReset = 0 }
            end
        end
        syncQuests(player)
    end
end)

return QuestHandler
