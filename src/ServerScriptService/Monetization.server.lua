-- Monetization.server.lua
-- ServerScriptService
-- Handles Roblox Developer Products (cash packs) and Game Passes.
-- Replace the placeholder asset IDs in GameConfig with real IDs from the Creator Dashboard.

local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RS                = game:GetService("ReplicatedStorage")

repeat task.wait(0.1) until _G.PlayerData

local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))
local RE         = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- ── Build lookup tables ───────────────────────────────────────────────────────
local productById  = {}
for _, prod in ipairs(GameConfig.DevProducts) do
    if prod.id ~= 0 then
        productById[prod.id] = prod
    end
end

local passById = {}
for _, pass in ipairs(GameConfig.GamePasses) do
    if pass.id ~= 0 then
        passById[pass.id] = pass
    end
end

-- ── Grant game pass benefits on join ─────────────────────────────────────────
local function applyGamePasses(player)
    local data = _G.PlayerData.get(player)
    if not data then return end

    for passId, pass in pairs(passById) do
        local ok, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
        end)
        if ok and owns then
            if pass.name == "Premium Citizen"  then data.hasPremium       = true end
            if pass.name == "VIP Resident"     then data.hasVIP           = true end
            if pass.name == "Business Tycoon"  then data.hasBusinessTycoon = true end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    task.wait(2)  -- allow DataStore to load first
    applyGamePasses(player)
end)

-- ── Process Developer Product receipts ───────────────────────────────────────
-- Roblox calls this function when a purchase is confirmed.
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        -- Player left; grant next session (simplified: log and PurchaseGranted)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    local prod = productById[receiptInfo.ProductId]
    if not prod then
        warn("[Monetization] Unknown product ID:", receiptInfo.ProductId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    _G.PlayerData.addCash(player, prod.cash)
    RE.Notify:FireClient(player, "Received +$" .. prod.cash .. " (" .. prod.name .. ")!", "success")
    print("[Monetization]", player.Name, "purchased", prod.name, "+$" .. prod.cash)

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

print("[Monetization] Initialized.")
