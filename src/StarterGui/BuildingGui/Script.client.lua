-- StarterGui/BuildingGui/Script.client.lua
-- Building mode and inventory management GUI.
-- Allows placing/removing items on player's plot and viewing inventory.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local screenGui = script.Parent
screenGui.Enabled = false

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemData     = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemData"))

local RemoteEvents     = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlaceObject      = RemoteEvents:WaitForChild("PlaceObject")
local RemoveObject     = RemoteEvents:WaitForChild("RemoveObject")
local UpdateInventory  = RemoteEvents:WaitForChild("UpdateInventory")
local NotifyPlayer     = RemoteEvents:WaitForChild("NotifyPlayer")

local playerInventory = {}
local currentMode     = "Build"  -- "Build" or "Inventory"
local selectedItem    = nil      -- itemId being placed
local placementPreview= nil      -- The semi-transparent preview part
local placementEnabled= false

UpdateInventory.OnClientEvent:Connect(function(inv)
    playerInventory = inv
    -- Refresh if open
    if screenGui.Enabled then
        -- will be handled by populatePanel()
    end
end)

-- ─── Build UI ─────────────────────────────────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name                = "BuildFrame"
mainFrame.Size                = UDim2.new(0, 650, 0, 480)
mainFrame.Position            = UDim2.new(0.5, -325, 0.5, -240)
mainFrame.BackgroundColor3    = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel     = 0
mainFrame.Parent              = screenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(100, 70, 20)
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
titleLabel.Text            = "🏗️ Build Mode"
titleLabel.Parent          = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size              = UDim2.new(0, 40, 0, 40)
closeBtn.Position          = UDim2.new(1, -45, 0, 5)
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
    placementEnabled = false
    selectedItem     = nil
    if placementPreview then placementPreview:Destroy(); placementPreview = nil end
    screenGui.Enabled = false
end)

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Size            = UDim2.new(1, 0, 0, 36)
tabBar.Position        = UDim2.new(0, 0, 0, 50)
tabBar.BackgroundColor3= Color3.fromRGB(15, 15, 20)
tabBar.BorderSizePixel = 0
tabBar.Parent          = mainFrame

local buildTabBtn = Instance.new("TextButton")
buildTabBtn.Size             = UDim2.new(0.5, 0, 1, 0)
buildTabBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
buildTabBtn.BorderSizePixel  = 0
buildTabBtn.TextColor3       = Color3.new(1, 1, 1)
buildTabBtn.Font             = Enum.Font.GothamBold
buildTabBtn.TextScaled       = true
buildTabBtn.Text             = "🏗️ Build"
buildTabBtn.Parent           = tabBar

local invTabBtn = Instance.new("TextButton")
invTabBtn.Size               = UDim2.new(0.5, 0, 1, 0)
invTabBtn.Position           = UDim2.new(0.5, 0, 0, 0)
invTabBtn.BackgroundColor3   = Color3.fromRGB(25, 25, 35)
invTabBtn.BorderSizePixel    = 0
invTabBtn.TextColor3         = Color3.fromRGB(180, 180, 180)
invTabBtn.Font               = Enum.Font.GothamBold
invTabBtn.TextScaled         = true
invTabBtn.Text               = "🎒 Inventory"
invTabBtn.Parent             = tabBar

-- Scroll list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size             = UDim2.new(1, -10, 1, -100)
scrollFrame.Position         = UDim2.new(0, 5, 0, 92)
scrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
scrollFrame.BorderSizePixel  = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize       = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent           = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent  = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingAll = UDim.new(0, 8)
listPadding.Parent     = scrollFrame

-- Orientation label
local orientLabel = Instance.new("TextLabel")
orientLabel.Size           = UDim2.new(1, -20, 0, 30)
orientLabel.Position       = UDim2.new(0, 10, 1, -35)
orientLabel.BackgroundTransparency = 1
orientLabel.TextColor3     = Color3.fromRGB(180, 180, 100)
orientLabel.Font           = Enum.Font.Gotham
orientLabel.TextScaled     = true
orientLabel.TextXAlignment = Enum.TextXAlignment.Left
orientLabel.Text           = "R: rotate | Click: place | X: cancel"
orientLabel.Parent         = mainFrame

