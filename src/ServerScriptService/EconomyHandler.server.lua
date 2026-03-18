--[[
    EconomyHandler.server.lua
    Handles DevProduct (Robux coin pack) purchases and fires UpdateCoins.
--]]

local MarketplaceService  = game:GetService("MarketplaceService")
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(Modules.RemoteEvents)
local GameConfig  = require(Modules.GameConfig)

local DataStore   = require(script.Parent.DataStore)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

-- ─── DevProduct purchase handler ─────────────────────────────────────────────
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        -- Player left; grant on next join via retry
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local data = DataStore.Get(player.UserId)
    if not data then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local amount = GameConfig.COIN_PACKAGES[receiptInfo.ProductId]
    if amount then
        data.Coins = data.Coins + amount
        local ls = player:FindFirstChild("leaderstats")
        if ls then ls.Coins.Value = data.Coins end
        RE(RemoteNames.UpdateCoins):FireClient(player, data.Coins)
        DataStore.Save(player.UserId)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    -- Unknown product – do not double-grant
    return Enum.ProductPurchaseDecision.PurchaseGranted
end
