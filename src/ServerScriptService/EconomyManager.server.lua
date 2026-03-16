-- ServerScriptService/EconomyManager.server.lua
-- Handles the player market, government store purchases/sales, auctions,
-- tax collection, and dynamic pricing.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local EconomyModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EconomyModule"))
local ItemData      = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PurchaseItem       = RemoteEvents:WaitForChild("PurchaseItem")
local SellItem           = RemoteEvents:WaitForChild("SellItem")
local ListMarketItem     = RemoteEvents:WaitForChild("ListMarketItem")
local BuyMarketItem      = RemoteEvents:WaitForChild("BuyMarketItem")
local UpdateMarketPrices = RemoteEvents:WaitForChild("UpdateMarketPrices")
local NotifyPlayer       = RemoteEvents:WaitForChild("NotifyPlayer")
local RequestLoan        = RemoteEvents:WaitForChild("RequestLoan")

-- ─── Market Listings ─────────────────────────────────────────────────────────
-- { id, itemId, qty, price, sellerId, sellerName, listedAt }
local marketListings = {}
local nextListingId  = 1

-- Supply count per item (total qty across all listings)
local supplyCount = {}

local function recalcSupply()
    supplyCount = {}
    for _, listing in ipairs(marketListings) do
        supplyCount[listing.itemId] = (supplyCount[listing.itemId] or 0) + listing.qty
    end
end

local function broadcastPrices()
    local prices = {}
    for itemId, basePrice in pairs(GameConfig.BaseItemPrices) do
        local supply = supplyCount[itemId] or 0
        prices[itemId] = EconomyModule.DynamicPrice(basePrice, supply, GameConfig.SupplyThreshold)
    end
    UpdateMarketPrices:FireAllClients(prices, marketListings)
end

-- ─── Government Store Purchase ───────────────────────────────────────────────
PurchaseItem.OnServerInvoke = function(player, itemId, qty)
    qty = math.max(1, math.floor(qty or 1))
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end

    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    local itemInfo = ItemData.ById[itemId]
    if not itemInfo then return false, "Unknown item" end

    local basePrice = GameConfig.BaseItemPrices[itemId]
    if not basePrice then return false, "Not for sale" end

    -- Apply reputation discount
    local price = EconomyModule.ApplyReputationDiscount(basePrice * qty, data.Reputation)

    -- Check reputation ban
    if data.Reputation < GameConfig.ReputationBannedBelow then
        return false, "You are banned from this shop due to low reputation."
    end

    if not EconomyModule.CanAfford(data.Money, price) then
        return false, "Not enough money (need $" .. price .. ")"
    end

    PDM.SubtractMoney(player, price)
    PDM.AddToInventory(player, itemId, qty)
    NotifyPlayer:FireClient(player, "✅ Bought " .. qty .. "x " .. (itemInfo.name or itemId) .. " for $" .. price, "green")
    return true, "Purchase successful"
end

-- ─── Government Store Sell ───────────────────────────────────────────────────
SellItem.OnServerInvoke = function(player, itemId, qty)
    qty = math.max(1, math.floor(qty or 1))
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end

    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    local itemInfo = ItemData.ById[itemId]
    if not itemInfo then return false, "Unknown item" end

    if not PDM.HasItem(player, itemId, qty) then
        return false, "You don't have " .. qty .. "x " .. (itemInfo.name or itemId)
    end

    local basePrice = GameConfig.BaseItemPrices[itemId]
    if not basePrice then return false, "Cannot sell this item" end

    -- Sell price is 60% of current dynamic price
    local supply  = supplyCount[itemId] or 0
    local dynPrice= EconomyModule.DynamicPrice(basePrice, supply, GameConfig.SupplyThreshold)
    local sellPriceEach = math.floor(dynPrice * 0.6)
    local total   = sellPriceEach * qty

    PDM.RemoveFromInventory(player, itemId, qty)
    PDM.AddMoney(player, total)
    NotifyPlayer:FireClient(player, "💰 Sold " .. qty .. "x " .. (itemInfo.name or itemId) .. " for $" .. total, "green")
    recalcSupply()
    broadcastPrices()
    return true, "Sell successful"
end

