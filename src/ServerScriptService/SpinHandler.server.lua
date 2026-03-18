--[[
    SpinHandler.server.lua
    Manages the daily spin / wheel reward.

    Reward pool (weighted):
        - Coins (small / medium / large)
        - Luck boost (30 minutes)
        - Random Golden brainrot
        - Random Diamond brainrot (rare)
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames  = require(Modules.RemoteEvents)
local GameConfig   = require(Modules.GameConfig)
local RarityConfig = require(Modules.RarityConfig)
local RaritySystem = require(Modules.RaritySystem)

local DataStore    = require(script.Parent.DataStore)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

-- ─── Spin reward table ──────────────────────────────────────────────────────
local SPIN_REWARDS = {
    { Weight = 30, Type = "coins",  Amount = 50,  Label = "50 Coins" },
    { Weight = 25, Type = "coins",  Amount = 150, Label = "150 Coins" },
    { Weight = 15, Type = "coins",  Amount = 500, Label = "500 Coins" },
    { Weight = 10, Type = "coins",  Amount = 1000,Label = "1,000 Coins" },
    { Weight = 10, Type = "boost",  BoostType = "luck", Multiplier = 2,
      DurationMin = 30, Label = "2x Luck (30 min)" },
    { Weight = 7,  Type = "brainrot", Rarity = "Golden",  Label = "Random Golden" },
    { Weight = 3,  Type = "brainrot", Rarity = "Diamond", Label = "Random Diamond" },
}

local TOTAL_WEIGHT = (function()
    local t = 0
    for _, r in ipairs(SPIN_REWARDS) do t = t + r.Weight end
    return t
end)()

local function spinRoll()
    local roll = math.random() * TOTAL_WEIGHT
    local cum  = 0
    for _, r in ipairs(SPIN_REWARDS) do
        cum = cum + r.Weight
        if roll <= cum then return r end
    end
    return SPIN_REWARDS[1]
end

-- ─── Apply reward ────────────────────────────────────────────────────────────
local function applySpinReward(player, reward)
    local data = DataStore.Get(player.UserId)
    if not data then return end

    if reward.Type == "coins" then
        data.Coins = data.Coins + reward.Amount
        local ls = player:FindFirstChild("leaderstats")
        if ls then ls.Coins.Value = data.Coins end
        RE(RemoteNames.UpdateCoins):FireClient(player, data.Coins)

    elseif reward.Type == "boost" then
        local expiry = os.time() + reward.DurationMin * 60
        table.insert(data.Boosts, {
            BoostType  = reward.BoostType,
            Multiplier = reward.Multiplier,
            ExpiresAt  = expiry,
        })

    elseif reward.Type == "brainrot" then
        local brainrot = RaritySystem.PickBrainrot()
        local rarity   = RarityConfig.GetRarity(reward.Rarity)
        local key      = brainrot.Id .. "_" .. rarity.Name
        data.Inventory[key] = (data.Inventory[key] or 0) + 1
        RE(RemoteNames.UpdateInventory):FireClient(player, data.Inventory)
        -- Augment reward info for client display
        reward = {
            Type        = "brainrot",
            BrainrotId  = brainrot.Id,
            BrainrotName= brainrot.Name,
            Rarity      = rarity.Name,
            Label       = rarity.Name .. " " .. brainrot.Name,
        }
    end

    return reward
end

-- ─── Remote handler ──────────────────────────────────────────────────────────
RE(RemoteNames.RequestSpin).OnServerEvent:Connect(function(player)
    local data = DataStore.Get(player.UserId)
    if not data then return end

    local now          = os.time()
    local cooldownSecs = GameConfig.SPIN_COOLDOWN_HOURS * 3600

    if now - (data.LastSpin or 0) < cooldownSecs then
        local remaining = cooldownSecs - (now - data.LastSpin)
        RE(RemoteNames.SpinResult):FireClient(player, {
            Success   = false,
            Reason    = "Spin on cooldown.",
            Remaining = remaining,
        })
        return
    end

    data.LastSpin = now
    local reward  = spinRoll()
    reward        = applySpinReward(player, reward) or reward

    RE(RemoteNames.SpinResult):FireClient(player, {
        Success = true,
        Reward  = reward,
        AllRewards = SPIN_REWARDS,  -- send full table so client can animate wheel
    })
end)
