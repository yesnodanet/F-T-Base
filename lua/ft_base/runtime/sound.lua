FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Sound = FTBase.Module.Define("Sound", {})

function Sound.EmitLayered(swep, layers)
    if not swep or not swep.EmitSound then
        return
    end

    for _, layer in ipairs(layers or {}) do
        local soundName = type(layer) == "table" and layer.sound or layer

        if soundName then
            swep:EmitSound(soundName)
        end
    end
end

function Sound.Fire(swep, ir)
    Sound.EmitLayered(swep, ir.sounds.fire.layers)
end

function Sound.Reload(swep, ir, stage)
    local soundName = ir.sounds.reload and ir.sounds.reload[stage or "reload"]

    if soundName and swep and swep.EmitSound then
        swep:EmitSound(soundName)
    end
end

FTBase.Runtime.Sound = Sound