-- ─── Populate Panels ─────────────────────────────────────────────────────────
local function clearItems()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function populateBuildPanel()
    clearItems()
    local count = 0
    for _, slot in ipairs(playerInventory) do
        local item = ItemData.ById[slot.id]
        if item and item.category == ItemData.CATEGORY.FURNITURE then
            count = count + 1
            local row = Instance.new("Frame")
            row.Size               = UDim2.new(1, 0, 0, 48)
            row.BackgroundColor3   = selectedItem == slot.id
                and Color3.fromRGB(80, 60, 20) or Color3.fromRGB(22, 22, 35)
            row.BorderSizePixel    = 0
            row.Parent             = scrollFrame
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 6)
            rowCorner.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size          = UDim2.new(0.6, 0, 1, 0)
            nameLabel.Position      = UDim2.new(0, 8, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3    = Color3.new(1, 1, 1)
            nameLabel.Font          = Enum.Font.Gotham
            nameLabel.TextScaled    = true
            nameLabel.TextXAlignment= Enum.TextXAlignment.Left
            nameLabel.Text          = item.name .. " (x" .. slot.qty .. ")"
            nameLabel.Parent        = row

            local placeBtn = Instance.new("TextButton")
            placeBtn.Size             = UDim2.new(0, 80, 0, 36)
            placeBtn.Position         = UDim2.new(1, -88, 0.5, -18)
            placeBtn.BackgroundColor3 = Color3.fromRGB(150, 90, 20)
            placeBtn.BorderSizePixel  = 0
            placeBtn.TextColor3       = Color3.new(1, 1, 1)
            placeBtn.Font             = Enum.Font.GothamBold
            placeBtn.TextScaled       = true
            placeBtn.Text             = "📍 Place"
            placeBtn.Parent           = row
            local placeCorner = Instance.new("UICorner")
            placeCorner.CornerRadius = UDim.new(0, 6)
            placeCorner.Parent = placeBtn

            placeBtn.MouseButton1Click:Connect(function()
                selectedItem    = slot.id
                placementEnabled= true
                screenGui.Enabled = false  -- Hide GUI while placing
            end)
        end
    end

    if count == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size   = UDim2.new(1, 0, 0, 60)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.Font   = Enum.Font.Gotham
        emptyLabel.TextScaled = true
        emptyLabel.Text   = "No building materials in inventory.\nBuy items from the Government Store."
        emptyLabel.TextWrapped = true
        emptyLabel.Parent = scrollFrame
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 52 + 16)
end

local function populateInventoryPanel()
    clearItems()
    local count = 0
    for _, slot in ipairs(playerInventory) do
        local item = ItemData.ById[slot.id]
        count = count + 1
        local row = Instance.new("Frame")
        row.Size               = UDim2.new(1, 0, 0, 48)
        row.BackgroundColor3   = Color3.fromRGB(22, 22, 35)
        row.BorderSizePixel    = 0
        row.Parent             = scrollFrame
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 6)
        rowCorner.Parent = row

        -- Item name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size          = UDim2.new(0.55, 0, 1, 0)
        nameLabel.Position      = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3    = Color3.new(1, 1, 1)
        nameLabel.Font          = Enum.Font.Gotham
        nameLabel.TextScaled    = true
        nameLabel.TextXAlignment= Enum.TextXAlignment.Left
        nameLabel.Text          = (item and item.name or slot.id)
        nameLabel.Parent        = row

        -- Quantity
        local qtyLabel = Instance.new("TextLabel")
        qtyLabel.Size           = UDim2.new(0.2, 0, 1, 0)
        qtyLabel.Position       = UDim2.new(0.55, 0, 0, 0)
        qtyLabel.BackgroundTransparency = 1
        qtyLabel.TextColor3     = Color3.fromRGB(180, 200, 180)
        qtyLabel.Font           = Enum.Font.GothamBold
        qtyLabel.TextScaled     = true
        qtyLabel.Text           = "x" .. slot.qty
        qtyLabel.Parent         = row

        -- Use button (consumables)
        if item and item.consumable then
            local useBtn = Instance.new("TextButton")
            useBtn.Size             = UDim2.new(0, 70, 0, 36)
            useBtn.Position         = UDim2.new(1, -78, 0.5, -18)
            useBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
            useBtn.BorderSizePixel  = 0
            useBtn.TextColor3       = Color3.new(1, 1, 1)
            useBtn.Font             = Enum.Font.GothamBold
            useBtn.TextScaled       = true
            useBtn.Text             = "Use"
            useBtn.Parent           = row
            local useBtnCorner = Instance.new("UICorner")
            useBtnCorner.CornerRadius = UDim.new(0, 6)
            useBtnCorner.Parent = useBtn

            useBtn.MouseButton1Click:Connect(function()
                -- Fire RemoteEvent to consume item on server
                RemoteEvents:WaitForChild("UseItem"):FireServer(slot.id)
            end)
        end
    end

    if count == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size   = UDim2.new(1, 0, 0, 60)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.Font   = Enum.Font.Gotham
        emptyLabel.TextScaled = true
        emptyLabel.Text   = "Your inventory is empty."
        emptyLabel.Parent = scrollFrame
    end

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 52 + 16)
end

