FTBase = FTBase or {}
FTBase.Adapters = FTBase.Adapters or {}

local function fireLayer(value)
    return {
        { sound = value, role = "body" }
    }
end

local rules = {
    ["PrintName"] = { ir = "meta.printName" },
    ["Category"] = { ir = "meta.category" },
    ["Spawnable"] = { ir = "meta.spawnable" },
    ["ViewModel"] = { ir = "rendering.viewModel" },
    ["WorldModel"] = { ir = "rendering.worldModel" },

    ["Damage_Max"] = { ir = "damage.base" },
    ["Damage_Min"] = { ir = "damage.minimum" },
    ["BodyDamageMultipliers"] = { ir = "damage.hitgroups" },
    ["Range_Max"] = { ir = "ballistics.damageCurve.maxRange" },
    ["Range_Min"] = { ir = "ballistics.damageCurve.minRange" },
    ["Penetration"] = { ir = "ballistics.penetration.power" },
    ["ArmorPenetration"] = { ir = "ballistics.armor.scale" },
    ["Num"] = { ir = "ballistics.pellets" },

    ["RPM"] = { ir = "fire.rpm" },
    ["FireDelay"] = { ir = "fire.delay" },
    ["Automatic"] = { ir = "fire.automatic" },
    ["ClipSize"] = { ir = "ammo.clipSize" },
    ["Ammo"] = { ir = "ammo.type" },

    ["Spread"] = { ir = "spread.hip" },
    ["Spread_Sights"] = { ir = "spread.ads" },
    ["Spread_Move"] = { ir = "spread.movement" },

    ["RecoilKick"] = { ir = "recoil.procedural.vertical" },
    ["RecoilSpreadPenalty"] = { ir = "spread.perShot" },
    ["RecoilStability"] = { ir = "recoil.procedural.recovery" },

    ["FreeAimAngle"] = { ir = "camera.freeAim.radius" },
    ["BlindFire"] = { ir = "movement.blindFire" },
    ["Sway"] = { ir = "camera.sway" },

    ["Sound_Shoot"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["Sound_Shoot_Silenced"] = { ir = "sounds.fire.suppressed" },
    ["Sound_Shoot_Distant"] = { ir = "sounds.fire.distant" },
    ["MuzzleEffect"] = { ir = "effects.muzzle" },
    ["Tracer"] = { ir = "effects.tracer" },

    ["ReloadTimeMult"] = { ir = "movement.reloadSpeed" },
    ["Animations"] = { ir = "animations.base" },
    ["Attachments"] = { ir = "attachments.slots" }
}

FTBase.Adapters.TacRP = FTBase.Adapters.Make({
    Name = "TacRP",
    Aliases = {"TACRP", "tacrp"},
    Rules = rules
})
