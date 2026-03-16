-- ServerScriptService/ProfessionManager.server.lua
-- Handles profession selection, work actions (mining, farming, etc.)

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local GameConfig      = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ProfessionData  = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfessionData"))

local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents")
local SetProfession   = RemoteEvents:WaitForChild("SetProfession")
local HarvestResource = RemoteEvents:WaitForChild("HarvestResource")
local PlantCrop       = RemoteEvents:WaitForChild("PlantCrop")
local FeedAnimal      = RemoteEvents:WaitForChild("FeedAnimal")
local NotifyPlayer    = RemoteEvents:WaitForChild("NotifyPlayer")

-- Cooldowns per player
local harvestCooldowns = {}
local HARVEST_CD = 3  -- seconds between harvests

-- ─── Set Profession ──────────────────────────────────────────────────────────
SetProfession.OnServerInvoke = function(player, professionName)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end

    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    -- Validate profession name
    local profInfo = ProfessionData.ByName[professionName]
    if not profInfo then return false, "Unknown profession" end

    -- Check if unemployed or already has profession (can switch from Unemployed freely)
    if data.Profession ~= "Unemployed" and data.Profession ~= professionName then
        -- Requires visiting Town Hall (we trust the client for now; add proximity check if needed)
    end

    -- Check license cost
    local licenseCost = GameConfig.ProfessionLicenseCost[professionName] or 0
    if licenseCost > 0 then
        if not PDM.SubtractMoney(player, licenseCost) then
            return false, "You need $" .. licenseCost .. " for this profession license"
        end
    end

    PDM.SetProfession(player, professionName)
    NotifyPlayer:FireClient(player, "🎓 Profession set to: " .. professionName, "green")
    return true, professionName
end

-- ─── Harvest Resource ────────────────────────────────────────────────────────
HarvestResource.OnServerInvoke = function(player, partName)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end

    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    -- Cooldown check
    local now = tick()
    local lastHarvest = harvestCooldowns[player.UserId] or 0
    if now - lastHarvest < HARVEST_CD then
        return false, "Wait " .. string.format("%.1f", HARVEST_CD - (now - lastHarvest)) .. "s"
    end
    harvestCooldowns[player.UserId] = now

    -- Find the resource part in Workspace
    local resourcePart = nil
    for _, folder in ipairs({ "Wilderness", "IndustrialZone" }) do
        local f = Workspace:FindFirstChild(folder)
        if f then
            resourcePart = f:FindFirstChild(partName, true)
            if resourcePart then break end
        end
    end

    if not resourcePart then return false, "Resource not found" end
    if not resourcePart:GetAttribute("HasResource") then return false, "This node is depleted" end

    local resourceType = resourcePart:GetAttribute("ResourceType")
    if not resourceType then return false, "No resource type" end

    -- Check if player has the right tool
    local requiredTool = {
        Wood  = "Axe",
        Iron  = "Pickaxe",
        Coal  = "Pickaxe",
        Gold  = "Pickaxe",
        Diamond="Pickaxe",
        Stone = "Pickaxe",
    }
    local tool = requiredTool[resourceType]
    if tool and not PDM.HasItem(player, tool) then
        return false, "You need a " .. tool .. " to harvest " .. resourceType
    end

    -- Determine yield (Miners get a bonus)
    local qty = math.random(1, 3)
    if data.Profession == "Miner" and (resourceType == "Iron" or resourceType == "Coal" or resourceType == "Gold" or resourceType == "Diamond" or resourceType == "Stone") then
        qty = qty + 1
    end

    -- Deplete node (respawns after delay)
    local nodeQty = resourcePart:GetAttribute("Quantity") or qty
    nodeQty = nodeQty - 1
    if nodeQty <= 0 then
        resourcePart:SetAttribute("HasResource", false)
        -- Respawn after 60 seconds
        task.delay(60, function()
            if resourcePart and resourcePart.Parent then
                resourcePart:SetAttribute("HasResource", true)
                resourcePart:SetAttribute("Quantity", math.random(3, 8))
            end
        end)
    else
        resourcePart:SetAttribute("Quantity", nodeQty)
    end

    PDM.AddToInventory(player, resourceType, qty)
    -- Drain energy
    PDM.SetStat(player, "Energy", math.max(0, data.Stats.Energy - 5))

    NotifyPlayer:FireClient(player, "⛏️ Harvested " .. qty .. "x " .. resourceType, "green")
    return true, qty
