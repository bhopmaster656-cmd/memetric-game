--[[
    HUD.client.lua  (StarterGui)
    Displays current coins, rebirth level, and VIP badge.
    Updates whenever the server fires UpdateCoins or UpdateStats.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(Modules.RemoteEvents)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Build HUD ScreenGui ─────────────────────────────────────────────────────
local screenGui       = Instance.new("ScreenGui")
screenGui.Name        = "HUD"
screenGui.DisplayOrder = 20
screenGui.ResetOnSpawn = false
screenGui.Parent      = PlayerGui

-- Coin display
local coinFrame        = Instance.new("Frame")
coinFrame.Size         = UDim2.new(0, 200, 0, 50)
coinFrame.Position     = UDim2.new(0, 10, 0, 10)
coinFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
coinFrame.BackgroundTransparency = 0.3
coinFrame.BorderSizePixel = 0
coinFrame.Parent       = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent       = coinFrame

local coinLabel        = Instance.new("TextLabel")
coinLabel.Name         = "CoinLabel"
coinLabel.Size         = UDim2.new(1, 0, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text         = "💰 0"
coinLabel.TextColor3   = Color3.fromRGB(255, 215, 0)
coinLabel.TextScaled   = true
coinLabel.Font         = Enum.Font.GothamBold
coinLabel.Parent       = coinFrame

-- Rebirth / stats bar
local statsFrame        = Instance.new("Frame")
statsFrame.Size         = UDim2.new(0, 200, 0, 40)
statsFrame.Position     = UDim2.new(0, 10, 0, 70)
statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statsFrame.BackgroundTransparency = 0.3
statsFrame.BorderSizePixel = 0
statsFrame.Parent       = screenGui

local uiCorner2 = Instance.new("UICorner")
uiCorner2.CornerRadius = UDim.new(0, 8)
uiCorner2.Parent       = statsFrame

local rebirthLabel       = Instance.new("TextLabel")
rebirthLabel.Name        = "RebirthLabel"
rebirthLabel.Size        = UDim2.new(1, 0, 1, 0)
rebirthLabel.BackgroundTransparency = 1
rebirthLabel.Text        = "♻️ Rebirth 0"
rebirthLabel.TextColor3  = Color3.fromRGB(100, 220, 255)
rebirthLabel.TextScaled  = true
rebirthLabel.Font        = Enum.Font.GothamSemibold
rebirthLabel.Parent      = statsFrame

-- VIP badge (hidden by default)
local vipLabel        = Instance.new("TextLabel")
vipLabel.Name         = "VIPLabel"
vipLabel.Size         = UDim2.new(0, 80, 0, 30)
vipLabel.Position     = UDim2.new(0, 220, 0, 10)
vipLabel.BackgroundColor3 = Color3.fromRGB(180, 0, 200)
vipLabel.BackgroundTransparency = 0.2
vipLabel.Text         = "👑 VIP"
vipLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
vipLabel.TextScaled   = true
vipLabel.Font         = Enum.Font.GothamBold
vipLabel.Visible      = false
vipLabel.Parent       = screenGui

local uiCorner3 = Instance.new("UICorner")
uiCorner3.CornerRadius = UDim.new(0, 8)
uiCorner3.Parent       = vipLabel

-- ─── Sync leaderstats to HUD ─────────────────────────────────────────────────
local function syncLeaderStats()
    local ls = localPlayer:FindFirstChild("leaderstats")
    if not ls then return end
    local coins    = ls:FindFirstChild("Coins")
    local rebirths = ls:FindFirstChild("Rebirths")
    if coins    then coinLabel.Text    = "💰 " .. tostring(coins.Value)    end
    if rebirths then rebirthLabel.Text = "♻️ Rebirth " .. tostring(rebirths.Value) end
end

-- Wait for leaderstats
task.spawn(function()
    local ls = localPlayer:WaitForChild("leaderstats", 10)
    if not ls then return end
    ls.ChildAdded:Connect(function() syncLeaderStats() end)
    ls.ChildRemoved:Connect(function() syncLeaderStats() end)
    for _, child in ipairs(ls:GetChildren()) do
        child.Changed:Connect(syncLeaderStats)
    end
    syncLeaderStats()
end)

-- ─── Remote listeners ────────────────────────────────────────────────────────
RE(RemoteNames.UpdateCoins).OnClientEvent:Connect(function(coins)
    coinLabel.Text = "💰 " .. tostring(coins)
end)

RE(RemoteNames.UpdateStats).OnClientEvent:Connect(function(stats)
    vipLabel.Visible = stats.IsVIP == true
end)
