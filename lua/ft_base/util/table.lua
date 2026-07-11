FTBase = FTBase or {}
FTBase.Util = FTBase.Util or {}

local Table = {}

local function isArrayKey(key)
    return type(key) == "number" and key > 0 and math.floor(key) == key
end

function Table.IsArray(value)
    if type(value) ~= "table" then
        return false
    end

    local max = 0
    local count = 0

    for key in pairs(value) do
        if not isArrayKey(key) then
            return false
        end

        if key > max then
            max = key
        end

        count = count + 1
    end

    return max == count
end

function Table.DeepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[Table.DeepCopy(key, seen)] = Table.DeepCopy(item, seen)
    end

    return copy
end

function Table.DeepEqual(left, right, seen)
    if left == right then
        return true
    end

    if type(left) ~= type(right) then
        return false
    end

    if type(left) ~= "table" then
        return false
    end

    seen = seen or {}
    seen[left] = seen[left] or {}

    if seen[left][right] then
        return true
    end

    seen[left][right] = true

    for key, value in pairs(left) do
        if not Table.DeepEqual(value, right[key], seen) then
            return false
        end
    end

    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end

    return true
end

function Table.MergeInto(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == "table" and type(target[key]) == "table" then
            Table.MergeInto(target[key], value)
        else
            target[key] = Table.DeepCopy(value)
        end
    end

    return target
end

function Table.Keys(value)
    local keys = {}

    for key in pairs(value or {}) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)

    return keys
end

function Table.ValueToString(value)
    local valueType = type(value)

    if valueType == "string" then
        return string.format("%q", value)
    end

    if valueType == "number" or valueType == "boolean" or value == nil then
        return tostring(value)
    end

    if valueType ~= "table" then
        return "<" .. valueType .. ">"
    end

    local parts = {}
    local count = 0

    for key, item in pairs(value) do
        count = count + 1

        if count > 6 then
            parts[#parts + 1] = "..."
            break
        end

        parts[#parts + 1] = tostring(key) .. "=" .. Table.ValueToString(item)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end

function Table.FlattenLeaves(value, prefix, output)
    output = output or {}
    prefix = prefix or {}

    if type(value) ~= "table" or Table.IsArray(value) then
        output[#output + 1] = {
            path = Table.DeepCopy(prefix),
            value = value
        }

        return output
    end

    for key, item in pairs(value) do
        local nextPrefix = Table.DeepCopy(prefix)
        nextPrefix[#nextPrefix + 1] = key
        Table.FlattenLeaves(item, nextPrefix, output)
    end

    return output
end

FTBase.Util.Table = Table
