FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Animation = FTBase.Module.Define("Animation", {})

function Animation.NewState(ir)
    return {
        current = nil,
        layerWeights = {},
        reloadStage = 0,
        events = ir.animations.events or {}
    }
end

function Animation.Play(swep, runtime, name)
    runtime.animation.current = name

    local sequence = runtime.ir.animations.base and runtime.ir.animations.base[name]

    if sequence and swep and swep.SendWeaponAnim and type(sequence) == "number" then
        swep:SendWeaponAnim(sequence)
    end
end

function Animation.Event(runtime, name, payload)
    local events = runtime.ir.animations.events or {}
    local handler = events[name]

    if type(handler) == "function" then
        handler(runtime, payload)
    end
end

FTBase.Runtime.Animation = Animation
