-- ServerScriptService/NPCManager.server.lua
-- Spawns and manages NPC citizens and bandits.
-- NPCs wander the world, can be talked to for quests,
-- and bandits can be fought for loot.

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))

local NotifyPlayer = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("NotifyPlayer")

-- NPC folder
local npcFolder = Instance.new("Folder")
npcFolder.Name  = "NPCs"
npcFolder.Parent= Workspace

-- ─── NPC Data ─────────────────────────────────────────────────────────────────
local NPC_NAMES = {
    "Alice", "Bob", "Carol", "Dave", "Eve", "Frank", "Grace", "Hank",
    "Iris", "Jake", "Karen", "Leo", "Mia", "Ned", "Olivia", "Pete",
    "Quinn", "Rosa", "Sam", "Tina",
}

local NPC_WANDER_POSITIONS = {
    Vector3.new(0,   3, 0),    -- Downtown center
    Vector3.new(-50, 3, 0),    -- Town Hall area
    Vector3.new(50,  3, 0),    -- Bank area
    Vector3.new(0,   3, 80),   -- Café
    Vector3.new(-200,3, 250),  -- Suburbs
    Vector3.new(300, 3, 200),  -- Farm
    Vector3.new(-300,3,-300),  -- Forest
    Vector3.new(0,   3, 850),  -- Beach
}

-- ─── Build NPC ─────────────────────────────────────────────────────────────────
local function buildNPC(name, pos, isBandit)
    local model    = Instance.new("Model")
    model.Name     = name

    -- Body parts (simple humanoid shape)
    local torso = Instance.new("Part")
    torso.Name   = "HumanoidRootPart"
    torso.Size   = Vector3.new(2, 2, 1)
    torso.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    torso.BrickColor = isBandit and BrickColor.new("Really black") or BrickColor.new("Medium brown")
    torso.Material = Enum.Material.SmoothPlastic
    torso.Parent = model

    local head = Instance.new("Part")
    head.Name   = "Head"
    head.Shape  = Enum.PartType.Ball
    head.Size   = Vector3.new(1.5, 1.5, 1.5)
    head.CFrame = CFrame.new(pos + Vector3.new(0, 4.5, 0))
    head.BrickColor = BrickColor.new("Bright yellow")
    head.Material = Enum.Material.SmoothPlastic
    head.Parent = model

    local weldHead = Instance.new("WeldConstraint")
    weldHead.Part0 = torso
    weldHead.Part1 = head
    weldHead.Parent= torso

    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth   = isBandit and 50 or 100
    humanoid.Health      = humanoid.MaxHealth
    humanoid.WalkSpeed   = GameConfig.NPCWalkSpeed
    humanoid.DisplayName = name
    humanoid.Parent      = model

    -- Name tag
    local gui = Instance.new("BillboardGui")
    gui.Size  = UDim2.new(0, 100, 0, 40)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = false
    local lbl = Instance.new("TextLabel")
    lbl.Size  = UDim2.new(1, 0, 1, 0)
    lbl.Text  = (isBandit and "⚔️ " or "👤 ") .. name
    lbl.TextColor3 = isBandit and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font  = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.Parent = gui
    gui.Parent = head

    -- Proximity prompt for interaction
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = isBandit and "Fight" or "Talk"
    prompt.ObjectText = name
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.Parent = torso

    model.PrimaryPart = torso
    model:SetAttribute("IsBandit", isBandit or false)
    model:SetAttribute("WanderIndex", math.random(#NPC_WANDER_POSITIONS))
    model:SetAttribute("WanderTimer", 0)
    model.Parent = npcFolder

    -- Interaction handler
    prompt.Triggered:Connect(function(player)
        if isBandit then
            -- Combat: player attacks bandit, gains loot
            local PDM = _G.PDM
            if not PDM then return end
            humanoid.Health = humanoid.Health - 25
            if humanoid.Health <= 0 then
                PDM.AddMoney(player, math.random(20, 80))
                PDM.AddToInventory(player, "Coal", math.random(1, 3))
                NotifyPlayer:FireClient(player, "⚔️ Defeated " .. name .. "! Gained loot.", "green")
                task.delay(30, function()
                    if model and model.Parent then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end)
            else
                NotifyPlayer:FireClient(player, "⚔️ Hit " .. name .. "! HP: " .. math.floor(humanoid.Health), "yellow")
                -- Bandit damages player
                local char = player.Character
                if char then
                    local playerHumanoid = char:FindFirstChildOfClass("Humanoid")
                    if playerHumanoid then
                        playerHumanoid:TakeDamage(10)
                    end
                end
            end
        else
            -- Friendly NPC dialog
            local dialogs = {
                "Welcome to Evergreen County! 🌳",
                "Have you tried fishing at the park pond?",
                "The market prices change based on supply!",
                "Stay warm in winter — buy a coat!",
                "The mine opens to the east. Bring a pickaxe!",
                "You can buy plots in the Suburbs.",
                "Save your money, taxes come every hour!",
                "The bus is free for new players!",
            }
            NotifyPlayer:FireClient(player, "💬 " .. name .. ": " .. dialogs[math.random(#dialogs)], "blue")
        end
    end)

    return model
end

-- ─── Spawn Citizens ───────────────────────────────────────────────────────────
for i = 1, GameConfig.NPCCount do
    local pos  = NPC_WANDER_POSITIONS[math.random(#NPC_WANDER_POSITIONS)]
    local name = NPC_NAMES[i] or ("Citizen_" .. i)
    buildNPC(name, pos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)), false)
end

-- ─── Spawn Bandits in Warehouse ───────────────────────────────────────────────
for i = 1, GameConfig.BanditSpawnMax do
    local pos = Vector3.new(450 + math.random(-15, 15), 3, 100 + math.random(-15, 15))
    buildNPC("Bandit_" .. i, pos, true)
end

-- ─── NPC Wander AI ────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function(dt)
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            local root     = npc:FindFirstChild("HumanoidRootPart")
            if humanoid and root and not npc:GetAttribute("IsBandit") then
                local timer = (npc:GetAttribute("WanderTimer") or 0) + dt
                npc:SetAttribute("WanderTimer", timer)

                if timer >= 8 then  -- Move every 8 seconds
                    npc:SetAttribute("WanderTimer", 0)
                    local targetPos = NPC_WANDER_POSITIONS[math.random(#NPC_WANDER_POSITIONS)]
                    targetPos = targetPos + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
                    humanoid:MoveTo(targetPos)
                end
            end
        end
    end
end)

print("[NPCManager] " .. GameConfig.NPCCount .. " citizens and " .. GameConfig.BanditSpawnMax .. " bandits spawned")
