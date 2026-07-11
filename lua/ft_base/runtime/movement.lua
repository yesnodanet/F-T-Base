FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Movement = FTBase.Module.Define("Movement", {})

function Movement.SpeedMultiplier(runtime)
    local ir = FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir
    local movement = ir.movement or {}
    local multiplier = movement.speed or 1

    if runtime.aiming then
        multiplier = multiplier * (movement.sightedSpeed or 1)
    end

    if runtime.reloading then
        multiplier = multiplier * (movement.reloadSpeed or 1)
    end

    return multiplier
end

function Movement.SetupMove(runtime, ply, moveData)
    if not moveData or not moveData.SetMaxClientSpeed then
        return
    end

    local speed = moveData:GetMaxClientSpeed() * Movement.SpeedMultiplier(runtime)
    moveData:SetMaxClientSpeed(speed)
end

FTBase.Runtime.Movement = Movement
