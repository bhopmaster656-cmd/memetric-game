-- AuctionSystem.server.lua
-- ServerScriptService
-- Players list properties or businesses for auction; others bid to acquire them.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

repeat task.wait(0.1) until _G.PlayerData

local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))
local RE         = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- ── Auction state ─────────────────────────────────────────────────────────────
-- auctions[auctionId] = {
--   id, sellerUserId, itemType ("property"|"business"),
--   itemData, startPrice, currentBid, currentBidder,
--   endTime, active
-- }
local auctions    = {}
local auctionSeq  = 0

local function newAuctionId()
    auctionSeq = auctionSeq + 1
    return "AUC_" .. auctionSeq
end

local function findAuction(auctionId)
    return auctions[auctionId]
end

-- ── Remote: ListAuction ───────────────────────────────────────────────────────
-- itemType: "property" | "business"
-- itemRef:  plotId (for property) or businessId (for business)
-- startPrice: opening bid
RE.ListAuction.OnServerEvent:Connect(function(player, itemType, itemRef, startPrice)
    local data = _G.PlayerData.get(player)
    if not data then return end

    startPrice = math.max(1, math.floor(tonumber(startPrice) or 0))

    -- Verify ownership
    local itemData = nil
    if itemType == "property" then
        for _, entry in ipairs(data.properties) do
            if entry.plotId == tostring(itemRef) then
                itemData = entry
                break
            end
        end
    elseif itemType == "business" then
        for _, entry in ipairs(data.businesses) do
            if entry.businessId == tostring(itemRef) then
                itemData = entry
                break
            end
        end
    end

    if not itemData then
        RE.Notify:FireClient(player, "You don't own that item.", "error")
        return
    end

    local auctionId = newAuctionId()
    auctions[auctionId] = {
        id             = auctionId,
        sellerUserId   = player.UserId,
        itemType       = itemType,
        itemData       = itemData,
        startPrice     = startPrice,
        currentBid     = startPrice,
        currentBidder  = nil,
        endTime        = os.time() + GameConfig.AuctionDuration,
        active         = true,
    }

    RE.Notify:FireClient(player, "Auction listed! ID: " .. auctionId, "success")
    print("[AuctionSystem]", player.Name, "listed", itemType, itemRef, "starting at $" .. startPrice)
end)

-- ── Remote: PlaceBid ──────────────────────────────────────────────────────────
RE.PlaceBid.OnServerEvent:Connect(function(player, auctionId, bidAmount)
    local data = _G.PlayerData.get(player)
    if not data then return end

    local auc = findAuction(auctionId)
    if not auc or not auc.active then
        RE.Notify:FireClient(player, "Auction not found or expired.", "error")
        return
    end

    if os.time() > auc.endTime then
        auc.active = false
        RE.Notify:FireClient(player, "That auction has already ended.", "warn")
        return
    end

    if player.UserId == auc.sellerUserId then
        RE.Notify:FireClient(player, "You cannot bid on your own auction.", "warn")
        return
    end

    bidAmount = math.floor(tonumber(bidAmount) or 0)
    local minBid = math.ceil(auc.currentBid * (1 + GameConfig.AuctionMinBidRaise))
    if bidAmount < minBid then
        RE.Notify:FireClient(player, "Bid must be at least $" .. minBid, "warn")
        return
    end

    if data.cash < bidAmount then
        RE.Notify:FireClient(player, "Not enough cash!", "warn")
        return
    end

    -- Refund previous bidder
    if auc.currentBidder then
        local prevBidder = Players:GetPlayerByUserId(auc.currentBidder)
        if prevBidder then
            _G.PlayerData.addCash(prevBidder, auc.currentBid)
            RE.Notify:FireClient(prevBidder, "You were outbid on auction " .. auctionId, "warn")
        end
        -- If offline, store in their data when they return (simplified: just log)
    end

    _G.PlayerData.addCash(player, -bidAmount)
    auc.currentBid    = bidAmount
    auc.currentBidder = player.UserId

    RE.Notify:FireClient(player, "Bid placed: $" .. bidAmount .. " on auction " .. auctionId, "success")
end)

