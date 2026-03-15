--[[
	InputHandler.client.lua
	Centralised input handler for keyboard shortcuts and UI toggles.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

--------------------------------------------------------------------
-- Disable default Roblox UI elements for a cleaner look
--------------------------------------------------------------------
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

--------------------------------------------------------------------
-- Bindable events for UI toggles
--------------------------------------------------------------------
local toggleShop = Instance.new("BindableEvent")
toggleShop.Name = "ToggleShop"
toggleShop.Parent = ReplicatedStorage

local toggleDistrictMap = Instance.new("BindableEvent")
toggleDistrictMap.Name = "ToggleDistrictMap"
toggleDistrictMap.Parent = ReplicatedStorage

local toggleRaidUI = Instance.new("BindableEvent")
toggleRaidUI.Name = "ToggleRaidUI"
toggleRaidUI.Parent = ReplicatedStorage

--------------------------------------------------------------------
-- Keyboard shortcuts
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.B then
		toggleShop:Fire()
	elseif input.KeyCode == Enum.KeyCode.M then
		toggleDistrictMap:Fire()
	elseif input.KeyCode == Enum.KeyCode.R then
		toggleRaidUI:Fire()
	end
end)

print("[NEON SLICE] InputHandler loaded ✓")
