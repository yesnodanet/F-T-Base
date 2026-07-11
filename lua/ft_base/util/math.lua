FTBase = FTBase or {}
FTBase.Util = FTBase.Util or {}

local Math = {}

function Math.Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

function Math.Lerp(fraction, fromValue, toValue)
    return fromValue + (toValue - fromValue) * fraction
end

function Math.Round(value, decimals)
    local scale = 10 ^ (decimals or 0)
    return math.floor(value * scale + 0.5) / scale
end

function Math.Number(value, fallback)
    local numeric = tonumber(value)

    if numeric == nil then
        return fallback or 0
    end

    return numeric
end

FTBase.Util.Math = Math
