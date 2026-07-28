FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Emitter = {}

local function sortedKeys(value)
    return FTBase.Util.Table.Keys(value)
end

-- These are the only symbolic values that may cross the converter boundary.
-- They are data constants used by animation maps, not executable expressions.
local SAFE_SYMBOLS = {
    ACT_VM_PRIMARYATTACK = true,
    ACT_VM_SECONDARYATTACK = true,
    ACT_VM_RELOAD = true,
    ACT_VM_DRAW = true,
    ACT_VM_HOLSTER = true,
    ACT_VM_IDLE = true,
    ACT_VM_IDLE_LOWERED = true,
    ACT_VM_PULLBACK = true,
    ACT_VM_RELEASE = true,
    ACT_VM_THROW = true,
    ACT_VM_PICKUP = true,
    ACT_VM_FIZZLE = true,
    ACT_VM_DRYFIRE = true,
    ACT_VM_SPRINT = true,
    ACT_VM_SPRINT_IDLE = true,
    ACT_VM_SPRINT_IN = true,
    ACT_VM_SPRINT_OUT = true,
    ACT_VM_RECOIL1 = true,
    ACT_VM_RECOIL2 = true,
    ACT_VM_RECOIL3 = true,
    ACT_VM_RECOIL4 = true,
    ACT_VM_RECOIL5 = true,
    ACT_VM_RECOIL6 = true,
    ACT_VM_RECOIL7 = true,
    ACT_VM_RECOIL8 = true,
    ACT_VM_RECOIL9 = true,
    ACT_VM_RECOIL10 = true,
    ACT_VM_DEPLOY = true
}

Emitter.SafeSymbols = SAFE_SYMBOLS

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function nativeVector(value)
    if type(isvector) == "function" and isvector(value) then
        return {value.x, value.y, value.z}
    end

    return nil
end

local function nativeAngle(value)
    if type(isangle) == "function" and isangle(value) then
        return {value.p, value.y, value.r}
    end

    return nil
end

local function addError(errors, path, message)
    errors[#errors + 1] = {
        path = path,
        message = message
    }
end

local function valuePath(path, suffix)
    if not path or path == "" then
        return suffix
    end

    return path .. "." .. suffix
end

local function scalarValue(value, path, errors)
    local valueType = type(value)

    if valueType == "string" then
        return string.format("%q", value)
    end

    if valueType == "number" then
        if not isFiniteNumber(value) then
            addError(errors, path, "non-finite numbers are not supported")
            return nil
        end

        return tostring(value)
    end

    if valueType == "boolean" or value == nil then
        return tostring(value)
    end

    return nil
end