-- Tab switching
buildTabBtn.MouseButton1Click:Connect(function()
    currentMode = "Build"
    buildTabBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 20)
    invTabBtn.BackgroundColor3   = Color3.fromRGB(25, 25, 35)
    titleLabel.Text = "🏗️ Build Mode"
    populateBuildPanel()
end)

invTabBtn.MouseButton1Click:Connect(function()
    currentMode = "Inventory"
    invTabBtn.BackgroundColor3   = Color3.fromRGB(80, 80, 20)
    buildTabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    titleLabel.Text = "🎒 Inventory"
    populateInventoryPanel()
end)

-- ─── Placement System ─────────────────────────────────────────────────────────
local placementOrientation = 0  -- degrees, rotated with R key
local GRID_SIZE = 2

local camera = workspace.CurrentCamera

local function getPlacementPosition()
    local ray = camera:ScreenPointToRay(
        UserInputService:GetMouseLocation().X,
        UserInputService:GetMouseLocation().Y
    )
    local result = workspace:Raycast(
        ray.Origin,
        ray.Direction * 100,
        RaycastParams.new()
    )
    if result then
        local pos = result.Position
        -- Snap to grid
        pos = Vector3.new(
            math.round(pos.X / GRID_SIZE) * GRID_SIZE,
            pos.Y,
            math.round(pos.Z / GRID_SIZE) * GRID_SIZE
        )
        return pos
    end
    return nil
end

-- Create/update preview part
local function updatePreview(pos)
    if not placementPreview then
        placementPreview = Instance.new("Part")
        placementPreview.Name      = "PlacementPreview"
        placementPreview.Anchored  = true
        placementPreview.CanCollide= false
        placementPreview.Size      = Vector3.new(4, 4, 4)
        placementPreview.BrickColor= BrickColor.new("Bright yellow")
        placementPreview.Material  = Enum.Material.Neon
        placementPreview.Transparency = 0.5
        placementPreview.Parent    = workspace
        local selBox = Instance.new("SelectionBox")
        selBox.Adornee = placementPreview
        selBox.Color3  = Color3.new(1, 1, 0)
        selBox.Parent  = placementPreview
    end
    if pos then
        placementPreview.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
            * CFrame.Angles(0, math.rad(placementOrientation), 0)
    end
end

RunService.RenderStepped:Connect(function()
    if placementEnabled and selectedItem then
        local pos = getPlacementPosition()
        updatePreview(pos)
    elseif placementPreview then
        placementPreview:Destroy()
        placementPreview = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.R and placementEnabled then
        placementOrientation = (placementOrientation + 45) % 360
    end

    if input.KeyCode == Enum.KeyCode.X then
        placementEnabled = false
        selectedItem = nil
        if placementPreview then placementPreview:Destroy(); placementPreview = nil end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not placementEnabled or not selectedItem then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if gameProcessed then return end

    local pos = getPlacementPosition()
    if not pos then return end

    local ok, result = PlaceObject:InvokeServer(selectedItem, pos, placementOrientation)
    if ok then
        -- Decrement in local inventory display
        for _, slot in ipairs(playerInventory) do
            if slot.id == selectedItem then
                slot.qty = slot.qty - 1
                if slot.qty <= 0 then
                    placementEnabled = false
                    selectedItem = nil
                    if placementPreview then placementPreview:Destroy(); placementPreview = nil end
                end
                break
            end
        end
    end
end)

-- ─── Show/Hide ────────────────────────────────────────────────────────────────
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if screenGui.Enabled then
        local mode = screenGui:GetAttribute("Mode") or "Build"
        if mode == "Inventory" then
            invTabBtn:Activate()
        else
            buildTabBtn:Activate()
        end
    end
end)

UpdateInventory.OnClientEvent:Connect(function(inv)
    playerInventory = inv
    if screenGui.Enabled then
        if currentMode == "Build" then
            populateBuildPanel()
        else
            populateInventoryPanel()
        end
    end
end)

print("[BuildingGui] Ready")
