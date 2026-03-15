--[[
	Utilities.lua
	Shared helper functions used across client and server.
]]

local Utilities = {}

--- Linearly interpolate between two numbers.
function Utilities.Lerp(a, b, t)
	return a + (b - a) * math.clamp(t, 0, 1)
end

--- Linearly interpolate between two Color3 values.
function Utilities.LerpColor(c1, c2, t)
	t = math.clamp(t, 0, 1)
	return Color3.new(
		Utilities.Lerp(c1.R, c2.R, t),
		Utilities.Lerp(c1.G, c2.G, t),
		Utilities.Lerp(c1.B, c2.B, t)
	)
end

--- Format a number with commas (e.g. 12345 -> "12,345").
function Utilities.FormatNumber(n)
	local formatted = tostring(math.floor(n))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

--- Format seconds into M:SS.
function Utilities.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

--- Shallow copy a table.
function Utilities.ShallowCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

--- Weighted random from a dictionary of {key = weight}.
function Utilities.WeightedRandom(weights)
	local total = 0
	for _, w in pairs(weights) do
		total = total + w
	end
	local roll = math.random() * total
	local cumulative = 0
	for key, w in pairs(weights) do
		cumulative = cumulative + w
		if roll <= cumulative then
			return key
		end
	end
end

--- Create a neon part helper.
function Utilities.CreateNeonPart(size, color, position)
	local part = Instance.new("Part")
	part.Size = size or Vector3.new(4, 4, 1)
	part.Color = color or Color3.fromRGB(155, 89, 182)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.Position = position or Vector3.new(0, 0, 0)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

return Utilities
