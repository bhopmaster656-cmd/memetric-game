--[[
    FishingUI.client.lua  (StarterGui)
    Shows cast state, bite alert, and catch result popup.

    FishingController (StarterPlayerScripts) fires BindableEvents that this
    script listens to, keeping input logic separate from UI logic.
--]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules     = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(Modules.RemoteEvents)

local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local function RE(name) return reFolder:WaitForChild(name) end

local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")

-- ─── Screen GUI ──────────────────────────────────────────────────────────────
local screenGui        = Instance.new("ScreenGui")
screenGui.Name         = "FishingUI"
screenGui.DisplayOrder = 15
screenGui.ResetOnSpawn = false
screenGui.Parent       = PlayerGui

-- ── Expose BindableEvents so FishingController can trigger UI ────────────────
local function makeBindable(name)
    local b = Instance.new("BindableEvent")
    b.Name  = name
    b.Parent = screenGui
    return b
end
local onCast        = makeBindable("OnCast")
local onBite        = makeBindable("OnBite")
local onCatchResult = makeBindable("OnCatchResult")

-- ── Bottom hint label ─────────────────────────────────────────────────────────
local hintLabel        = Instance.new("TextLabel")
hintLabel.Name         = "HintLabel"
hintLabel.Size         = UDim2.new(0.4, 0, 0, 50)
hintLabel.Position     = UDim2.new(0.3, 0, 0.85, 0)
hintLabel.AnchorPoint  = Vector2.new(0, 0)
hintLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hintLabel.BackgroundTransparency = 0.4
hintLabel.Text         = "Press [E] to cast your rod"
hintLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
hintLabel.TextScaled   = true
hintLabel.Font         = Enum.Font.GothamSemibold
hintLabel.Parent       = screenGui

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 10)
hintCorner.Parent       = hintLabel

-- ── Catch result popup ───────────────────────────────────────────────────────
local popup        = Instance.new("Frame")
popup.Name         = "CatchPopup"
popup.Size         = UDim2.new(0, 320, 0, 160)
popup.Position     = UDim2.new(0.5, -160, 0.3, 0)
popup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
popup.BackgroundTransparency = 0.1
popup.Visible      = false
popup.Parent       = screenGui

local popupCorner  = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 12)
popupCorner.Parent = popup

local popupTitle   = Instance.new("TextLabel")
popupTitle.Name    = "Title"
popupTitle.Size    = UDim2.new(1, 0, 0.4, 0)
popupTitle.BackgroundTransparency = 1
popupTitle.Text    = "🎣 You caught something!"
popupTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
popupTitle.TextScaled = true
popupTitle.Font    = Enum.Font.GothamBold
popupTitle.Parent  = popup

local popupBody    = Instance.new("TextLabel")
popupBody.Name     = "Body"
popupBody.Size     = UDim2.new(1, -10, 0.6, 0)
popupBody.Position = UDim2.new(0, 5, 0.4, 0)
popupBody.BackgroundTransparency = 1
popupBody.Text     = ""
popupBody.TextColor3 = Color3.fromRGB(230, 230, 230)
popupBody.TextScaled = true
popupBody.Font     = Enum.Font.Gotham
popupBody.Parent   = popup

-- ─── State machine ───────────────────────────────────────────────────────────
local RARITY_COLORS = {
    Normal  = Color3.fromRGB(200, 200, 200),
    Golden  = Color3.fromRGB(255, 215, 0),
    Diamond = Color3.fromRGB(100, 220, 255),
}

onCast.Event:Connect(function()
    hintLabel.Text = "🎣 Casting… wait for a bite!"
    popup.Visible  = false
end)

onBite.Event:Connect(function()
    hintLabel.Text            = "⚡ FISH ON! Press [E] to reel in!"
    hintLabel.TextColor3      = Color3.fromRGB(255, 80, 80)
    -- Flash effect
    local flash = TweenService:Create(hintLabel,
        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 4, true),
        { TextColor3 = Color3.fromRGB(255, 215, 0) }
    )
    flash:Play()
    flash.Completed:Connect(function()
        hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end)

onCatchResult.Event:Connect(function(result)
    hintLabel.Text       = "Press [E] to cast your rod"
    hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    if result.Success then
        local color = RARITY_COLORS[result.Rarity] or Color3.fromRGB(255, 255, 255)
        popupTitle.TextColor3 = color
        popupTitle.Text       = "🎣 " .. result.Rarity .. " Catch!"
        popupBody.Text        = result.Brainrot.Name
            .. "\n+" .. tostring(result.Coins) .. " coins"
        popup.Visible         = true

        -- Auto-hide after 3 seconds
        task.delay(3, function()
            if popup.Visible then popup.Visible = false end
        end)
    else
        hintLabel.Text = "🐟 The fish got away! Press [E] to try again."
    end
end)
