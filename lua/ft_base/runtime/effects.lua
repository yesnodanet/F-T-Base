FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Effects = FTBase.Module.Define("Effects", {})

function Effects.Muzzle(swep, ir)
    if not ir.effects.muzzle then
        return
    end

    if swep and swep.GetOwner and IsValid and IsValid(swep:GetOwner()) and swep:GetOwner().MuzzleFlash then
        swep:GetOwner():MuzzleFlash()
    end
end

function Effects.Impact(ir, trace)
    if not util or not ir.effects.impact then
        return
    end

    local effectName = ir.effects.impact.default

    if effectName and EffectData then
        local data = EffectData()
        data:SetOrigin(trace.HitPos)
        util.Effect(effectName, data)
    end
end

FTBase.Runtime.Effects = Effects
