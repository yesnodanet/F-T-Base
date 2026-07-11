FTBase = FTBase or {}
FTBase.Util = FTBase.Util or {}

local Path = {}

function Path.Split(path)
    if type(path) == "table" then
        return FTBase.Util.Table.DeepCopy(path)
    end

    local parts = {}

    for part in string.gmatch(tostring(path or ""), "[^%.]+") do
        local numeric = tonumber(part)
        parts[#parts + 1] = numeric or part
    end

    return parts
end

function Path.Join(path)
    local parts = Path.Split(path)
    local text = {}

    for index = 1, #parts do
        text[#text + 1] = tostring(parts[index])
    end

    return table.concat(text, ".")
end

function Path.LowerJoin(path)
    return string.lower(Path.Join(path))
end

function Path.Append(basePath, suffixPath)
    local result = Path.Split(basePath)
    local suffix = Path.Split(suffixPath)

    for index = 1, #suffix do
        result[#result + 1] = suffix[index]
    end

    return result
end

function Path.Get(root, path)
    local current = root
    local parts = Path.Split(path)

    for index = 1, #parts do
        if type(current) ~= "table" then
            return nil
        end

        current = current[parts[index]]
    end

    return current
end

function Path.Set(root, path, value)
    local current = root
    local parts = Path.Split(path)

    for index = 1, #parts - 1 do
        local key = parts[index]

        if type(current[key]) ~= "table" then
            current[key] = {}
        end

        current = current[key]
    end

    current[parts[#parts]] = value
    return root
end

function Path.Has(root, path)
    return Path.Get(root, path) ~= nil
end

function Path.StartsWith(path, prefix)
    local pathParts = Path.Split(path)
    local prefixParts = Path.Split(prefix)

    if #prefixParts > #pathParts then
        return false
    end

    for index = 1, #prefixParts do
        if string.lower(tostring(pathParts[index])) ~= string.lower(tostring(prefixParts[index])) then
            return false
        end
    end

    return true
end

FTBase.Util.Path = Path
