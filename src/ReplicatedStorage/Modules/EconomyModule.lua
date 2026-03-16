-- Modules/EconomyModule.lua
-- Shared economy helpers: price calculation, formatting, validation

local EconomyModule = {}

-- Format a number as a currency string: 1234 -> "$1,234"
function EconomyModule.FormatMoney(amount)
    amount = math.floor(amount)
    local str = tostring(math.abs(amount))
    local result = ""
    local len = #str
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then
            result = result .. ","
        end
        result = result .. str:sub(i, i)
    end
    if amount < 0 then result = "-" .. result end
    return "$" .. result
end

-- Calculate the dynamic market price for an item based on supply
-- supplyCount: how many units are currently listed across all players
-- basePrice: government store base price
function EconomyModule.DynamicPrice(basePrice, supplyCount, supplyThreshold)
    supplyThreshold = supplyThreshold or 50
    if supplyCount == 0 then
        return math.floor(basePrice * 1.5)     -- scarce
    elseif supplyCount >= supplyThreshold then
        return math.floor(basePrice * 0.7)     -- oversupplied
    else
        -- Linear interpolation between scarce and oversupplied
        local t = supplyCount / supplyThreshold
        local mult = 1.5 - t * 0.8
        return math.floor(basePrice * mult)
    end
end

-- Returns true when a transaction can proceed (buyer has enough money)
function EconomyModule.CanAfford(playerMoney, cost)
    return playerMoney >= cost
end

-- Apply reputation-based discount
-- reputation: -100 to +100
-- basePrice: original price
function EconomyModule.ApplyReputationDiscount(basePrice, reputation)
    if reputation >= 50 then
        local discount = math.min(0.2, (reputation - 50) / 250)  -- up to 20% off
        return math.floor(basePrice * (1 - discount))
    end
    return basePrice
end

return EconomyModule