-- ─── Player Market: List an item ─────────────────────────────────────────────
ListMarketItem.OnServerInvoke = function(player, itemId, qty, price)
    qty   = math.max(1, math.floor(qty   or 1))
    price = math.max(1, math.floor(price or 1))
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end

    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    if not PDM.HasItem(player, itemId, qty) then
        return false, "You don't have enough of that item"
    end

    -- Deduct listing fee (5%)
    local fee = math.max(1, math.floor(price * qty * GameConfig.AuctionFeePercent / 100))
    if not EconomyModule.CanAfford(data.Money, fee) then
        return false, "Listing fee is $" .. fee .. " (you need more money)"
    end

    PDM.RemoveFromInventory(player, itemId, qty)
    PDM.SubtractMoney(player, fee)

    local listing = {
        id        = nextListingId,
        itemId    = itemId,
        qty       = qty,
        price     = price,
        sellerId  = player.UserId,
        sellerName= player.Name,
        listedAt  = os.time(),
    }
    nextListingId = nextListingId + 1
    table.insert(marketListings, listing)
    recalcSupply()
    broadcastPrices()
    NotifyPlayer:FireClient(player, "🏪 Listed " .. qty .. "x " .. itemId .. " at $" .. price .. " each (fee: $" .. fee .. ")", "blue")
    return true, listing.id
end

-- ─── Player Market: Buy a listing ────────────────────────────────────────────
BuyMarketItem.OnServerInvoke = function(player, listingId)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end

    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    -- Find listing
    local listingIdx = nil
    local listing    = nil
    for i, l in ipairs(marketListings) do
        if l.id == listingId then
            listingIdx = i
            listing    = l
            break
        end
    end
    if not listing then return false, "Listing no longer available" end

    if listing.sellerId == player.UserId then
        return false, "You cannot buy your own listing"
    end

    local total = listing.price * listing.qty
    if not EconomyModule.CanAfford(data.Money, total) then
        return false, "Not enough money (need $" .. total .. ")"
    end

    PDM.SubtractMoney(player, total)
    PDM.AddToInventory(player, listing.itemId, listing.qty)

    -- Pay seller
    local seller = Players:GetPlayerByUserId(listing.sellerId)
    if seller then
        PDM.AddMoney(seller, total)
        NotifyPlayer:FireClient(seller, "💰 Your listing sold for $" .. total .. "!", "green")
    end

    table.remove(marketListings, listingIdx)
    recalcSupply()
    broadcastPrices()
    NotifyPlayer:FireClient(player, "✅ Bought " .. listing.qty .. "x " .. listing.itemId .. " for $" .. total, "green")
    return true, "Purchase successful"
end

-- ─── Bank Loan ────────────────────────────────────────────────────────────────
RequestLoan.OnServerInvoke = function(player, amount)
    amount = math.max(100, math.min(GameConfig.MaxLoan, math.floor(amount or 1000)))
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end
    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    if data.LoanAmount > 0 then
        return false, "You already have an outstanding loan of $" .. data.LoanAmount
    end

    data.LoanAmount = amount
    PDM.AddMoney(player, amount)
    NotifyPlayer:FireClient(player, "🏦 Loan of $" .. amount .. " approved. Pay it back at the bank!", "blue")
    return true, "Loan approved"
end

-- ─── Tax Collection (every TaxIntervalSeconds) ───────────────────────────────
local taxTimer = 0
RunService.Heartbeat:Connect(function(dt)
    taxTimer = taxTimer + dt
    if taxTimer >= GameConfig.TaxIntervalSeconds then
        taxTimer = 0
        local PDM = _G.PDM
        if not PDM then return end
        for _, player in ipairs(Players:GetPlayers()) do
            local data = PDM.GetData(player)
            if data then
                -- Property tax (only if they own a plot)
                if data.PlotIndex > 0 then
                    local tax = math.floor(GameConfig.PlotPrices.Small * GameConfig.TaxRatePercent / 100)
                    if PDM.SubtractMoney(player, tax) then
                        NotifyPlayer:FireClient(player, "🏛️ Property tax collected: $" .. tax, "yellow")
                    else
                        NotifyPlayer:FireClient(player, "⚠️ Could not pay property tax! You may lose your plot.", "red")
                    end
                end
                -- Loan interest
                if data.LoanAmount > 0 then
                    local interest = math.floor(data.LoanAmount * GameConfig.LoanInterestRatePercent / 100)
                    data.LoanAmount = data.LoanAmount + interest
                    NotifyPlayer:FireClient(player, "🏦 Loan interest added: $" .. interest .. " (total: $" .. data.LoanAmount .. ")", "yellow")
                end
                -- Savings interest (if money > 1000)
                if data.Money >= 1000 then
                    local interest = math.floor(data.Money * GameConfig.BankInterestRatePercent / 100)
                    PDM.AddMoney(player, interest)
                end
            end
        end
        broadcastPrices()
    end
end)

-- Initial price broadcast after a short delay (let players load)
task.delay(3, broadcastPrices)

print("[EconomyManager] Ready")
