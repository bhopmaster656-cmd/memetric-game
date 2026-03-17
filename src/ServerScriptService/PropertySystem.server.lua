-- PropertySystem.server.lua
-- ServerScriptService
-- Handles buying, selling, and tracking of residential properties and land.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")

repeat task.wait(0.1) until _G.PlayerData

local GameConfig = require(RS:WaitForChild("Modules"):WaitForChild("GameConfig"))
local RE         = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- Available plots are tagged parts in Workspace under the folder "PropertyPlots".
-- Each Part should have a StringValue child "PropertyType" and a BoolValue "Owned".
local Workspace     = game:GetService("Workspace")
local plotsFolder   = Workspace:WaitForChild("PropertyPlots", 30)

-- Registry: plotId -> { ownerId, propertyType }
local plotOwnership = {}

-- Build initial registry from existing plots
local function refreshRegistry()
    if not plotsFolder then return end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local typeVal  = plot:FindFirstChild("PropertyType")
        local ownedVal = plot:FindFirstChild("Owned")
        if typeVal and ownedVal then
            plotOwnership[plot.Name] = {
                ownerId      = ownedVal.Value,
                propertyType = typeVal.Value,
                price        = 0,
            }
        end
    end
end
refreshRegistry()

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function findPropertyConfig(propId)
    for _, p in ipairs(GameConfig.Properties) do
        if p.id == propId then return p end
    end
    return nil
end

local function countPlayerProperties(data, propId)
    local count = 0
    for _, entry in ipairs(data.properties) do
        if entry.type == propId then count = count + 1 end
    end
    return count
end

local function findPlayerPropertyIndex(data, plotId)
    for i, entry in ipairs(data.properties) do
        if entry.plotId == plotId then return i end
    end
    return nil
end

-- Tag a plot part as owned/unowned
local function tagPlot(plotId, ownerId)
    if not plotsFolder then return end
    local plot    = plotsFolder:FindFirstChild(plotId)
    if not plot then return end
    local owned   = plot:FindFirstChild("Owned")
    if owned then owned.Value = tostring(ownerId or "") end
    -- Tint the plot so players can see it is taken
    if plot:IsA("BasePart") then
        plot.BrickColor = ownerId and BrickColor.new("Bright red") or BrickColor.new("Bright green")
        plot.Transparency = ownerId and 0.4 or 0.6
    end
end

-- ── Remote: BuyProperty ───────────────────────────────────────────────────────
RE.BuyProperty.OnServerEvent:Connect(function(player, propertyId, plotId)
    local data = _G.PlayerData.get(player)
    if not data then return end

    local prop = findPropertyConfig(propertyId)
    if not prop then
        RE.Notify:FireClient(player, "Invalid property type.", "error")
        return
    end

    -- Check plot availability
    local ownership = plotOwnership[tostring(plotId)]
    if ownership and ownership.ownerId ~= "" then
        RE.Notify:FireClient(player, "This plot is already owned.", "warn")
        return
    end

    -- Check ownership limit
    if countPlayerProperties(data, propertyId) >= prop.maxOwned then
        RE.Notify:FireClient(player, "You already own the maximum number of " .. prop.name .. "s.", "warn")
        return
    end

    -- Check funds
    if data.cash < prop.price then
        RE.Notify:FireClient(player, "Not enough cash! Need $" .. prop.price, "warn")
        return
    end

    _G.PlayerData.addCash(player, -prop.price)
    data.properties[#data.properties + 1] = { type = propertyId, plotId = tostring(plotId) }
    plotOwnership[tostring(plotId)] = { ownerId = tostring(player.UserId), propertyType = propertyId }
    tagPlot(tostring(plotId), player.UserId)

    RE.Notify:FireClient(player, "You bought a " .. prop.name .. "! (-$" .. prop.price .. ")", "success")
    print("[PropertySystem]", player.Name, "bought", prop.name, "plot", plotId)
end)

-- ── Remote: SellProperty ──────────────────────────────────────────────────────
RE.SellProperty.OnServerEvent:Connect(function(player, plotId)
    local data = _G.PlayerData.get(player)
    if not data then return end

    local idx = findPlayerPropertyIndex(data, tostring(plotId))
    if not idx then
        RE.Notify:FireClient(player, "You don't own that property.", "error")
        return
    end

    local entry    = data.properties[idx]
    local prop     = findPropertyConfig(entry.type)
    local sellPrice = prop and math.floor(prop.price * 0.7) or 0  -- 70 % resale value

    table.remove(data.properties, idx)
    plotOwnership[tostring(plotId)] = { ownerId = "", propertyType = entry.type }
    tagPlot(tostring(plotId), nil)
    _G.PlayerData.addCash(player, sellPrice)

    RE.Notify:FireClient(player, "Property sold for $" .. sellPrice, "success")
end)

-- ── Remote: GetMyProperties ───────────────────────────────────────────────────
RE.GetMyProperties.OnServerInvoke = function(player)
    local data = _G.PlayerData.get(player)
    if not data then return {} end
    return data.properties
end

print("[PropertySystem] Initialized.")
