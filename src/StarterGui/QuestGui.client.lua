--[[
    QuestGui.client.lua  (StarterGui)
    Displays active quests and progress.
    Toggle with [Q] key.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local Modules      = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames  = require(Modules.RemoteEvents)
local QuestConfig  = require(Modules.QuestConfig)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── ScreenGui ───────────────────────────────────────────────────────────────
local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "QuestGui"
screenGui.DisplayOrder = 30
screenGui.ResetOnSpawn = false
screenGui.Parent       = PlayerGui

local panel             = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 420, 0, 500)
panel.Position          = UDim2.new(1, -430, 0.5, -250)
panel.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
panel.BackgroundTransparency = 0.05
panel.Visible           = false
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent       = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size  = UDim2.new(1, -10, 0, 50)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text  = "📜 Quests"
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

local scroll = Instance.new("ScrollingFrame")
scroll.Size  = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 55)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding   = UDim.new(0, 8)
listLayout.Parent    = scroll

-- ─── Quest card builder ──────────────────────────────────────────────────────
local function makeQuestCard(quest, questData, order)
    local completed = questData and questData.Completed
    local progress  = questData and questData.Progress or 0

    local card = Instance.new("Frame")
    card.Size  = UDim2.new(1, -10, 0, 80)
    card.BackgroundColor3 = completed
        and Color3.fromRGB(20, 60, 20)
        or  Color3.fromRGB(30, 30, 30)
    card.LayoutOrder = order
    card.Parent      = scroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size  = UDim2.new(1, -10, 0, 28)
    nameLabel.Position = UDim2.new(0, 10, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text  = (completed and "✅ " or "⬜ ") .. quest.Name
    nameLabel.TextColor3 = completed
        and Color3.fromRGB(100, 255, 100)
        or  Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font  = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size  = UDim2.new(1, -10, 0, 20)
    descLabel.Position = UDim2.new(0, 10, 0, 32)
    descLabel.BackgroundTransparency = 1
    descLabel.Text  = quest.Description
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLabel.TextScaled = true
    descLabel.Font  = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = card

    -- Progress bar
    local barBg = Instance.new("Frame")
    barBg.Size  = UDim2.new(1, -20, 0, 10)
    barBg.Position = UDim2.new(0, 10, 0, 56)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barBg.BorderSizePixel  = 0
    barBg.Parent = card

    local barBgCorner = Instance.new("UICorner")
    barBgCorner.CornerRadius = UDim.new(1, 0)
    barBgCorner.Parent = barBg

    local ratio = math.clamp(progress / quest.Goal, 0, 1)
    local barFill = Instance.new("Frame")
    barFill.Size  = UDim2.new(ratio, 0, 1, 0)
    barFill.BackgroundColor3 = completed
        and Color3.fromRGB(80, 200, 80)
        or  Color3.fromRGB(80, 160, 255)
    barFill.BorderSizePixel  = 0
    barFill.Parent = barBg

    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(1, 0)
    barFillCorner.Parent = barFill

    -- Reward label
    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size  = UDim2.new(0.4, 0, 0, 20)
    rewardLabel.Position = UDim2.new(0.6, 0, 0, 56)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text  = "💰 " .. (quest.Reward.Coins or 0)
        .. "  " .. progress .. "/" .. quest.Goal
    rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    rewardLabel.TextScaled = true
    rewardLabel.Font  = Enum.Font.GothamSemibold
    rewardLabel.Parent = card

    return card
end

-- ─── Rebuild list ────────────────────────────────────────────────────────────
local currentQuestData = {}

local function refreshQuests()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for i, q in ipairs(QuestConfig.QUESTS) do
        makeQuestCard(q, currentQuestData[q.Id], i)
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0,
        #QuestConfig.QUESTS * 88 + (#QuestConfig.QUESTS - 1) * 8
    )
end

-- ─── Toggle ──────────────────────────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Q then
        panel.Visible = not panel.Visible
        if panel.Visible then refreshQuests() end
    end
end)

-- ─── Remote listeners ────────────────────────────────────────────────────────
RE(RemoteNames.UpdateQuests).OnClientEvent:Connect(function(questData)
    currentQuestData = questData or {}
    if panel.Visible then refreshQuests() end
end)

RE(RemoteNames.QuestComplete).OnClientEvent:Connect(function(questId, reward)
    -- Show a toast notification
    local toast = Instance.new("TextLabel")
    toast.Size  = UDim2.new(0, 300, 0, 50)
    toast.Position = UDim2.new(0.5, -150, 0.1, 0)
    toast.BackgroundColor3 = Color3.fromRGB(20, 120, 20)
    toast.BackgroundTransparency = 0.1
    toast.Text  = "✅ Quest Complete! +" .. (reward.Coins or 0) .. " coins"
    toast.TextColor3 = Color3.fromRGB(255, 255, 255)
    toast.TextScaled = true
    toast.Font  = Enum.Font.GothamBold
    toast.ZIndex = 50
    toast.Parent = screenGui

    local toastCorner = Instance.new("UICorner")
    toastCorner.CornerRadius = UDim.new(0, 10)
    toastCorner.Parent = toast

    task.delay(3, function() toast:Destroy() end)
end)
