-- RemoteEvents.lua
-- ReplicatedStorage > Modules > RemoteEvents
-- Creates (server) or retrieves (client) all RemoteEvents and RemoteFunctions.
-- Usage:  local RE = require(game.ReplicatedStorage.Modules.RemoteEvents)
--         RE.BuyProperty:FireServer(propertyId, plotId)

local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")

local isServer = RunService:IsServer()

-- Folder that holds all remotes
local function getOrCreate(parent, className, name)
    local obj = parent:FindFirstChild(name)
    if not obj then
        if isServer then
            obj = Instance.new(className)
            obj.Name = name
            obj.Parent = parent
        else
            obj = parent:WaitForChild(name, 15)
        end
    end
    return obj
end

local folder = getOrCreate(RS, "Folder", "Remotes")

local RemoteEvents = {}

-- ── Job System ──────────────────────────────────
RemoteEvents.AssignJob         = getOrCreate(folder, "RemoteEvent",    "AssignJob")
RemoteEvents.LeaveJob          = getOrCreate(folder, "RemoteEvent",    "LeaveJob")
RemoteEvents.GetJobInfo        = getOrCreate(folder, "RemoteFunction", "GetJobInfo")

-- ── Property System ──────────────────────────────
RemoteEvents.BuyProperty       = getOrCreate(folder, "RemoteEvent",    "BuyProperty")
RemoteEvents.SellProperty      = getOrCreate(folder, "RemoteEvent",    "SellProperty")
RemoteEvents.GetMyProperties   = getOrCreate(folder, "RemoteFunction", "GetMyProperties")

-- ── Business System ──────────────────────────────
RemoteEvents.OpenBusiness      = getOrCreate(folder, "RemoteEvent",    "OpenBusiness")
RemoteEvents.CloseBusiness     = getOrCreate(folder, "RemoteEvent",    "CloseBusiness")
RemoteEvents.GetMyBusinesses   = getOrCreate(folder, "RemoteFunction", "GetMyBusinesses")

-- ── Auction System ──────────────────────────────
RemoteEvents.ListAuction       = getOrCreate(folder, "RemoteEvent",    "ListAuction")
RemoteEvents.PlaceBid          = getOrCreate(folder, "RemoteEvent",    "PlaceBid")
RemoteEvents.ClaimAuction      = getOrCreate(folder, "RemoteEvent",    "ClaimAuction")
RemoteEvents.GetAuctions       = getOrCreate(folder, "RemoteFunction", "GetAuctions")

-- ── Economy / HUD ────────────────────────────────
RemoteEvents.UpdateHUD         = getOrCreate(folder, "RemoteEvent",    "UpdateHUD")
RemoteEvents.Notify            = getOrCreate(folder, "RemoteEvent",    "Notify")

-- ── Monetization ────────────────────────────────
RemoteEvents.PurchaseProduct   = getOrCreate(folder, "RemoteEvent",    "PurchaseProduct")

return RemoteEvents
