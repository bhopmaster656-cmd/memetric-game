-- TaxSystem.server.lua
-- ServerScriptService
-- Collects periodic property and business taxes; evicts players who cannot pay.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

repeat task.wait(0.1) until _G.PlayerData

local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))
local RE         = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function findPropertyConfig(propId)
    for _, p in ipairs(GameConfig.Properties) do
        if p.id == propId then return p end
    end
    return nil
end

local function findBizConfig(bizId)
    for _, b in ipairs(GameConfig.Businesses) do
        if b.id == bizId then return b end
    end
    return nil
end

-- ── Tax collection ────────────────────────────────────────────────────────────
local function collectTaxes()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = _G.PlayerData.get(player)
        if not data then continue end

        local totalTax = 0

        -- Property taxes
        for _, entry in ipairs(data.properties) do
            local prop = findPropertyConfig(entry.type)
            if prop then
                totalTax = totalTax + math.ceil(prop.price * prop.taxRate)
            end
        end

        -- Business taxes
        for _, entry in ipairs(data.businesses) do
            local biz = findBizConfig(entry.type)
            if biz then
                -- Tax based on one interval's worth of revenue
                local intervalRevenue = biz.incomePerMin * (GameConfig.TaxInterval / 60)
                totalTax = totalTax + math.ceil(intervalRevenue * biz.taxRate)
            end
        end

        if totalTax == 0 then continue end

        if data.cash >= totalTax then
            _G.PlayerData.addCash(player, -totalTax)
            RE.Notify:FireClient(player, "Property/Business tax paid: -$" .. totalTax, "tax")
        else
            -- Cannot pay – forfeit last property or business (eviction)
            local forfeited = false

            -- Try forfeiting a business first
            if #data.businesses > 0 then
                local entry = table.remove(data.businesses)
                local biz   = findBizConfig(entry.type)
                RE.Notify:FireClient(
                    player,
                    "Cannot pay taxes! Your " .. (biz and biz.name or "business") .. " was seized.",
                    "eviction"
                )
                forfeited = true
            elseif #data.properties > 0 then
                local entry = table.remove(data.properties)
                local prop  = findPropertyConfig(entry.type)
                RE.Notify:FireClient(
                    player,
                    "Cannot pay taxes! Your " .. (prop and prop.name or "property") .. " was seized.",
                    "eviction"
                )
                forfeited = true
            end

            if not forfeited then
                -- No assets to forfeit – deduct whatever cash remains
                _G.PlayerData.addCash(player, -data.cash)
                RE.Notify:FireClient(player, "You were fined for unpaid taxes!", "eviction")
            end
        end

        data.lastTaxTime = os.time()
    end
end

-- ── Tax loop ──────────────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(GameConfig.TaxInterval)
        collectTaxes()
        print("[TaxSystem] Tax cycle completed.")
    end
end)

print("[TaxSystem] Initialized.")
