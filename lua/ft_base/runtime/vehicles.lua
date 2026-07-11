FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Vehicles = FTBase.Module.Define("Vehicles", {})

function Vehicles.CanFire(runtime, owner)
    if not runtime.ir.vehicles.enabled then
        return false
    end

    if owner and owner.InVehicle and owner:InVehicle() then
        return runtime.ir.vehicles.allowFire ~= false
    end

    return true
end

FTBase.Runtime.Vehicles = Vehicles
