FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Debug = FTBase.Module.Define("Debug", {
    Enabled = false
})

function Debug.SetEnabled(enabled)
    Debug.Enabled = enabled and true or false
end

function Debug.Log(...)
    if not Debug.Enabled then
        return
    end

    local parts = {"[F&T]"}

    for index = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(index, ...))
    end

    print(table.concat(parts, " "))
end

function Debug.Report(report)
    if report then
        Debug.Log("\n" .. report:ToString())
    end
end

FTBase.Runtime.Debug = Debug
