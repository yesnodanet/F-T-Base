FTBase = FTBase or {}

local Merge = {}

local Path = FTBase.Util.Path
local Table = FTBase.Util.Table

local function mergeValue(existing, incoming, strategy)
    if strategy == "first" then
        return existing
    end

    if strategy == "average" and type(existing) == "number" and type(incoming) == "number" then
        return (existing + incoming) / 2
    end

    if strategy == "maximum" and type(existing) == "number" and type(incoming) == "number" then
        return math.max(existing, incoming)
    end

    if strategy == "minimum" and type(existing) == "number" and type(incoming) == "number" then
        return math.min(existing, incoming)
    end

    if strategy == "multiply" and type(existing) == "number" and type(incoming) == "number" then
        return existing * incoming
    end

    if type(strategy) == "function" then
        return strategy(existing, incoming)
    end

    return incoming
end

function Merge.Apply(ir, operation, report)
    local irPath = operation.irPath
    local existing = Path.Get(ir, irPath)
    local strategy = operation.strategy or "override"

    report._writtenPaths = report._writtenPaths or {}

    if report._writtenPaths[irPath] and existing ~= nil and not Table.DeepEqual(existing, operation.value) then
        report:AddConflict(irPath, existing, operation.value, strategy, operation.source)
    end

    if existing == nil then
        Path.Set(ir, irPath, Table.DeepCopy(operation.value))
    else
        Path.Set(ir, irPath, mergeValue(existing, operation.value, strategy))
    end

    report:AddApplied(operation.source, operation.externalPath, irPath, operation.value, strategy)
    report._writtenPaths[irPath] = true
end

FTBase.Merge = Merge
