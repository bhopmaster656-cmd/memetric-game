--[[
    MainHandler.server.lua
    Bootstraps all RemoteEvent instances so every handler can find them.
    Must run before any handler that fires/connects RemoteEvents.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Modules         = ReplicatedStorage:WaitForChild("Modules")
local EventNames      = require(Modules.RemoteEvents)
local GameConfig      = require(Modules.GameConfig)  -- luacheck: ignore

-- Require DataStore at top level so its PlayerAdded listener is registered
-- before any player can join (Scripts run before PlayerAdded fires).
local DataStore = require(script.Parent.DataStore)

-- Ensure the RemoteEvents folder exists
local reFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    or Instance.new("Folder", ReplicatedStorage)
reFolder.Name = "RemoteEvents"

-- Create a RemoteEvent for every name in the map
for _, name in pairs(EventNames) do
    if not reFolder:FindFirstChild(name) then
        local re   = Instance.new("RemoteEvent")
        re.Name    = name
        re.Parent  = reFolder
    end
end

-- Leaderstats (visible in the Roblox players list)
Players.PlayerAdded:Connect(function(player)
    -- Wait for DataStore cache to be populated (DataStore.PlayerAdded fires first)
    task.wait(0.1)

    local stats = Instance.new("Folder")
    stats.Name   = "leaderstats"
    stats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name   = "Coins"
    coins.Value  = 0
    coins.Parent = stats

    local caught = Instance.new("IntValue")
    caught.Name   = "Caught"
    caught.Value  = 0
    caught.Parent = stats

    local rebirths = Instance.new("IntValue")
    rebirths.Name   = "Rebirths"
    rebirths.Value  = 0
    rebirths.Parent = stats

    -- Sync from saved data
    local data = DataStore.Get(player.UserId)
    if data then
        coins.Value    = data.Coins
        caught.Value   = data.TotalCaught
        rebirths.Value = data.RebirthLevel
    end
end)

print("[MainHandler] RemoteEvents initialised –", #reFolder:GetChildren(), "events ready.")
