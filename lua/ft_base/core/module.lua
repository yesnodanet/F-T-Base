FTBase = FTBase or {}
FTBase.Modules = FTBase.Modules or {}

local Module = {}

function Module.Define(name, interface)
    interface = interface or {}
    interface.Name = name
    FTBase.Modules[name] = interface
    return interface
end

function Module.Get(name)
    return FTBase.Modules[name]
end

function Module.GetAll()
    return FTBase.Modules
end

FTBase.Module = Module
