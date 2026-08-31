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
    ir = ir or {}
    local animations = ir.animations or {}

    return {
        current = nil,
        layerWeights = {},
        reloadStage = 0,
        events = animations.events or {}
    }
end

function Animation.RefreshState(runtime, ir)
    if not runtime then
        return
    end

    ir = ir or runtime.ir or {}
    runtime.animation = runtime.animation or Animation.NewState(ir)
    runtime.animation.events = ir.animations and ir.animations.events or {}
end

function Animation.PlaySequence(swep, runtime, name, configuredSequence)
    if not runtime then
        return nil
    end

    runtime.animation.current = name
    local sequence = resolveSequence(swep, configuredSequence)

    if sequence and swep and swep.SendWeaponAnim then
        swep:SendWeaponAnim(sequence)
    end

    return sequence
end

function Animation.Play(swep, runtime, name)
    if not runtime then
        return nil
    end

    local ir = FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir or {}
    local animations = ir.animations or {}
    return Animation.PlaySequence(swep, runtime, name, animations.base and animations.base[name])
end

function Animation.GetReloadDuration(swep, runtime)
    local ir = runtime and (FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir) or {}
    local configured = ir.animations and ir.animations.reloadDuration

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
    local ir = runtime and (FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir) or {}
    local events = ir.animations and ir.animations.events or {}
    local handler = events[name]

    if type(handler) == "function" then
        handler(runtime, payload)
    end
end

FTBase.Runtime.Animation = Animation
