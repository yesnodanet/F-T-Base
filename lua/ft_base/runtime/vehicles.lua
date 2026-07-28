FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Vehicles = FTBase.Module.Define("Vehicles", {})

function Vehicles.CanFire(runtime, owner)
    if not runtime then
        return false
    end

    local ir = FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir or {}
    local vehicles = ir.vehicles or {}

    if owner and owner.InVehicle and owner:InVehicle() then
        return vehicles.enabled ~= false and vehicles.allowFire ~= false
    end

    return true
end

FTBase.Runtime.Vehicles = Vehicles
