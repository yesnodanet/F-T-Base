FTBase = FTBase or {}

local Optimizer = {}

local function resolveLiteral(value)
    if type(value) ~= "table" then
        return value
    end

    if value.__type == "Symbol" then
        if _G and _G[value.name] ~= nil then
            return _G[value.name]
        end

        return value.name
    end

    if value.__type == "Vector" or value.__type == "Angle" then
        return value
    end

    local resolved = {}

    for key, item in pairs(value) do
        resolved[key] = resolveLiteral(item)
    end

    return resolved
end

local function normalizePatternEntry(entry)
    entry = resolveLiteral(entry)

    if type(entry) ~= "table" then
        return {
            horizontal = 0,
            vertical = 0,
            roll = 0,
            camera = 1,
            weapon = 1,
            recovery = 1,
            randomness = 0
        }
    end

    if entry.horizontal or entry.vertical or entry.roll then
        return {
            horizontal = tonumber(entry.horizontal) or tonumber(entry.x) or 0,
            vertical = tonumber(entry.vertical) or tonumber(entry.y) or 0,
            roll = tonumber(entry.roll) or tonumber(entry.z) or 0,
            camera = tonumber(entry.camera) or 1,
            weapon = tonumber(entry.weapon) or 1,
            recovery = tonumber(entry.recovery) or 1,
            randomness = tonumber(entry.randomness) or 0,
            animation = entry.animation
        }
    end

    return {
        horizontal = tonumber(entry[1]) or 0,
        vertical = tonumber(entry[2]) or 0,
        roll = tonumber(entry[3]) or 0,
        camera = tonumber(entry[4]) or 1,
        weapon = tonumber(entry[5]) or 1,
        recovery = tonumber(entry[6]) or 1,
        randomness = tonumber(entry[7]) or 0
    }
end

function Optimizer.Optimize(ir, report)
    report = report or FTBase.Report.New("optimization")

    for key, value in pairs(ir) do
        ir[key] = resolveLiteral(value)
    end

    local normalized = {}

    for index, entry in ipairs(ir.recoil.pattern or {}) do
        normalized[index] = normalizePatternEntry(entry)
    end

    ir.recoil.pattern = normalized

    if ir.fire.delay == nil and type(ir.fire.rpm) == "number" and ir.fire.rpm > 0 then
        ir.fire.delay = 60 / ir.fire.rpm
        report:AddOptimization("Computed fire.delay from fire.rpm")
    end

    if #ir.recoil.pattern > 80 then
        report:AddPerformanceSuggestion("Large recoil patterns should use interpolation or procedural segments")
    end

    ir.runtime.compiledAt = os.time()
    ir.runtime.optimized = true

    for _, plugin in ipairs(FTBase.Plugin and FTBase.Plugin.GetAll() or {}) do
        if plugin.Optimize then
            plugin.Optimize(ir, report)
        end
    end

    return ir, report
end

FTBase.Optimizer = Optimizer
