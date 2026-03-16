-- ServerScriptService/BuildingManager.server.lua
-- Manages player plot ownership, building object placement/removal,
-- and co-op construction.

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local GameConfig   = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemData     = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemData"))

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlaceObject   = RemoteEvents:WaitForChild("PlaceObject")
local RemoveObject  = RemoteEvents:WaitForChild("RemoveObject")
local InviteCoop    = RemoteEvents:WaitForChild("InviteCoop")
local AcceptCoop    = RemoteEvents:WaitForChild("AcceptCoop")
local OpenShop      = RemoteEvents:WaitForChild("OpenShop")
local NotifyPlayer  = RemoteEvents:WaitForChild("NotifyPlayer")

-- Pending co-op invitations: { [targetUserId] = inviterPlayer }
local coopInvites = {}

-- ─── Helper: Find a plot by index ─────────────────────────────────────────────
local function findPlot(plotIndex)
    local suburbs = Workspace:FindFirstChild("Suburbs")
    if not suburbs then return nil end
    return suburbs:FindFirstChild("Plot_" .. plotIndex)
end

-- ─── Buy a Plot ───────────────────────────────────────────────────────────────
-- Exposed via proximity prompt on each plot (see init),
-- called from client via a RemoteEvent mapped to the plot sign.
-- We handle it here as a BindableFunction for simplicity.
local buyPlotBF = Instance.new("BindableFunction")
buyPlotBF.Name  = "BuyPlot"
buyPlotBF.OnInvoke = function(player, plotIndex)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end
    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    if data.PlotIndex > 0 then
        return false, "You already own a plot (Plot_" .. data.PlotIndex .. ")"
    end

    local plot = findPlot(plotIndex)
    if not plot then return false, "Plot not found" end
    if not plot:GetAttribute("ForSale") then return false, "Plot is not for sale" end

    local price = plot:GetAttribute("Price") or GameConfig.PlotPrices.Small
    if not PDM.SubtractMoney(player, price) then
        return false, "You need $" .. price .. " to buy this plot"
    end

    plot:SetAttribute("ForSale",   false)
    plot:SetAttribute("OwnerId",   player.UserId)
    plot.BrickColor = BrickColor.new("Bright green")

    -- Update plot sign
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local lbl = sign:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.Text = "🏡 Plot " .. plotIndex .. "\nOwned by:\n" .. player.Name end
    end

    data.PlotIndex = plotIndex

    -- Create a Buildings folder inside the plot
    local buildFolder = Instance.new("Folder")
    buildFolder.Name  = "Buildings"
    buildFolder.Parent= plot

    NotifyPlayer:FireClient(player, "🏡 You purchased Plot_" .. plotIndex .. " for $" .. price .. "!", "green")
    return true, plotIndex
end
buyPlotBF.Parent = game:GetService("ServerScriptService")
_G.BuyPlot = buyPlotBF

-- ─── Place Object ─────────────────────────────────────────────────────────────
PlaceObject.OnServerInvoke = function(player, itemId, position, orientation)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end
    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    -- Check plot ownership
    if data.PlotIndex <= 0 then
        return false, "You don't own a plot. Buy one first!"
    end

    local plot = findPlot(data.PlotIndex)
    if not plot then return false, "Plot not found" end

    -- Co-owner check
    local isCoOwner = plot:GetAttribute("CoOwnerId") == player.UserId
    local isOwner   = plot:GetAttribute("OwnerId")   == player.UserId
    -- Builder profession can build on any plot with permission
    local isBuilder = data.Profession == "Builder"
    if not isOwner and not isCoOwner and not isBuilder then
        return false, "You don't have permission to build here"
    end

    -- Validate item is a furniture/building item
    local item = ItemData.ById[itemId]
    if not item then return false, "Unknown item" end
    if item.category ~= ItemData.CATEGORY.FURNITURE then
        return false, "This item cannot be placed"
    end

    -- Check inventory
    if not PDM.RemoveFromInventory(player, itemId, 1) then
        return false, "You don't have " .. (item.name or itemId) .. " in your inventory"
    end

    -- Enforce object limit
    local buildFolder = plot:FindFirstChild("Buildings")
    if buildFolder and #buildFolder:GetChildren() >= GameConfig.MaxObjectsPerPlot then
        -- Refund item
        PDM.AddToInventory(player, itemId, 1)
        return false, "Plot is full (max " .. GameConfig.MaxObjectsPerPlot .. " objects)"
    end

    -- Validate position is within plot bounds
    local plotPos  = plot.Position
    local plotSize = plot.Size
    local halfX    = plotSize.X / 2
    local halfZ    = plotSize.Z / 2
    if math.abs(position.X - plotPos.X) > halfX or
       math.abs(position.Z - plotPos.Z) > halfZ then
        PDM.AddToInventory(player, itemId, 1)
        return false, "Position is outside your plot boundary"
    end

    -- Height limit
    if position.Y - plotPos.Y > GameConfig.MaxBuildHeight then
        PDM.AddToInventory(player, itemId, 1)
        return false, "Exceeds maximum build height"
    end

    -- Create the object part
    local obj = Instance.new("Part")
    obj.Name      = itemId .. "_" .. player.UserId .. "_" .. tostring(os.time())
    obj.Anchored  = true
    obj.Size      = Vector3.new(4, 4, 4)
    obj.CFrame    = CFrame.new(position) * CFrame.Angles(0, math.rad(orientation or 0), 0)
    obj.BrickColor= BrickColor.new("Medium stone grey")
    obj.Material  = Enum.Material.SmoothPlastic
    obj:SetAttribute("ItemId",    itemId)
    obj:SetAttribute("PlacedBy",  player.UserId)
    obj:SetAttribute("PlacedAt",  os.time())

    -- Warm items provide warmth attribute
    if item.warmth and item.warmth > 0 then
        obj:SetAttribute("Warmth", item.warmth)
    end

    -- Label
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 100, 0, 30)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = false
    local lbl = Instance.new("TextLabel")
    lbl.Size  = UDim2.new(1, 0, 1, 0)
    lbl.Text  = item.name or itemId
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font  = Enum.Font.Gotham
    lbl.TextScaled = true
    lbl.Parent = gui
    gui.Parent = obj

    if not buildFolder then
        buildFolder = Instance.new("Folder")
        buildFolder.Name   = "Buildings"
        buildFolder.Parent = plot
    end
    obj.Parent = buildFolder

    return true, obj.Name
