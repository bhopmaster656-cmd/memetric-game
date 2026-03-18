-- PlayerController.client.lua
-- StarterPlayer > StarterPlayerScripts
-- Client-side character controller: nameplate, interactions, key bindings.

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local RS                 = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera    = workspace.CurrentCamera

-- ── Nameplate cash display ─────────────────────────────────────────────────────
-- Attach a BillboardGui above the character's head showing the player's name.
local function attachNameplate(char)
    local head = char:WaitForChild("Head", 10)
    if not head then return end

    -- Remove any existing nameplate
    local existing = head:FindFirstChild("CityNameplate")
    if existing then existing:Destroy() end

    local bg         = Instance.new("BillboardGui")
    bg.Name          = "CityNameplate"
    bg.Size          = UDim2.new(0, 180, 0, 30)
    bg.StudsOffset   = Vector3.new(0, 2.5, 0)
    bg.AlwaysOnTop   = false
    bg.ResetOnSpawn  = false
    bg.Parent        = head

    local lbl        = Instance.new("TextLabel")
    lbl.Name         = "Label"
    lbl.Size         = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text         = player.Name
    lbl.TextColor3   = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0.5
    lbl.Font         = Enum.Font.GothamBold
    lbl.TextScaled   = true
    lbl.Parent       = bg
end

attachNameplate(character)
player.CharacterAdded:Connect(attachNameplate)

-- ── Camera FOV and bobbing ──────────────────────────────────────────────────────
camera.FieldOfView = 70

-- ── Proximity interaction prompt (press E near objects) ────────────────────────
-- When a player walks close to a building labelled "FireStation", "PoliceStation",
-- etc., they get a prompt to apply for the job.
local INTERACT_RANGE = 20
local promptGui      = player.PlayerGui:WaitForChild("MainHUD", 10)
local interactLabel  = nil   -- created lazily

local jobTriggers = {
    FireStation    = "firefighter",
    PoliceStation  = "police",
    Hospital       = "doctor",
    School         = "teacher",
    CityHall       = "mayor",
    Courthouse     = "deputy",
}

local function getCharPos()
    if not character then return nil end
    local root = character:FindFirstChild("HumanoidRootPart")
    return root and root.Position or nil
end

local function findNearestTrigger()
    local pos = getCharPos()
    if not pos then return nil, nil end
    local best, bestDist, bestJob = nil, INTERACT_RANGE + 1, nil
    for modelName, jobId in pairs(jobTriggers) do
        local model = workspace:FindFirstChild("CityMap", true)
        if model then
            local part = model:FindFirstChild(modelName, true)
            if part and part:IsA("BasePart") then
                local d = (part.Position - pos).Magnitude
                if d < bestDist then
                    bestDist = d
                    best     = part
                    bestJob  = jobId
                end
            end
        end
    end
    return best, bestJob
end

-- Simple on-screen prompt label
local function ensureInteractLabel()
    if interactLabel then return interactLabel end
    local hud = player.PlayerGui:FindFirstChild("MainHUD")
    if not hud then return nil end
    local lbl = Instance.new("TextLabel")
    lbl.Name  = "InteractPrompt"
    lbl.Size  = UDim2.new(0, 300, 0, 40)
    lbl.Position = UDim2.new(0.5, -150, 0.8, 0)
    lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    lbl.BackgroundTransparency = 0.3
    lbl.BorderSizePixel = 0
    lbl.Text  = ""
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font  = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.Visible = false
    lbl.Parent  = hud
    Instance.new("UICorner").Parent = lbl
    interactLabel = lbl
    return lbl
end

local nearbyJob = nil

RunService.Heartbeat:Connect(function()
    local _, job = findNearestTrigger()
    nearbyJob    = job
    local lbl    = ensureInteractLabel()
    if lbl then
        if job then
            lbl.Text    = "[E] Apply for job"
            lbl.Visible = true
        else
            lbl.Visible = false
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.E and nearbyJob then
        local RE = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))
        RE.AssignJob:FireServer(nearbyJob)
    end
end)

print("[PlayerController] Loaded.")
