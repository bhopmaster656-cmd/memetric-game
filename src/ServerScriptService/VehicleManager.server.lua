-- ServerScriptService/VehicleManager.server.lua
-- Spawns vehicles, tracks durability, handles repairs.

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))

local RemoteEvents   = ReplicatedStorage:WaitForChild("RemoteEvents")
local SpawnVehicle   = RemoteEvents:WaitForChild("SpawnVehicle")
local RepairVehicle  = RemoteEvents:WaitForChild("RepairVehicle")
local NotifyPlayer   = RemoteEvents:WaitForChild("NotifyPlayer")

-- Track active vehicle models per player
local activeVehicles = {}  -- [userId] = Model

-- Vehicle folder
local vehicleFolder = Instance.new("Folder")
vehicleFolder.Name  = "Vehicles"
vehicleFolder.Parent= Workspace

-- ─── Build a simple vehicle model ────────────────────────────────────────────
local function buildVehicle(vehicleId, spawnCFrame)
    local model    = Instance.new("Model")
    model.Name     = vehicleId

    local speeds = {
        Bicycle    = GameConfig.BicycleSpeed,
        Car_Basic  = GameConfig.CarBasicSpeed,
        Car_Sports = GameConfig.CarSportsSpeed,
        Car_Truck  = GameConfig.CarTruckSpeed,
    }

    local colors = {
        Bicycle    = BrickColor.new("Bright red"),
        Car_Basic  = BrickColor.new("Bright blue"),
        Car_Sports = BrickColor.new("Bright yellow"),
        Car_Truck  = BrickColor.new("Sand green"),
    }

    local sizes = {
        Bicycle    = Vector3.new(2, 3, 6),
        Car_Basic  = Vector3.new(6, 3, 12),
        Car_Sports = Vector3.new(6, 2, 14),
        Car_Truck  = Vector3.new(7, 4, 16),
    }

    -- Body
    local body = Instance.new("Part")
    body.Name      = "VehicleBody"
    body.Size      = sizes[vehicleId] or Vector3.new(6, 3, 12)
    body.CFrame    = spawnCFrame
    body.BrickColor= colors[vehicleId] or BrickColor.new("Medium grey")
    body.Material  = Enum.Material.SmoothPlastic
    body.Parent    = model

    -- Wheels (4 corner spheres)
    local wheelPositions = {
        Vector3.new( 2.5, -1.5,  4),
        Vector3.new(-2.5, -1.5,  4),
        Vector3.new( 2.5, -1.5, -4),
        Vector3.new(-2.5, -1.5, -4),
    }
    for i, offset in ipairs(wheelPositions) do
        local wheel = Instance.new("Part")
        wheel.Name     = "Wheel_" .. i
        wheel.Shape    = Enum.PartType.Cylinder
        wheel.Size     = Vector3.new(1.5, 2, 2)
        wheel.CFrame   = spawnCFrame * CFrame.new(offset)
        wheel.BrickColor = BrickColor.new("Really black")
        wheel.Material = Enum.Material.SmoothPlastic
        wheel.Parent   = model
    end

    -- VehicleSeat for driving
    local seat = Instance.new("VehicleSeat")
    seat.Name         = "DriverSeat"
    seat.Size         = Vector3.new(2, 1, 2)
    seat.CFrame       = spawnCFrame * CFrame.new(0, 1.5, 0)
    seat.MaxSpeed     = speeds[vehicleId] or 60
    seat.Torque       = 50
    seat.TurnSpeed    = 2
    seat.BrickColor   = BrickColor.new("Dark grey")
    seat.Material     = Enum.Material.SmoothPlastic
    seat.Parent       = model

    -- Weld everything to body
    for _, part in ipairs(model:GetChildren()) do
        if part ~= body and part:IsA("BasePart") then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = body
            weld.Part1 = part
            weld.Parent= body
        end
    end

    model.PrimaryPart = body
    return model
end

