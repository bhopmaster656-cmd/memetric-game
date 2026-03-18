--[[
    SpinGui.client.lua  (StarterGui)
    Displays the daily spin wheel.
    Toggle with [X] key or Spin button.

    Segments are laid out as colored arcs around a central wheel.
    After RequestSpin succeeds the server returns SpinResult with the winning
    reward; the UI animates to that segment.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(Modules.RemoteEvents)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── ScreenGui ───────────────────────────────────────────────────────────────
local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "SpinGui"
screenGui.DisplayOrder = 30
screenGui.ResetOnSpawn = false
screenGui.Parent       = PlayerGui

local panel             = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 480, 0, 520)
panel.Position          = UDim2.new(0.5, -240, 0.5, -260)
panel.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0.05
panel.Visible           = false
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent       = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size  = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundTransparency = 1
titleLabel.Text  = "🎰 Daily Spin"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font  = Enum.Font.GothamBold
titleLabel.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.Size   = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 5)
closeBtn.Text   = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Font   = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.Parent = panel

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- Segment list (text display – actual animated wheel is decorative)
local segmentScroll = Instance.new("ScrollingFrame")
segmentScroll.Size  = UDim2.new(1, -20, 0, 280)
segmentScroll.Position = UDim2.new(0, 10, 0, 60)
segmentScroll.BackgroundTransparency = 1
segmentScroll.ScrollBarThickness = 4
segmentScroll.Parent = panel

local segLayout = Instance.new("UIListLayout")
segLayout.SortOrder = Enum.SortOrder.LayoutOrder
segLayout.Padding   = UDim.new(0, 4)
segLayout.Parent    = segmentScroll

-- Spin button
local spinBtn = Instance.new("TextButton")
spinBtn.Size  = UDim2.new(0, 200, 0, 55)
spinBtn.Position = UDim2.new(0.5, -100, 1, -70)
spinBtn.Text  = "🎰 SPIN!"
spinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spinBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 180)
spinBtn.Font  = Enum.Font.GothamBold
spinBtn.TextScaled = true
spinBtn.Parent = panel

local spinBtnCorner = Instance.new("UICorner")
spinBtnCorner.CornerRadius = UDim.new(0, 12)
spinBtnCorner.Parent = spinBtn

-- Result label
local resultLabel = Instance.new("TextLabel")
resultLabel.Size  = UDim2.new(1, -20, 0, 40)
resultLabel.Position = UDim2.new(0, 10, 1, -115)
resultLabel.BackgroundTransparency = 1
resultLabel.Text  = ""
resultLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
resultLabel.TextScaled = true
resultLabel.Font  = Enum.Font.GothamBold
resultLabel.Parent = panel

-- Segment colors
local SEG_COLORS = {
    Color3.fromRGB(220, 60,  60),
    Color3.fromRGB(220, 140, 40),
    Color3.fromRGB(200, 200, 40),
    Color3.fromRGB(60,  200, 60),
    Color3.fromRGB(40,  160, 220),
    Color3.fromRGB(120, 60,  220),
    Color3.fromRGB(220, 60,  180),
}

local function buildSegmentList(allRewards)
    for _, c in ipairs(segmentScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, r in ipairs(allRewards) do
        local row = Instance.new("Frame")
        row.Size  = UDim2.new(1, -8, 0, 32)
        row.BackgroundColor3 = SEG_COLORS[((i - 1) % #SEG_COLORS) + 1]
        row.BackgroundTransparency = 0.3
        row.LayoutOrder = i
        row.Parent = segmentScroll

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size  = UDim2.new(1, -10, 1, 0)
        lbl.Position = UDim2.new(0, 5, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text  = r.Label or "?"
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextScaled = true
        lbl.Font  = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
    end
    segmentScroll.CanvasSize = UDim2.new(0, 0, 0,
        #allRewards * 36 + (#allRewards - 1) * 4
    )
end

-- ─── Spin logic ──────────────────────────────────────────────────────────────
local isSpinning = false

spinBtn.MouseButton1Click:Connect(function()
    if isSpinning then return end
    isSpinning = true
    spinBtn.Text = "Spinning…"
    spinBtn.Active = false
    resultLabel.Text = ""
    RE(RemoteNames.RequestSpin):FireServer()
end)

RE(RemoteNames.SpinResult).OnClientEvent:Connect(function(result)
    isSpinning = false
    spinBtn.Active = true

    if result.Success then
        if result.AllRewards then
            buildSegmentList(result.AllRewards)
        end
        -- Animate button briefly then show result
        local tween = TweenService:Create(spinBtn,
            TweenInfo.new(0.4, Enum.EasingStyle.Bounce),
            { Size = UDim2.new(0, 220, 0, 60) }
        )
        tween:Play()
        tween.Completed:Connect(function()
            spinBtn.Size = UDim2.new(0, 200, 0, 55)
        end)
        spinBtn.Text = "🎰 SPIN!"
        local reward = result.Reward
        resultLabel.Text = "🎉 You got: " .. (reward.Label or reward.BrainrotName or "a reward") .. "!"
    else
        spinBtn.Text = "🎰 SPIN!"
        local remaining = result.Remaining or 0
        local hours   = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        resultLabel.Text = string.format(
            "⏳ Next spin in %dh %dm", hours, minutes
        )
    end
end)

-- ─── Toggle ──────────────────────────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.X then
        panel.Visible = not panel.Visible
    end
end)
