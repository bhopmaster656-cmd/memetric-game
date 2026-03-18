--[[
    FishingController.client.lua
    StarterPlayerScripts – handles all client-side fishing input and UI events.

    Communicates with FishingHandler.server via RemoteEvents.
    Coordinates with FishingUI.client (StarterGui) via BindableEvents stored
    in ReplicatedStorage so both scripts stay decoupled.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames  = require(Modules.RemoteEvents)
local GameConfig   = require(Modules.GameConfig)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local localPlayer = Players.LocalPlayer

-- ─── State ───────────────────────────────────────────────────────────────────
local isCasting = false
local biteReady = false

-- ─── Fishing input ───────────────────────────────────────────────────────────
-- Press E (or tap on mobile) to cast / reel
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.E
        or input.UserInputType == Enum.UserInputType.Touch then

        if not isCasting then
            -- Cast the rod
            isCasting = true
            biteReady = false
            RE(RemoteNames.CastRod):FireServer()
            -- Notify UI
            local gui = localPlayer.PlayerGui:FindFirstChild("FishingUI")
            if gui then
                local castEvent = gui:FindFirstChild("OnCast")
                if castEvent then castEvent:Fire() end
            end

        elseif biteReady then
            -- Reel in
            biteReady = false
            RE(RemoteNames.ReelIn):FireServer()
        end
    end
end)

-- ─── Bite alert ──────────────────────────────────────────────────────────────
RE(RemoteNames.BiteAlert).OnClientEvent:Connect(function()
    biteReady = true
    -- Notify UI to show reel prompt
    local gui = localPlayer.PlayerGui:FindFirstChild("FishingUI")
    if gui then
        local biteEvent = gui:FindFirstChild("OnBite")
        if biteEvent then biteEvent:Fire() end
    end
end)

-- ─── Catch result ────────────────────────────────────────────────────────────
RE(RemoteNames.CatchResult).OnClientEvent:Connect(function(result)
    isCasting = false
    biteReady = false

    -- Notify UI
    local gui = localPlayer.PlayerGui:FindFirstChild("FishingUI")
    if gui then
        local catchEvent = gui:FindFirstChild("OnCatchResult")
        if catchEvent then catchEvent:Fire(result) end
    end
end)