end

-- ─── Remove Object ────────────────────────────────────────────────────────────
RemoveObject.OnServerInvoke = function(player, objectName)
    local PDM = _G.PDM
    if not PDM then return false, "Server not ready" end
    local data = PDM.GetData(player)
    if not data then return false, "Data not loaded" end

    if data.PlotIndex <= 0 then return false, "You don't own a plot" end

    local plot = findPlot(data.PlotIndex)
    if not plot then return false, "Plot not found" end

    local buildFolder = plot:FindFirstChild("Buildings")
    if not buildFolder then return false, "No buildings found" end

    local obj = buildFolder:FindFirstChild(objectName)
    if not obj then return false, "Object not found" end

    -- Only owner or co-owner can remove
    local isOwner   = plot:GetAttribute("OwnerId")   == player.UserId
    local isCoOwner = plot:GetAttribute("CoOwnerId") == player.UserId
    local placedBy  = obj:GetAttribute("PlacedBy")   == player.UserId
    if not isOwner and not isCoOwner and not placedBy then
        return false, "You cannot remove this object"
    end

    local itemId = obj:GetAttribute("ItemId")
    if itemId then
        PDM.AddToInventory(player, itemId, 1)  -- Refund item
    end
    obj:Destroy()
    return true, "Removed"
end

-- ─── Co-op Invite ─────────────────────────────────────────────────────────────
InviteCoop.OnServerEvent:Connect(function(player, targetName)
    local PDM = _G.PDM
    if not PDM then return end
    local data = PDM.GetData(player)
    if not data or data.PlotIndex <= 0 then
        NotifyPlayer:FireClient(player, "You need to own a plot to invite co-owners.", "red")
        return
    end

    local target = Players:FindFirstChild(targetName)
    if not target then
        NotifyPlayer:FireClient(player, "Player not found: " .. targetName, "red")
        return
    end

    coopInvites[target.UserId] = player
    NotifyPlayer:FireClient(target, "🤝 " .. player.Name .. " invites you to co-own their plot! Type /acceptcoop " .. player.Name, "blue")
    NotifyPlayer:FireClient(player,  "📨 Co-op invite sent to " .. targetName, "blue")
end)

AcceptCoop.OnServerInvoke = function(player, inviterName)
    local inviter = Players:FindFirstChild(inviterName)
    if not inviter then return false, "Inviter not found" end

    local pendingInviter = coopInvites[player.UserId]
    if not pendingInviter or pendingInviter ~= inviter then
        return false, "No pending invite from " .. inviterName
    end

    local PDM = _G.PDM
    if not PDM then return false end
    local inviterData = PDM.GetData(inviter)
    if not inviterData or inviterData.PlotIndex <= 0 then return false, "Inviter has no plot" end

    local plot = findPlot(inviterData.PlotIndex)
    if not plot then return false, "Plot not found" end

    plot:SetAttribute("CoOwnerId", player.UserId)
    coopInvites[player.UserId] = nil

    NotifyPlayer:FireClient(player,  "🏗️ You are now a co-owner of " .. inviterName .. "'s plot!", "green")
    NotifyPlayer:FireClient(inviter, "🏗️ " .. player.Name .. " accepted co-ownership!", "green")
    return true, "Co-op accepted"
end

-- ─── Plot Purchase Proximity Prompts ─────────────────────────────────────────
-- Add proximity prompts to each plot sign so players can buy plots easily
task.delay(5, function()
    local suburbs = Workspace:FindFirstChild("Suburbs")
    if not suburbs then return end
    for _, plot in ipairs(suburbs:GetChildren()) do
        if plot:IsA("BasePart") and plot:GetAttribute("ForSale") then
            local prompt = Instance.new("ProximityPrompt")
            prompt.ActionText   = "Buy Plot"
            prompt.ObjectText   = "Plot " .. (plot:GetAttribute("PlotIndex") or "?")
            prompt.HoldDuration = 1
            prompt.MaxActivationDistance = 10
            prompt.Parent = plot
            prompt.Triggered:Connect(function(player)
                local ok, msg = buyPlotBF:Invoke(player, plot:GetAttribute("PlotIndex"))
                if not ok then
                    local NotifyPlayerRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("NotifyPlayer")
                    NotifyPlayerRemote:FireClient(player, "❌ " .. (msg or "Cannot buy plot"), "red")
                end
            end)
        end
    end
    print("[BuildingManager] Plot proximity prompts added")
end)

print("[BuildingManager] Ready")
