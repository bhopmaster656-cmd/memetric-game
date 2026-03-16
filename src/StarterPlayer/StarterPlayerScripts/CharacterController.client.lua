-- StarterPlayer/StarterPlayerScripts/CharacterController.client.lua
-- Handles sprint, crouch, emotes, and chat commands like /arrestplayer.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local ArrestPlayer  = RemoteEvents:WaitForChild("ArrestPlayer")
local InviteCoop    = RemoteEvents:WaitForChild("InviteCoop")
local AcceptCoop    = RemoteEvents:WaitForChild("AcceptCoop")
local SpawnVehicle  = RemoteEvents:WaitForChild("SpawnVehicle")
local NotifyPlayer  = RemoteEvents:WaitForChild("NotifyPlayer")

-- ─── Sprint ────────────────────────────────────────────────────────────────────
local isSprinting = false
local WALK_SPEED  = 16
local SPRINT_SPEED= 26

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = true
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = SPRINT_SPEED
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = false
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = WALK_SPEED
            end
        end
    end
end)

-- Re-apply walk speed on character respawn
player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.WalkSpeed = WALK_SPEED
    isSprinting = false
end)

-- ─── Chat Commands ─────────────────────────────────────────────────────────────
local function handleChatCommand(message)
    local lower = message:lower()

    -- /arrest <player>
    local arrestTarget = lower:match("^/arrest%s+(.+)$")
    if arrestTarget then
        -- Find exact player name (case-insensitive)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == arrestTarget then
                ArrestPlayer:FireServer(p.Name)
                return
            end
        end
        NotifyPlayer:FireServer and nil
        return
    end

    -- /coop <player>
    local coopTarget = lower:match("^/coop%s+(.+)$")
    if coopTarget then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == coopTarget then
                InviteCoop:FireServer(p.Name)
                return
            end
        end
        return
    end

    -- /acceptcoop <player>
    local acceptTarget = lower:match("^/acceptcoop%s+(.+)$")
    if acceptTarget then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == acceptTarget then
                AcceptCoop:InvokeServer(p.Name)
                return
            end
        end
        return
    end

    -- /spawn <vehicleId>
    local vehicleId = lower:match("^/spawn%s+(.+)$")
    if vehicleId then
        local vehicleMap = {
            bicycle   = "Bicycle",
            car       = "Car_Basic",
            sports    = "Car_Sports",
            truck     = "Car_Truck",
        }
        local mappedId = vehicleMap[vehicleId]
        if mappedId then
            SpawnVehicle:InvokeServer(mappedId)
        end
        return
    end
end

-- Hook into chat
local chatGui = player:WaitForChild("PlayerGui"):WaitForChild("Chat", 10)
if chatGui then
    -- Connect to chat fired events
end

-- Use Players.LocalPlayer.Chatted for command processing
player.Chatted:Connect(handleChatCommand)

-- ─── Emote Keybind (G key) ────────────────────────────────────────────────────
local emotes = { "wave", "dance", "laugh", "point" }
local emoteIndex = 1

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        local emote = emotes[emoteIndex]
        emoteIndex = (emoteIndex % #emotes) + 1
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:LoadAnimation(
                    script:FindFirstChild(emote) or Instance.new("Animation")
                ):Play()
            end
        end
    end
end)

print("[CharacterController] Ready")
