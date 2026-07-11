FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Profiler = FTBase.Module.Define("Profiler", {})

function Profiler.New()
    return {
        stack = {},
        records = {}
    }
end

function Profiler.Begin(profiler, name)
    if not profiler then
        return
    end

    profiler.stack[#profiler.stack + 1] = {
        name = name,
        started = SysTime and SysTime() or os.clock()
    }
end

function Profiler.End(profiler)
    if not profiler or #profiler.stack == 0 then
        return
    end

    local scope = table.remove(profiler.stack)
    local now = SysTime and SysTime() or os.clock()

    profiler.records[#profiler.records + 1] = {
        name = scope.name,
        duration = now - scope.started
    }
end

function Profiler.Summary(profiler)
    local summary = {}

    for _, record in ipairs(profiler and profiler.records or {}) do
        summary[record.name] = (summary[record.name] or 0) + record.duration
    end

    return summary
end

FTBase.Runtime.Profiler = Profiler
