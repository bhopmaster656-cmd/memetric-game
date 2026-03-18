--[[
    RebirthGui.client.lua  (StarterGui)
    Confirm-dialog for the rebirth mechanic.
    Toggle with [R] key or Rebirth button.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(Modules.RemoteEvents)
local GameConfig  = require(Modules.GameConfig)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── ScreenGui ───────────────────────────────────────────────────────────────
local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "RebirthGui"
screenGui.DisplayOrder = 30
screenGui.ResetOnSpawn = false
screenGui.Parent       = PlayerGui

local panel             = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 400, 0, 280)
panel.Position          = UDim2.new(0.5, -200, 0.5, -140)
panel.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0.05
panel.Visible           = false
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent       = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size  = UDim2.new(1, 0, 0, 60)
titleLabel.BackgroundTransparency = 1
titleLabel.Text  = "♻️ Rebirth"
titleLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
titleLabel.TextScaled = true
titleLabel.Font  = Enum.Font.GothamBold
titleLabel.Parent = panel

local infoLabel = Instance.new("TextLabel")
infoLabel.Size  = UDim2.new(1, -20, 0, 80)
infoLabel.Position = UDim2.new(0, 10, 0, 60)
infoLabel.BackgroundTransparency = 1
infoLabel.Text  = string.format(
    "Reset your coins & inventory for +%.0f%% luck\nand +%.0f%% coins per level.\n\nCost: %d coins",
    GameConfig.REBIRTH_LUCK_BONUS * 100,
    GameConfig.REBIRTH_COIN_BONUS * 100,
    GameConfig.REBIRTH_COST
)
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextScaled = true
infoLabel.Font  = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size  = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 145)
statusLabel.BackgroundTransparency = 1
statusLabel.Text  = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
statusLabel.TextScaled = true
statusLabel.Font  = Enum.Font.GothamSemibold
statusLabel.Parent = panel

-- Confirm / Cancel buttons
local confirmBtn = Instance.new("TextButton")
confirmBtn.Size  = UDim2.new(0, 160, 0, 50)
confirmBtn.Position = UDim2.new(0, 20, 1, -70)
confirmBtn.Text  = "✅ Rebirth!"
confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
confirmBtn.Font  = Enum.Font.GothamBold
confirmBtn.TextScaled = true
confirmBtn.Parent = panel

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 10)
confirmCorner.Parent = confirmBtn

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size  = UDim2.new(0, 160, 0, 50)
cancelBtn.Position = UDim2.new(1, -180, 1, -70)
cancelBtn.Text  = "❌ Cancel"
cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
cancelBtn.Font  = Enum.Font.GothamBold
cancelBtn.TextScaled = true
cancelBtn.Parent = panel

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 10)
cancelCorner.Parent = cancelBtn

-- ─── Interactions ────────────────────────────────────────────────────────────
confirmBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = "⏳ Processing…"
    confirmBtn.Active = false
    RE(RemoteNames.RequestRebirth):FireServer()
end)

cancelBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

RE(RemoteNames.RebirthResult).OnClientEvent:Connect(function(result)
    confirmBtn.Active = true
    if result.Success then
        statusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        statusLabel.Text = "🎉 Rebirth " .. result.Level .. " reached!"
        task.delay(2, function()
            panel.Visible  = false
            statusLabel.Text = ""
        end)
    else
        statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        statusLabel.Text = "❌ " .. (result.Reason or "Failed.")
    end
end)

-- ─── Toggle ──────────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.R then
        panel.Visible = not panel.Visible
        statusLabel.Text = ""
    end
end)
