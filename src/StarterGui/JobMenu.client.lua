-- JobMenu.client.lua
-- StarterGui
-- Shows a list of available jobs; player can join or leave a job.

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RE        = require(RS:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- ── Screen Gui ────────────────────────────────────────────────────────────────
local gui           = Instance.new("ScreenGui")
gui.Name            = "JobMenu"
gui.ResetOnSpawn    = false
gui.DisplayOrder    = 20
gui.Enabled         = false
gui.Parent          = playerGui

-- ── Main window ───────────────────────────────────────────────────────────────
local window        = Instance.new("Frame")
window.Name         = "Window"
window.Size         = UDim2.new(0, 500, 0, 520)
window.Position     = UDim2.new(0.5, -250, 0.5, -260)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
window.BackgroundTransparency = 0.05
window.BorderSizePixel = 0
window.Parent       = gui

local corner        = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent       = window

-- Title bar
local title         = Instance.new("TextLabel")
title.Size          = UDim2.new(1, -40, 0, 50)
title.Position      = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text          = "💼 Choose Your Job"
title.TextColor3    = Color3.new(1,1,1)
title.Font          = Enum.Font.GothamBold
title.TextScaled    = true
title.Parent        = window

-- Close button
local closeBtn      = Instance.new("TextButton")
closeBtn.Size       = UDim2.new(0, 36, 0, 36)
closeBtn.Position   = UDim2.new(1, -42, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text       = "✕"
closeBtn.Font       = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.Parent     = window
Instance.new("UICorner").Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- Scroll frame for job cards
local scroll        = Instance.new("ScrollingFrame")
scroll.Size         = UDim2.new(1, -10, 1, -60)
scroll.Position     = UDim2.new(0, 5, 0, 55)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 5
scroll.BorderSizePixel = 0
scroll.CanvasSize   = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent       = window

local listLayout    = Instance.new("UIListLayout")
listLayout.Padding  = UDim.new(0, 6)
listLayout.Parent   = scroll

local padding       = Instance.new("UIPadding")
padding.PaddingLeft  = UDim.new(0, 6)
padding.PaddingRight = UDim.new(0, 6)
padding.Parent       = scroll

-- ── Populate jobs ──────────────────────────────────────────────────────────────
local function buildJobCards(jobList)
    -- Clear existing cards
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, job in ipairs(jobList) do
        local card      = Instance.new("Frame")
        card.Size       = UDim2.new(1, 0, 0, 68)
        card.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        card.BorderSizePixel = 0
        card.Parent     = scroll
        Instance.new("UICorner").Parent = card

        local nameLbl   = Instance.new("TextLabel")
        nameLbl.Size    = UDim2.new(0.55, 0, 0.5, 0)
        nameLbl.Position = UDim2.new(0, 8, 0, 4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text    = job.name
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.Font    = Enum.Font.GothamBold
        nameLbl.TextScaled = true
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent  = card

        local salaryLbl = Instance.new("TextLabel")
        salaryLbl.Size  = UDim2.new(0.55, 0, 0.45, 0)
        salaryLbl.Position = UDim2.new(0, 8, 0.5, 0)
        salaryLbl.BackgroundTransparency = 1
        salaryLbl.Text  = "💵 $" .. job.salary .. "/min  |  " .. job.current .. "/" .. job.maxSlots .. " slots"
        salaryLbl.TextColor3 = Color3.fromRGB(160,220,160)
        salaryLbl.Font  = Enum.Font.Gotham
        salaryLbl.TextScaled = true
        salaryLbl.TextXAlignment = Enum.TextXAlignment.Left
        salaryLbl.Parent = card

        local joinBtn   = Instance.new("TextButton")
        joinBtn.Size    = UDim2.new(0, 90, 0, 36)
        joinBtn.Position = UDim2.new(1, -98, 0.5, -18)
        joinBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        joinBtn.Text    = "Join"
        joinBtn.Font    = Enum.Font.GothamBold
        joinBtn.TextScaled = true
        joinBtn.BorderSizePixel = 0
        joinBtn.Parent  = card
        Instance.new("UICorner").Parent = joinBtn

        joinBtn.MouseButton1Click:Connect(function()
            RE.AssignJob:FireServer(job.id)
            gui.Enabled = false
        end)
    end
end

-- Leave job button at bottom
local leaveBtn      = Instance.new("TextButton")
leaveBtn.Size       = UDim2.new(0, 140, 0, 38)
leaveBtn.Position   = UDim2.new(0.5, -70, 1, -46)
leaveBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
leaveBtn.Text       = "Leave Current Job"
leaveBtn.Font       = Enum.Font.GothamBold
leaveBtn.TextScaled = true
leaveBtn.BorderSizePixel = 0
leaveBtn.Parent     = window
Instance.new("UICorner").Parent = leaveBtn
leaveBtn.MouseButton1Click:Connect(function()
    RE.LeaveJob:FireServer()
    gui.Enabled = false
end)

-- Refresh job list when menu opens
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if gui.Enabled then
        task.spawn(function()
            local jobs = RE.GetJobInfo:InvokeServer()
            if jobs then buildJobCards(jobs) end
        end)
    end
end)

print("[JobMenu] Loaded.")
