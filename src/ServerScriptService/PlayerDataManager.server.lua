-- ServerScriptService/PlayerDataManager.server.lua
-- Manages per-player persistent data using DataStoreService.
-- Handles load on join, auto-save, save on leave.

local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))
local CharacterStats = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CharacterStats"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateStats      = RemoteEvents:WaitForChild("UpdateStats")
local UpdateMoney      = RemoteEvents:WaitForChild("UpdateMoney")
local UpdateReputation = RemoteEvents:WaitForChild("UpdateReputation")
local UpdateInventory  = RemoteEvents:WaitForChild("UpdateInventory")
local NotifyPlayer     = RemoteEvents:WaitForChild("NotifyPlayer")
local PayTax           = RemoteEvents:WaitForChild("PayTax")

-- DataStore (disabled in Studio unpublished runs — won't error, just warns)
local PlayerStore
local success = pcall(function()
    PlayerStore = DataStoreService:GetDataStore("EvergreenCounty_v" .. GameConfig.DataVersion)
end)
if not success then
    warn("[PDM] DataStore unavailable — data will not persist (Studio test mode)")
end

-- In-memory player data cache
local playerData = {}

-- ─── Default Data ─────────────────────────────────────────────────────────────
local function defaultData()
    return {
        Money      = GameConfig.StartingMoney,
        Reputation = GameConfig.ReputationStarting,
        Profession = "Unemployed",
        Stats = {
            Hunger      = 100,
            Thirst      = 100,
            Energy      = 100,
            Health      = 100,
            Temperature = 50,
        },
        Inventory  = {
            { id = "Bicycle",    qty = 1 },
            { id = "TrashBag",   qty = 5 },
            { id = "Water",      qty = 3 },
            { id = "Bread",      qty = 2 },
        },
        PlotIndex     = 0,
        OwnedVehicle  = "Bicycle",
        IsJailed      = false,
        JailTimeLeft  = 0,
        CriminalLevel = 0,
        LoanAmount    = 0,
        SavedAt       = os.time(),
        Version       = GameConfig.DataVersion,
    }
end

-- ─── Load Player Data ─────────────────────────────────────────────────────────
local function loadData(player)
    local data = nil

    if PlayerStore then
        local ok, result = pcall(function()
            return PlayerStore:GetAsync("player_" .. player.UserId)
        end)
        if ok and result then
            data = result
            -- Migrate older data versions if needed
            if not data.Version or data.Version < GameConfig.DataVersion then
                local defaults = defaultData()
                for k, v in pairs(defaults) do
                    if data[k] == nil then data[k] = v end
                end
                data.Version = GameConfig.DataVersion
            end
        else
            if not ok then
                warn("[PDM] Failed to load data for " .. player.Name .. ": " .. tostring(result))
            end
        end
    end

    if not data then
        data = defaultData()
    end

    playerData[player.UserId] = data
    return data
end

-- ─── Save Player Data ─────────────────────────────────────────────────────────
local function saveData(player)
    local data = playerData[player.UserId]
    if not data then return end
    data.SavedAt = os.time()

    if PlayerStore then
        local ok, err = pcall(function()
            PlayerStore:SetAsync("player_" .. player.UserId, data)
        end)
        if not ok then
            warn("[PDM] Save failed for " .. player.Name .. ": " .. tostring(err))
        end
    end
end

-- ─── Public API (used by other server scripts) ───────────────────────────────
local PDM = {}

function PDM.GetData(player)
    return playerData[player.UserId]
end

function PDM.SetMoney(player, amount)
    local data = playerData[player.UserId]
    if not data then return end
    data.Money = math.max(0, math.floor(amount))
    UpdateMoney:FireClient(player, data.Money)
end

function PDM.AddMoney(player, amount)
    local data = playerData[player.UserId]
    if not data then return end
    PDM.SetMoney(player, data.Money + amount)
end

function PDM.SubtractMoney(player, amount)
    local data = playerData[player.UserId]
    if not data then return false end
    if data.Money < amount then return false end
    PDM.SetMoney(player, data.Money - amount)
    return true
end

function PDM.SetReputation(player, value)
    local data = playerData[player.UserId]
    if not data then return end
    data.Reputation = math.clamp(math.floor(value), GameConfig.ReputationMin, GameConfig.ReputationMax)
    UpdateReputation:FireClient(player, data.Reputation)
end

function PDM.AddReputation(player, delta)
    local data = playerData[player.UserId]
    if not data then return end
    PDM.SetReputation(player, data.Reputation + delta)
end

function PDM.SetStat(player, statName, value)
    local data = playerData[player.UserId]
    if not data then return end
    data.Stats[statName] = math.clamp(value, 0, 100)
    -- Update character Values
    local char = player.Character
    if char then
        local v = char:FindFirstChild(statName)
        if v then v.Value = data.Stats[statName] end
    end
    UpdateStats:FireClient(player, data.Stats)
end

function PDM.AddToInventory(player, itemId, qty)
    local data = playerData[player.UserId]
    if not data then return end
    qty = qty or 1
    for _, slot in ipairs(data.Inventory) do
        if slot.id == itemId then
            slot.qty = slot.qty + qty
            UpdateInventory:FireClient(player, data.Inventory)
            return
        end
    end
    table.insert(data.Inventory, { id = itemId, qty = qty })
    UpdateInventory:FireClient(player, data.Inventory)
end

function PDM.RemoveFromInventory(player, itemId, qty)
    local data = playerData[player.UserId]
    if not data then return false end
    qty = qty or 1
    for i, slot in ipairs(data.Inventory) do
        if slot.id == itemId then
            if slot.qty < qty then return false end
            slot.qty = slot.qty - qty
            if slot.qty <= 0 then
                table.remove(data.Inventory, i)
            end
            UpdateInventory:FireClient(player, data.Inventory)
            return true
        end
    end
    return false
end

function PDM.HasItem(player, itemId, qty)
    local data = playerData[player.UserId]
    if not data then return false end
    qty = qty or 1
    for _, slot in ipairs(data.Inventory) do
        if slot.id == itemId and slot.qty >= qty then
            return true
        end
    end
    return false
end

function PDM.SetProfession(player, profession)
    local data = playerData[player.UserId]
    if not data then return end
    data.Profession = profession
end

function PDM.Jail(player, timeSeconds)
    local data = playerData[player.UserId]
    if not data then return end
    data.IsJailed     = true
    data.JailTimeLeft = timeSeconds
    NotifyPlayer:FireClient(player, "⛓️ You have been arrested! Jail time: " .. timeSeconds .. "s", "red")
    -- Teleport to jail (Police Station approximate location)
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(-100, 5, 30)
        end
    end
end

function PDM.Release(player)
    local data = playerData[player.UserId]
    if not data then return end
    data.IsJailed    = false
    data.JailTimeLeft = 0
    NotifyPlayer:FireClient(player, "🔓 You have been released!", "green")
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(-100, 5, 60)
        end
    end
end

-- ─── Player Events ───────────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    local data = loadData(player)

    player.CharacterAdded:Connect(function(char)
        -- Apply saved stats to new character
        task.wait(1)  -- Wait for character to fully load
        CharacterStats.CreateStatValues(char, data.Stats)
        -- Send initial data to client
        UpdateStats:FireClient(player, data.Stats)
        UpdateMoney:FireClient(player, data.Money)
        UpdateReputation:FireClient(player, data.Reputation)
        UpdateInventory:FireClient(player, data.Inventory)

        -- Restore health
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.MaxHealth = GameConfig.MaxHealth
            humanoid.Health    = data.Stats.Health
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    saveData(player)
    playerData[player.UserId] = nil
end)

-- Auto-save loop
local autoSaveTimer = 0
RunService.Heartbeat:Connect(function(dt)
    autoSaveTimer = autoSaveTimer + dt
    if autoSaveTimer >= GameConfig.AutoSaveInterval then
        autoSaveTimer = 0
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(saveData, player)
        end
    end
end)

-- Jail timer
RunService.Heartbeat:Connect(function(dt)
    for _, player in ipairs(Players:GetPlayers()) do
        local data = playerData[player.UserId]
        if data and data.IsJailed and data.JailTimeLeft > 0 then
            data.JailTimeLeft = data.JailTimeLeft - dt
            if data.JailTimeLeft <= 0 then
                PDM.Release(player)
            end
        end
    end
end)

-- Make PDM accessible to other server scripts via a BindableFunction
local pdmBindable = Instance.new("BindableFunction")
pdmBindable.Name = "PDM_GetData"
pdmBindable.OnInvoke = function(player)
    return playerData[player.UserId]
end
pdmBindable.Parent = game:GetService("ServerScriptService")

-- Store reference so other scripts can require this
_G.PDM = PDM

print("[PDM] PlayerDataManager ready")
