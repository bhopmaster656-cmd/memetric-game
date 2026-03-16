-- StarterPlayer/StarterPlayerScripts/VehicleClient.client.lua
-- Client-side vehicle: enter/exit management, speed display, durability warning.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local player = Players.LocalPlayer

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local SpawnVehicle  = RemoteEvents:WaitForChild("SpawnVehicle")
local RepairVehicle = RemoteEvents:WaitForChild("RepairVehicle")
local NotifyPlayer  = RemoteEvents:WaitForChild("NotifyPlayer")

-- ─── Speed HUD (shown while in vehicle) ──────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "VehicleHUD"
screenGui.DisplayOrder   = 25
screenGui.ResetOnSpawn   = false
screenGui.Enabled        = false
screenGui.Parent         = player:WaitForChild("PlayerGui")

local speedLabel = Instance.new("TextLabel")
speedLabel.Name           = "SpeedLabel"
speedLabel.Size           = UDim2.new(0, 200, 0, 60)
speedLabel.Position       = UDim2.new(0.5, -100, 0.85, 0)
speedLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
speedLabel.BackgroundTransparency = 0.5
speedLabel.TextColor3     = Color3.new(1, 1, 1)
speedLabel.Font           = Enum.Font.GothamBold
speedLabel.TextScaled     = true
speedLabel.Text           = "🚗 0 mph"
speedLabel.Parent         = screenGui

local durabilityLabel = Instance.new("TextLabel")
durabilityLabel.Name      = "DurabilityLabel"
durabilityLabel.Size      = UDim2.new(0, 200, 0, 40)
durabilityLabel.Position  = UDim2.new(0.5, -100, 0.92, 0)
durabilityLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
durabilityLabel.BackgroundTransparency = 0.5
durabilityLabel.TextColor3= Color3.new(0, 1, 0)
durabilityLabel.Font      = Enum.Font.Gotham
durabilityLabel.TextScaled= true
durabilityLabel.Text      = "Durability: 100%"
durabilityLabel.Parent    = screenGui

-- ─── Track Current Vehicle ───────────────────────────────────────────────────
local currentVehicle = nil
local currentSeat    = nil

local function findPlayerVehicle()
    local vehicleFolder = Workspace:FindFirstChild("Vehicles")
    if not vehicleFolder then return nil, nil end
    for _, model in ipairs(vehicleFolder:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("OwnerId") == player.UserId then
            local seat = model:FindFirstChild("DriverSeat")
            if seat and seat:IsA("VehicleSeat") then
                return model, seat
            end
        end
    end
    return nil, nil
end

-- ─── E key: Enter/Exit vehicle ───────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= Enum.KeyCode.E then return end

    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Check if already seated
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        -- Exit vehicle
        humanoid.Sit = false
        screenGui.Enabled = false
        currentVehicle = nil
        currentSeat    = nil
        return
    end

    -- Look for nearby vehicle
    local model, seat = findPlayerVehicle()
    if model and seat then
        local dist = (root.Position - seat.Position).Magnitude
        if dist <= 15 then
            seat:Sit(humanoid)
            currentVehicle = model
            currentSeat    = seat
            screenGui.Enabled = true
        end
    end
end)

-- ─── Speed & Durability Update Loop ─────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not currentSeat or not currentVehicle then return end

    local body = currentVehicle:FindFirstChild("VehicleBody")
    if body then
        local velocity = body.AssemblyLinearVelocity
        local speed    = math.floor(velocity.Magnitude * 2.237)  -- convert to mph approx
        speedLabel.Text = "🚗 " .. speed .. " mph"
    end

    local dur = currentVehicle:GetAttribute("Durability") or 100
    local pct = math.floor(dur)
    durabilityLabel.Text = "Durability: " .. pct .. "%"
    if pct < 25 then
        durabilityLabel.TextColor3 = Color3.new(1, 0, 0)
    elseif pct < 50 then
        durabilityLabel.TextColor3 = Color3.new(1, 1, 0)
    else
        durabilityLabel.TextColor3 = Color3.new(0, 1, 0)
    end
end)

-- ─── Quick Spawn Keybind (F key opens vehicle spawn UI) ──────────────────────
-- Actual spawn is done via the HUD. This is just a shortcut.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        local model, seat = findPlayerVehicle()
        if not model then
            -- Try to spawn bicycle (default)
            SpawnVehicle:InvokeServer("Bicycle")
        end
    end
end)

print("[VehicleClient] Ready")
