FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Emitter = {}

local function sortedKeys(value)
    return FTBase.Util.Table.Keys(value)
end

local function luaValue(value, indent)
    indent = indent or ""

    if type(value) == "string" then
        return string.format("%q", value)
    end

    if type(value) == "number" or type(value) == "boolean" or value == nil then
        return tostring(value)
    end

    if type(value) ~= "table" then
        return "nil"
    end

    if value.__type == "Nil" then
        return "nil"
    end

    if value.__type == "Symbol" then
        return tostring(value.name)
    end

    if value.__type == "Vector" then
        return "Vector(" .. luaValue(value.x) .. ", " .. luaValue(value.y) .. ", " .. luaValue(value.z) .. ")"
    end

    if value.__type == "Angle" then
        return "Angle(" .. luaValue(value.p) .. ", " .. luaValue(value.y) .. ", " .. luaValue(value.r) .. ")"
    end

    if value.__type == "Call" then
        local args = {}

        for _, item in ipairs(value.args or {}) do
            args[#args + 1] = luaValue(item)
        end

        return tostring(value.name) .. "(" .. table.concat(args, ", ") .. ")"
    end

    local isArray = FTBase.Util.Table.IsArray(value)
    local childIndent = indent .. "    "
    local parts = {"{"}

    local keys = isArray and nil or sortedKeys(value)

    if isArray then
        for index, item in ipairs(value) do
            parts[#parts + 1] = childIndent .. luaValue(item, childIndent) .. ","
        end
    else
        for _, key in ipairs(keys) do
            local item = value[key]
            local prefix = ""

            if type(key) == "string" and string.match(key, "^[A-Za-z_][A-Za-z0-9_]*$") then
                prefix = key .. " = "
            else
                prefix = "[" .. luaValue(key) .. "] = "
            end

            parts[#parts + 1] = childIndent .. prefix .. luaValue(item, childIndent) .. ","
        end
    end

    parts[#parts + 1] = indent .. "}"
    return table.concat(parts, "\n")
end

function Emitter.EmitAssignments(assignments)
    local lines = {}

    for _, assignment in ipairs(assignments or {}) do
        lines[#lines + 1] = (type(assignment.path) == "table" and FTBase.Util.Path.Join(assignment.path) or assignment.path)
            .. " = " .. luaValue(assignment.value)
    end

    return table.concat(lines, "\n")
end

function Emitter.Value(value)
    return luaValue(value)
end

FTBase.Compiler.Emitter = Emitter
