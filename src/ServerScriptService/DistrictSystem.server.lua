--[[
	DistrictSystem.server.lua
	Tracks ownership and energy contributions for each city district.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DistrictData = require(ReplicatedStorage:WaitForChild("DistrictData"))

--------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------
local DistrictUpdateEvent = ReplicatedStorage:WaitForChild("DistrictUpdate")
local BankEnergyEvent     = ReplicatedStorage:WaitForChild("BankEnergy")
local NotificationEvent   = ReplicatedStorage:WaitForChild("Notification")

--------------------------------------------------------------------
-- District state
--------------------------------------------------------------------
local districtState = {} -- [districtName] = { Owner = "guild/none", Energy = {[guildId] = amount} }

for name, data in pairs(DistrictData.Districts) do
	districtState[name] = {
		Owner = "Unclaimed",
		Energy = {},
		Threshold = data.CaptureThreshold,
	}
end

--------------------------------------------------------------------
-- Energy contribution (called when a run ends)
--------------------------------------------------------------------
local function contributeEnergy(player, districtName, amount)
	local state = districtState[districtName]
	if not state then return end

	-- Use player name as a simple guild stand-in
	local guildId = player.Name

	state.Energy[guildId] = (state.Energy[guildId] or 0) + amount

	-- Check for capture
	if state.Energy[guildId] >= state.Threshold and state.Owner ~= guildId then
		state.Owner = guildId
		-- Broadcast capture
		for _, p in ipairs(Players:GetPlayers()) do
			DistrictUpdateEvent:FireClient(p, {
				District = districtName,
				NewOwner = guildId,
				Type = "Captured",
			})
		end
		NotificationEvent:FireClient(player, "You captured " .. districtName .. "!")
	end
end

--------------------------------------------------------------------
-- Listen for run completions to bank energy (via BindableEvent from GameManager)
--------------------------------------------------------------------
BankEnergyEvent.Event:Connect(function(player, districtName, energy)
	if player and districtName and energy then
		contributeEnergy(player, districtName, energy)
	end
end)

--------------------------------------------------------------------
-- Broadcast district state periodically
--------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(30) -- every 30 seconds
		local summary = {}
		for name, state in pairs(districtState) do
			summary[name] = {
				Owner = state.Owner,
				TopContributor = "",
				TopEnergy = 0,
			}
			for guild, energy in pairs(state.Energy) do
				if energy > summary[name].TopEnergy then
					summary[name].TopContributor = guild
					summary[name].TopEnergy = energy
				end
			end
		end

		for _, player in ipairs(Players:GetPlayers()) do
			DistrictUpdateEvent:FireClient(player, {
				Type = "FullUpdate",
				Districts = summary,
			})
		end
	end
end)

print("[NEON SLICE] DistrictSystem loaded ✓")