-- ─── Spawn Vehicle for player ─────────────────────────────────────────────────
SpawnVehicle.OnServerInvoke = function(player, vehicleId)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end
    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    -- Remove existing vehicle
    if activeVehicles[player.UserId] then
        activeVehicles[player.UserId]:Destroy()
        activeVehicles[player.UserId] = nil
    end

    -- Check ownership
    if not PDM.HasItem(player, vehicleId) then
        return false, "You don't own a " .. vehicleId
    end

    -- Spawn near player
    local char = player.Character
    local spawnPos = Vector3.new(0, 5, 150)  -- Default spawn
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            spawnPos = root.Position + Vector3.new(8, 3, 0)
        end
    end

    local model = buildVehicle(vehicleId, CFrame.new(spawnPos))
    model.Name  = player.Name .. "_" .. vehicleId
    model:SetAttribute("OwnerId",    player.UserId)
    model:SetAttribute("Durability", GameConfig.VehicleMaxDurability)
    model:SetAttribute("VehicleType",vehicleId)
    model.Parent= vehicleFolder

    activeVehicles[player.UserId] = model
    NotifyPlayer:FireClient(player, "🚗 Spawned your " .. vehicleId .. "!", "blue")
    return true, model.Name
end

-- ─── Repair Vehicle ───────────────────────────────────────────────────────────
RepairVehicle.OnServerInvoke = function(player, vehicleModelName)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end
    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    local model = vehicleFolder:FindFirstChild(vehicleModelName)
    if not model then return false, "Vehicle not found" end

    if model:GetAttribute("OwnerId") ~= player.UserId and data.Profession ~= "Mechanic" then
        return false, "Not your vehicle"
    end

    local durability = model:GetAttribute("Durability") or 0
    local needed     = GameConfig.VehicleMaxDurability - durability
    if needed <= 0 then return false, "Vehicle is already in perfect condition" end

    local cost = needed * GameConfig.VehicleRepairCostPerPoint
    if not PDM.SubtractMoney(player, cost) then
        return false, "Need $" .. cost .. " to repair"
    end

    model:SetAttribute("Durability", GameConfig.VehicleMaxDurability)
    NotifyPlayer:FireClient(player, "🔧 Vehicle fully repaired for $" .. cost, "green")
    return true, "Repaired"
end

-- ─── Durability Wear Tracking ─────────────────────────────────────────────────
-- Monitors VehicleSeat occupant and applies wear over time
RunService.Heartbeat:Connect(function(dt)
    for _, model in ipairs(vehicleFolder:GetChildren()) do
        if model:IsA("Model") then
            local seat = model:FindFirstChild("DriverSeat")
            if seat and seat:IsA("VehicleSeat") and seat.Occupant then
                local durability = model:GetAttribute("Durability") or 0
                if durability > 0 then
                    -- Simple wear: lose ~0.1 durability per second while occupied
                    local newDur = math.max(0, durability - dt * 0.1)
                    model:SetAttribute("Durability", newDur)

                    if newDur <= 0 then
                        -- Vehicle breaks down — eject occupant
                        local humanoid = seat.Occupant
                        if humanoid then
                            humanoid.Sit = false
                        end
                        -- Notify owner
                        local ownerId = model:GetAttribute("OwnerId")
                        if ownerId then
                            local owner = Players:GetPlayerByUserId(ownerId)
                            if owner then
                                NotifyPlayer:FireClient(owner, "🚗 Your vehicle has broken down! Take it to the Mechanic.", "red")
                            end
                        end
                        seat.MaxSpeed = 0  -- Disable driving
                    end
                end
            end
        end
    end
end)

-- Cleanup vehicles when player leaves
Players.PlayerRemoving:Connect(function(player)
    if activeVehicles[player.UserId] then
        activeVehicles[player.UserId]:Destroy()
        activeVehicles[player.UserId] = nil
    end
end)

print("[VehicleManager] Ready")
