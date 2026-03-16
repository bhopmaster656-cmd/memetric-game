-- StarterGui/ProfessionGui/Script.client.lua
-- Profession selection screen shown when visiting the Town Hall.

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local screenGui = script.Parent
screenGui.Enabled = false

local GameConfig       = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ProfessionData   = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfessionData"))

local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local SetProfession    = RemoteEvents:WaitForChild("SetProfession")
local NotifyPlayer     = RemoteEvents:WaitForChild("NotifyPlayer")

local currentProfession = "Unemployed"

-- ─── Build UI ─────────────────────────────────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name                = "ProfFrame"
mainFrame.Size                = UDim2.new(0, 680, 0, 520)
mainFrame.Position            = UDim2.new(0.5, -340, 0.5, -260)
mainFrame.BackgroundColor3    = Color3.fromRGB(18, 22, 35)
mainFrame.BorderSizePixel     = 0
mainFrame.Parent              = screenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title
local titleBar = Instance.new("Frame")
titleBar.Name             = "TitleBar"
titleBar.Size             = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 50, 100)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size            = UDim2.new(1, -60, 1, 0)
titleLabel.Position        = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3      = Color3.new(1, 1, 1)
titleLabel.Font            = Enum.Font.GothamBold
titleLabel.TextScaled      = true
titleLabel.TextXAlignment  = Enum.TextXAlignment.Left
titleLabel.Text            = "🎓 Choose Your Profession — Town Hall"
titleLabel.Parent          = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size              = UDim2.new(0, 40, 0, 40)
closeBtn.Position          = UDim2.new(1, -45, 0, 7)
closeBtn.BackgroundColor3  = Color3.fromRGB(200, 60, 60)
closeBtn.BorderSizePixel   = 0
closeBtn.TextColor3        = Color3.new(1, 1, 1)
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.TextScaled        = true
closeBtn.Text              = "✕"
closeBtn.Parent            = titleBar
local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- Current profession indicator
local currentProfLabel = Instance.new("TextLabel")
currentProfLabel.Name           = "CurrentProf"
currentProfLabel.Size           = UDim2.new(1, -20, 0, 30)
currentProfLabel.Position       = UDim2.new(0, 10, 0, 58)
currentProfLabel.BackgroundTransparency = 1
currentProfLabel.TextColor3     = Color3.fromRGB(150, 200, 255)
currentProfLabel.Font           = Enum.Font.GothamBold
currentProfLabel.TextScaled     = true
currentProfLabel.TextXAlignment = Enum.TextXAlignment.Left
currentProfLabel.Text           = "Current Profession: Unemployed"
currentProfLabel.Parent         = mainFrame

-- Scrolling profession list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size             = UDim2.new(1, -10, 1, -100)
scrollFrame.Position         = UDim2.new(0, 5, 0, 95)
scrollFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
scrollFrame.BorderSizePixel  = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize       = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent           = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent  = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingAll = UDim.new(0, 8)
listPadding.Parent     = scrollFrame

-- ─── Populate Professions ─────────────────────────────────────────────────────
local function populateProfessions()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, prof in ipairs(ProfessionData.List) do
        local row = Instance.new("Frame")
        row.Name               = "ProfRow_" .. prof.Name
        row.Size               = UDim2.new(1, 0, 0, 100)
        row.BackgroundColor3   = currentProfession == prof.Name
            and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(22, 28, 45)
        row.BorderSizePixel    = 0
        row.Parent             = scrollFrame
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row

        -- Icon + Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size          = UDim2.new(0.35, 0, 0.4, 0)
        nameLabel.Position      = UDim2.new(0, 10, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3    = Color3.new(1, 1, 1)
        nameLabel.Font          = Enum.Font.GothamBold
        nameLabel.TextScaled    = true
        nameLabel.TextXAlignment= Enum.TextXAlignment.Left
        nameLabel.Text          = prof.Icon .. " " .. prof.Name
        nameLabel.Parent        = row

        -- Description
        local descLabel = Instance.new("TextLabel")
        descLabel.Size          = UDim2.new(0.6, 0, 0.55, 0)
        descLabel.Position      = UDim2.new(0, 10, 0, 42)
        descLabel.BackgroundTransparency = 1
        descLabel.TextColor3    = Color3.fromRGB(180, 180, 200)
        descLabel.Font          = Enum.Font.Gotham
        descLabel.TextScaled    = true
        descLabel.TextWrapped   = true
        descLabel.TextXAlignment= Enum.TextXAlignment.Left
        descLabel.Text          = prof.Description
        descLabel.Parent        = row

        -- License cost
        local cost = GameConfig.ProfessionLicenseCost[prof.Name] or 0
        local costLabel = Instance.new("TextLabel")
        costLabel.Size          = UDim2.new(0.25, 0, 0.35, 0)
        costLabel.Position      = UDim2.new(0.7, 0, 0, 6)
        costLabel.BackgroundTransparency = 1
        costLabel.TextColor3    = cost > 0 and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(100, 220, 100)
        costLabel.Font          = Enum.Font.GothamBold
        costLabel.TextScaled    = true
        costLabel.Text          = cost > 0 and ("License: $" .. cost) or "Free"
        costLabel.Parent        = row

        -- Select button
        local selectBtn = Instance.new("TextButton")
        selectBtn.Size             = UDim2.new(0, 90, 0, 34)
        selectBtn.Position         = UDim2.new(1, -98, 1, -42)
        selectBtn.BackgroundColor3 = currentProfession == prof.Name
            and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(50, 130, 200)
        selectBtn.BorderSizePixel  = 0
        selectBtn.TextColor3       = Color3.new(1, 1, 1)
        selectBtn.Font             = Enum.Font.GothamBold
        selectBtn.TextScaled       = true
        selectBtn.Text             = currentProfession == prof.Name and "✓ Active" or "Select"
        selectBtn.Active           = currentProfession ~= prof.Name
        selectBtn.Parent           = row
        local selectCorner = Instance.new("UICorner")
        selectCorner.CornerRadius = UDim.new(0, 6)
        selectCorner.Parent = selectBtn

        if currentProfession ~= prof.Name then
            selectBtn.MouseButton1Click:Connect(function()
                local ok, result = SetProfession:InvokeServer(prof.Name)
                if ok then
                    currentProfession = prof.Name
                    currentProfLabel.Text = "Current Profession: " .. prof.Name
                    populateProfessions()  -- Refresh
                end
            end)
        end
    end

    -- Update canvas
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #ProfessionData.List * 106 + 16)
end

-- ─── Show/Hide ────────────────────────────────────────────────────────────────
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if screenGui.Enabled then
        populateProfessions()
    end
end)

print("[ProfessionGui] Ready")
