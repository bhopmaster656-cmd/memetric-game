--[[
    VIPHandler.server.lua
    Grants VIP perks to players who own the VIP gamepass.
    Fires UpdateStats so the client can show the VIP badge.
--]]

local Players             = game:GetService("Players")
local MarketplaceService  = game:GetService("MarketplaceService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(Modules.RemoteEvents)
local GameConfig  = require(Modules.GameConfig)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local function checkVIP(player)
    if GameConfig.VIP_GAMEPASS_ID == 0 then return false end
    local ok, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(
            player.UserId, GameConfig.VIP_GAMEPASS_ID
        )
    end)
    return ok and owns
end

Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    local isVIP = checkVIP(player)
    RE(RemoteNames.UpdateStats):FireClient(player, {
        IsVIP = isVIP,
    })
end)

-- Handle in-session purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(
    function(player, gamepassId, wasPurchased)
        if not wasPurchased then return end
        if gamepassId == GameConfig.VIP_GAMEPASS_ID then
            RE(RemoteNames.UpdateStats):FireClient(player, { IsVIP = true })
        end
    end
)
