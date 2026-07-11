FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Animation = FTBase.Module.Define("Animation", {})

local function resolveSequence(swep, sequence)
    if type(sequence) == "number" then
        return sequence
    end

    if type(sequence) == "table" and sequence.__type == "Symbol" then
        local value = _G and _G[sequence.name]

        if type(value) == "number" then
            return value
        end
    end

    if type(sequence) == "string" and swep and swep.LookupSequence then
        local index = swep:LookupSequence(sequence)

        if type(index) == "number" and index >= 0 then
            return index
        end
    end

    return nil
end

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
    sequence = resolveSequence(swep, sequence)

    if sequence and swep and swep.SendWeaponAnim then
        swep:SendWeaponAnim(sequence)
    end

    return sequence
end

function Animation.GetReloadDuration(swep, runtime)
    local configured = runtime.ir.animations and runtime.ir.animations.reloadDuration

    if type(configured) == "number" and configured > 0 then
        return configured
    end

    if swep and swep.SequenceDuration then
        local duration = swep:SequenceDuration()

        if type(duration) == "number" and duration > 0 then
            return duration
        end
    end

    return 1.8
end

function Animation.Event(runtime, name, payload)
    local events = runtime.ir.animations.events or {}
    local handler = events[name]

    if type(handler) == "function" then
        handler(runtime, payload)
    end
end

FTBase.Runtime.Animation = Animation
