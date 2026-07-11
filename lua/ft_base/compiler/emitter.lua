FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Emitter = {}

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

    local isArray = FTBase.Util.Table.IsArray(value)
    local childIndent = indent .. "    "
    local parts = {"{"}

    for key, item in pairs(value) do
        local prefix = ""

        if not isArray then
            if type(key) == "string" and string.match(key, "^[A-Za-z_][A-Za-z0-9_]*$") then
                prefix = key .. " = "
            else
                prefix = "[" .. luaValue(key) .. "] = "
            end
        end

        parts[#parts + 1] = childIndent .. prefix .. luaValue(item, childIndent) .. ","
    end

    parts[#parts + 1] = indent .. "}"
    return table.concat(parts, "\n")
end

function Emitter.EmitAssignments(assignments)
    local lines = {}

    for _, assignment in ipairs(assignments or {}) do
        lines[#lines + 1] = assignment.path .. " = " .. luaValue(assignment.value)
    end

    return table.concat(lines, "\n")
end

function Emitter.Value(value)
    return luaValue(value)
end

FTBase.Compiler.Emitter = Emitter
