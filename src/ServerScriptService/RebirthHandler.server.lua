--[[
    RebirthHandler.server.lua
    Handles the rebirth mechanic.

    On rebirth:
        - Validates player has enough coins.
        - Increments RebirthLevel.
        - Resets coins & inventory (keeps RebirthLevel and quest progress).
        - Fires RebirthResult back to client.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames  = require(Modules.RemoteEvents)
local GameConfig   = require(Modules.GameConfig)

local DataStore    = require(script.Parent.DataStore)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

RE(RemoteNames.RequestRebirth).OnServerEvent:Connect(function(player)
    local data = DataStore.Get(player.UserId)
    if not data then
        RE(RemoteNames.RebirthResult):FireClient(player, {
            Success = false, Reason = "Data not loaded."
        })
        return
    end

    if data.RebirthLevel >= GameConfig.MAX_REBIRTHS then
        RE(RemoteNames.RebirthResult):FireClient(player, {
            Success = false, Reason = "Max rebirth level reached."
        })
        return
    end

    if data.Coins < GameConfig.REBIRTH_COST then
        RE(RemoteNames.RebirthResult):FireClient(player, {
            Success = false,
            Reason  = "Not enough coins. Need " .. GameConfig.REBIRTH_COST .. "."
        })
        return
    end

    -- Perform rebirth
    data.RebirthLevel = data.RebirthLevel + 1
    data.Coins        = 0
    data.Inventory    = {}
    data.TotalCaught  = 0

    -- Update leaderstats
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        ls.Coins.Value    = 0
        ls.Caught.Value   = 0
        ls.Rebirths.Value = data.RebirthLevel
    end

    RE(RemoteNames.UpdateCoins):FireClient(player, 0)
    RE(RemoteNames.UpdateInventory):FireClient(player, {})
    RE(RemoteNames.RebirthResult):FireClient(player, {
        Success = true,
        Level   = data.RebirthLevel,
    })
end)