end

-- ─── Plant Crop ───────────────────────────────────────────────────────────────
PlantCrop.OnServerInvoke = function(player, plotName, seedId)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end
    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    if data.Profession ~= "Farmer" and data.Profession ~= "Unemployed" then
        return false, "Only Farmers can plant crops"
    end

    -- Find farm plot
    local industrial = Workspace:FindFirstChild("IndustrialZone")
    if not industrial then return false, "Farm not found" end
    local farmPlots = industrial:FindFirstChild("FarmPlots")
    if not farmPlots then return false, "Farm plots not found" end
    local plot = farmPlots:FindFirstChild(plotName)
    if not plot then return false, "Plot not found" end

    if plot:GetAttribute("Occupied") then return false, "Plot is already in use" end
    if plot:GetAttribute("OwnerId") ~= 0 and plot:GetAttribute("OwnerId") ~= player.UserId then
        return false, "This plot belongs to another farmer"
    end

    -- Check seed
    local seedMap = {
        SeedWheat  = "Wheat",
        SeedCorn   = "Corn",
        SeedTomato = "Tomato",
        SeedPotato = "Potato",
    }
    local cropType = seedMap[seedId]
    if not cropType then return false, "Unknown seed" end

    if not PDM.RemoveFromInventory(player, seedId, 1) then
        return false, "You don't have that seed"
    end

    plot:SetAttribute("Occupied",    true)
    plot:SetAttribute("CropType",    cropType)
    plot:SetAttribute("GrowthStage", 0)
    plot:SetAttribute("OwnerId",     player.UserId)
    plot:SetAttribute("PlantedAt",   os.time())
    plot.BrickColor = BrickColor.new("Bright green")

    -- Growth stages (takes 60 seconds per stage, 3 stages to full)
    local GROWTH_TIME = 60
    task.delay(GROWTH_TIME, function()
        if plot and plot.Parent and plot:GetAttribute("Occupied") then
            plot:SetAttribute("GrowthStage", 1)
        end
    end)
    task.delay(GROWTH_TIME * 2, function()
        if plot and plot.Parent and plot:GetAttribute("Occupied") then
            plot:SetAttribute("GrowthStage", 2)
        end
    end)
    task.delay(GROWTH_TIME * 3, function()
        if plot and plot.Parent and plot:GetAttribute("Occupied") then
            plot:SetAttribute("GrowthStage", 3)  -- Ready to harvest
            -- Notify owner
            local owner = Players:GetPlayerByUserId(player.UserId)
            if owner then
                NotifyPlayer:FireClient(owner, "🌾 Your " .. cropType .. " is ready to harvest!", "green")
            end
        end
    end)

    NotifyPlayer:FireClient(player, "🌱 Planted " .. cropType .. " on " .. plotName, "green")
    return true, cropType
end

-- ─── Feed Animal (placeholder for future animal system) ─────────────────────
FeedAnimal.OnServerInvoke = function(player, animalName)
    local PDM = _G.PDM
    if not PDM then return false end
    -- Basic implementation: feeding costs food, gives money
    if PDM.RemoveFromInventory(player, "Wheat", 1) then
        PDM.AddMoney(player, 15)
        NotifyPlayer:FireClient(player, "🐄 Fed the animal and earned $15", "green")
        return true
    end
    return false, "You need Wheat to feed animals"
end

print("[ProfessionManager] Ready")