local function luaValue(value, indent, errors, path, seen)
    indent = indent or ""
    errors = errors or {}
    path = path or "value"
    seen = seen or {}

    -- Optimizer output can contain native GMod Vector/Angle userdata. Keep
    -- those values data-only when converting instead of treating them as
    -- executable Lua objects.
    local native = nativeVector(value)

    if native then
        for index, component in ipairs(native) do
            if not isFiniteNumber(component) then
                addError(errors, valuePath(path, tostring(index)), "Vector components must be finite numbers")
                return nil
            end
        end

        return "Vector(" .. tostring(native[1]) .. ", " .. tostring(native[2]) .. ", " .. tostring(native[3]) .. ")"
    end

    native = nativeAngle(value)

    if native then
        for index, component in ipairs(native) do
            if not isFiniteNumber(component) then
                addError(errors, valuePath(path, tostring(index)), "Angle components must be finite numbers")
                return nil
            end
        end

        return "Angle(" .. tostring(native[1]) .. ", " .. tostring(native[2]) .. ", " .. tostring(native[3]) .. ")"
    end

    local scalar = scalarValue(value, path, errors)

    if scalar ~= nil then
        return scalar
    end

    if type(value) ~= "table" then
        addError(errors, path, "unsupported value type '" .. type(value) .. "'")
        return nil
    end

    if seen[value] then
        addError(errors, path, "cyclic tables are not supported")
        return nil
    end

    seen[value] = true

    if value.__type == "Nil" then
        seen[value] = nil
        return "nil"
    end

    if value.__type == "Symbol" then
        local name = tostring(value.name or "")

        if not SAFE_SYMBOLS[name] then
            addError(errors, path, "symbol '" .. name .. "' is not in the emitter whitelist")
            seen[value] = nil
            return nil
        end

        seen[value] = nil
        return name
    end

    local function vectorCall(name, components)
        if type(components) ~= "table" then
            addError(errors, path, name .. " arguments must be a table")
            return nil
        end

        if #components ~= 3 then
            addError(errors, path, name .. " requires exactly three numeric arguments")
            return nil
        end

        local args = {}

        for index, component in ipairs(components) do
            if not isFiniteNumber(component) then
                addError(errors, valuePath(path, tostring(index)), name .. " arguments must be finite numbers")
                return nil
            end

            args[#args + 1] = tostring(component)
        end

        return name .. "(" .. table.concat(args, ", ") .. ")"
    end

    if value.__type == "Vector" then
        local output = vectorCall("Vector", {value.x, value.y, value.z})
        seen[value] = nil
        return output
    end

    if value.__type == "Angle" then
        local output = vectorCall("Angle", {value.p, value.y, value.r})
        seen[value] = nil
        return output
    end

    if value.__type == "Call" then
        local name = tostring(value.name or "")

        if name ~= "Vector" and name ~= "Angle" then
            addError(errors, path, "call '" .. name .. "' is not allowed")
            seen[value] = nil
            return nil
        end

        local args = value.args or {}
        local output = vectorCall(name, args)
        seen[value] = nil
        return output
    end

    if value.__type then
        addError(errors, path, "unsupported tagged value '" .. tostring(value.__type) .. "'")
        seen[value] = nil
        return nil
    end

    local isArray = FTBase.Util.Table.IsArray(value)
    local childIndent = indent .. "    "
    local parts = {"{"}

    if isArray then
        for index, item in ipairs(value) do
            local serialized = luaValue(item, childIndent, errors, valuePath(path, tostring(index)), seen)

            if serialized == nil then
                seen[value] = nil
                return nil
            end

            parts[#parts + 1] = childIndent .. serialized .. ","
        end
    else
        for _, key in ipairs(sortedKeys(value)) do
            local keyType = type(key)

            if keyType ~= "string" and keyType ~= "number" and keyType ~= "boolean" then
                addError(errors, valuePath(path, tostring(key)), "table keys must be strings, numbers, or booleans")
                seen[value] = nil
                return nil
            end

            local item = value[key]
            local serialized = luaValue(item, childIndent, errors, valuePath(path, tostring(key)), seen)

            if serialized == nil then
                seen[value] = nil
                return nil
            end

            local prefix

            if keyType == "string" and string.match(key, "^[A-Za-z_][A-Za-z0-9_]*$") then
                prefix = key .. " = "
            else
                local serializedKey = scalarValue(key, valuePath(path, tostring(key)), errors)

                if serializedKey == nil then
                    seen[value] = nil
                    return nil
                end

                prefix = "[" .. serializedKey .. "] = "
            end

            parts[#parts + 1] = childIndent .. prefix .. serialized .. ","
        end
    end

    parts[#parts + 1] = indent .. "}"
    seen[value] = nil
    return table.concat(parts, "\n")
end

local function assignmentPath(path)
    if type(path) == "table" then
        path = FTBase.Util.Path.Join(path)
    end

    if type(path) ~= "string" or path == "" or string.sub(path, 1, 1) == "."
        or string.sub(path, -1) == "." or string.find(path, "..", 1, true) then
        return nil
    end

    local segments = 0

    for segment in string.gmatch(path, "[^%.]+") do
        if not string.match(segment, "^[A-Za-z_][A-Za-z0-9_]*$") then
            return nil
        end

        segments = segments + 1
    end

    if segments == 0 then
        return nil
    end

    return path
end

function Emitter.EmitAssignments(assignments, report)
    local lines = {}
    local errors = {}

    for index, assignment in ipairs(assignments or {}) do
        local path = assignmentPath(assignment.path)

        if not path then
            addError(errors, "assignment[" .. tostring(index) .. "]", "invalid assignment path")
        else
            local value = luaValue(assignment.value, "", errors, path)

            if value ~= nil then
                lines[#lines + 1] = path .. " = " .. value
            end
        end
    end

    if report then
        for _, item in ipairs(errors) do
            report:AddError("Emitter rejected " .. item.path .. ": " .. item.message)
        end
    end

    return table.concat(lines, "\n"), errors
end

function Emitter.Value(value, report)
    local errors = {}
    local output = luaValue(value, "", errors, "value")

    if report then
        for _, item in ipairs(errors) do
            report:AddError("Emitter rejected " .. item.path .. ": " .. item.message)
        end
    end

    return output
end

FTBase.Compiler.Emitter = Emitter