-- ── Remote: ClaimAuction ─────────────────────────────────────────────────────
RE.ClaimAuction.OnServerEvent:Connect(function(player, auctionId)
    local data = _G.PlayerData.get(player)
    if not data then return end

    local auc = findAuction(auctionId)
    if not auc then
        RE.Notify:FireClient(player, "Auction not found.", "error")
        return
    end

    if auc.active and os.time() < auc.endTime then
        RE.Notify:FireClient(player, "Auction is still running.", "warn")
        return
    end

    auc.active = false

    if auc.currentBidder == nil then
        -- No bids — return to seller if online
        local seller = Players:GetPlayerByUserId(auc.sellerUserId)
        if seller then
            RE.Notify:FireClient(seller, "No bids on your auction " .. auctionId .. ". Item returned.", "info")
        end
        auctions[auctionId] = nil
        return
    end

    if player.UserId ~= auc.currentBidder then
        RE.Notify:FireClient(player, "You are not the winning bidder.", "error")
        return
    end

    -- Transfer item to winner
    if auc.itemType == "property" then
        local sellerData = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == auc.sellerUserId then
                sellerData = _G.PlayerData.get(p)
                break
            end
        end
        -- If seller offline, item is still transferred (simplified)
        if sellerData then
            for i, entry in ipairs(sellerData.properties) do
                if entry.plotId == auc.itemData.plotId then
                    table.remove(sellerData.properties, i)
                    break
                end
            end
        end
        data.properties[#data.properties + 1] = auc.itemData
        -- Pay seller
        local seller = Players:GetPlayerByUserId(auc.sellerUserId)
        if seller then
            _G.PlayerData.addCash(seller, auc.currentBid)
            RE.Notify:FireClient(seller, "Your auction sold for $" .. auc.currentBid, "success")
        end
    elseif auc.itemType == "business" then
        local sellerData = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p.UserId == auc.sellerUserId then
                sellerData = _G.PlayerData.get(p)
                break
            end
        end
        if sellerData then
            for i, entry in ipairs(sellerData.businesses) do
                if entry.businessId == auc.itemData.businessId then
                    table.remove(sellerData.businesses, i)
                    break
                end
            end
        end
        data.businesses[#data.businesses + 1] = auc.itemData
        local seller = Players:GetPlayerByUserId(auc.sellerUserId)
        if seller then
            _G.PlayerData.addCash(seller, auc.currentBid)
            RE.Notify:FireClient(seller, "Your business auction sold for $" .. auc.currentBid, "success")
        end
    end

    RE.Notify:FireClient(player, "You won auction " .. auctionId .. "!", "success")
    auctions[auctionId] = nil
end)

-- ── Remote: GetAuctions ────────────────────────────────────────────────────────
RE.GetAuctions.OnServerInvoke = function(_player)
    local list = {}
    for id, auc in pairs(auctions) do
        if auc.active and os.time() <= auc.endTime then
            list[#list + 1] = {
                id           = id,
                itemType     = auc.itemType,
                itemData     = auc.itemData,
                currentBid   = auc.currentBid,
                timeLeft     = auc.endTime - os.time(),
            }
        else
            auc.active = false
        end
    end
    return list
end

-- ── Expire auctions automatically ─────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(10)
        for id, auc in pairs(auctions) do
            if auc.active and os.time() > auc.endTime then
                auc.active = false
                -- If there's a winning bidder, notify them
                if auc.currentBidder then
                    local winner = Players:GetPlayerByUserId(auc.currentBidder)
                    if winner then
                        RE.Notify:FireClient(winner, "Auction " .. id .. " ended – use Claim to collect.", "info")
                    end
                end
            end
        end
    end
end)

print("[AuctionSystem] Initialized.")
