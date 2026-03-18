-- BusinessSystem.server.lua
-- ServerScriptService
-- Players open, manage, and earn passive income from businesses.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

repeat task.wait(0.1) until _G.PlayerData

local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))
local RE         = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function findBizConfig(bizId)
    for _, b in ipairs(GameConfig.Businesses) do
        if b.id == bizId then return b end
    end
    return nil
end

local function countPlayerBusinesses(data, bizId)
    local count = 0
    for _, entry in ipairs(data.businesses) do
        if entry.type == bizId then count = count + 1 end
    end
    return count
end

local function maxOwned(data, biz)
    local max = biz.maxOwned
    if data.hasBusinessTycoon then max = max + 1 end
    return max
end

-- ── Remote: OpenBusiness ──────────────────────────────────────────────────────
RE.OpenBusiness.OnServerEvent:Connect(function(player, bizId)
    local data = _G.PlayerData.get(player)
    if not data then return end

    local biz = findBizConfig(bizId)
    if not biz then
        RE.Notify:FireClient(player, "Invalid business type.", "error")
        return
    end

    if countPlayerBusinesses(data, bizId) >= maxOwned(data, biz) then
        RE.Notify:FireClient(player, "You already own the maximum number of " .. biz.name .. "s.", "warn")
        return
    end

    if data.cash < biz.cost then
        RE.Notify:FireClient(player, "Not enough cash! Need $" .. biz.cost, "warn")
        return
    end

    _G.PlayerData.addCash(player, -biz.cost)

    local bizEntry = {
        type       = bizId,
        businessId = player.UserId .. "_" .. bizId .. "_" .. os.time(),
        open       = true,
        revenue    = 0,
    }
    data.businesses[#data.businesses + 1] = bizEntry

    RE.Notify:FireClient(player, "You opened a " .. biz.name .. "! (-$" .. biz.cost .. ")", "success")
    print("[BusinessSystem]", player.Name, "opened", biz.name)
end)

-- ── Remote: CloseBusiness ──────────────────────────────────────────────────────
RE.CloseBusiness.OnServerEvent:Connect(function(player, businessId)
    local data = _G.PlayerData.get(player)
    if not data then return end

    local foundIdx = nil
    for i, entry in ipairs(data.businesses) do
        if entry.businessId == businessId then
            foundIdx = i
            break
        end
    end

    if not foundIdx then
        RE.Notify:FireClient(player, "Business not found.", "error")
        return
    end

    local entry  = table.remove(data.businesses, foundIdx)
    local biz    = findBizConfig(entry.type)
    -- Sell back at 60 % of purchase price
    local refund = biz and math.floor(biz.cost * 0.6) or 0
    _G.PlayerData.addCash(player, refund)

    RE.Notify:FireClient(player, "Business closed. Refund: $" .. refund, "info")
end)

-- ── Remote: GetMyBusinesses ───────────────────────────────────────────────────
RE.GetMyBusinesses.OnServerInvoke = function(player)
    local data = _G.PlayerData.get(player)
    if not data then return {} end
    return data.businesses
end

-- ── Passive income loop ───────────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(60)  -- pay out every 60 seconds
        for _, player in ipairs(Players:GetPlayers()) do
            local data = _G.PlayerData.get(player)
            if data then
                for _, entry in ipairs(data.businesses) do
                    if entry.open then
                        local biz = findBizConfig(entry.type)
                        if biz then
                            local income = biz.incomePerMin
                            entry.revenue = (entry.revenue or 0) + income
                            _G.PlayerData.addCash(player, income)
                            RE.Notify:FireClient(player, biz.name .. " earned +$" .. income, "business")
                        end
                    end
                end
            end
        end
    end
end)

print("[BusinessSystem] Initialized.")
