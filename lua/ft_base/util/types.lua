FTBase = FTBase or {}
FTBase.Util = FTBase.Util or {}

local Types = {}

local function numeric(value)
    return tonumber(value) or 0
end

function Types.Vector(value)
    if value == nil then
        return nil
    end

    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Vector" then
        if Vector then
            return Vector(numeric(value.x), numeric(value.y), numeric(value.z))
        end

        return value
    end

    if value.__type == "Call" and value.name == "Vector" then
        local args = value.args or {}

        if Vector then
            return Vector(numeric(args[1]), numeric(args[2]), numeric(args[3]))
        end

        return value
    end

    if type(value.x) == "number" and type(value.y) == "number" and type(value.z) == "number" then
        if Vector then
            return Vector(value.x, value.y, value.z)
        end
    end

    return value
end

function Types.Angle(value)
    if value == nil then
        return nil
    end

    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Angle" then
        if Angle then
            return Angle(numeric(value.p), numeric(value.y), numeric(value.r))
        end

        return value
    end

    if value.__type == "Call" and value.name == "Angle" then
        local args = value.args or {}

        if Angle then
            return Angle(numeric(args[1]), numeric(args[2]), numeric(args[3]))
        end

        return value
    end

    if type(value.p) == "number" and type(value.y) == "number" and type(value.r) == "number" then
        if Angle then
            return Angle(value.p, value.y, value.r)
        end
    end

    return value
end

function Types.ResolveLiteral(value)
    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Vector" or (value.__type == "Call" and value.name == "Vector") then
        return Types.Vector(value)
    end

    if value.__type == "Angle" or (value.__type == "Call" and value.name == "Angle") then
        return Types.Angle(value)
    end

    if value.__type == "Nil" then
        return nil
    end

    if value.__type == "Symbol" then
        return value
    end

    local resolved = {}

    for key, item in pairs(value) do
        resolved[key] = Types.ResolveLiteral(item)
    end

    return resolved
end

FTBase.Util.Types = Types
