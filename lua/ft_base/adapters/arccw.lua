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

    ["Damage"] = { ir = "damage.base" },
    ["DamageMin"] = { ir = "damage.minimum" },
    ["Range"] = { ir = "ballistics.damageCurve.maxRange" },
    ["Penetration"] = { ir = "ballistics.penetration.power" },
    ["Num"] = { ir = "ballistics.pellets" },

    ["Delay"] = { ir = "fire.delay" },
    ["RPM"] = { ir = "fire.rpm" },
    ["Firemodes"] = { ir = "fire.modes" },
    ["ChamberSize"] = { ir = "ammo.chamberSize" },
    ["Primary.ClipSize"] = { ir = "ammo.clipSize" },
    ["Primary.Ammo"] = { ir = "ammo.type" },

    ["AccuracyMOA"] = { ir = "spread.hip" },
    ["Dispersion"] = { ir = "spread.hip" },
    ["HipDispersion"] = { ir = "spread.hip" },
    ["MoveDispersion"] = { ir = "spread.movement" },

    ["Recoil"] = { ir = "recoil.scalar" },
    ["RecoilSide"] = { ir = "recoil.procedural.horizontal" },
    ["VisualRecoilMult"] = { ir = "camera.shake" },
    ["SightedSpeedMult"] = { ir = "movement.sightedSpeed" },

    ["ShootSound"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["ShootSoundSilenced"] = { ir = "sounds.fire.suppressed" },
    ["DistantShootSound"] = { ir = "sounds.fire.distant" },
    ["MuzzleEffect"] = { ir = "effects.muzzle" },
    ["Tracer"] = { ir = "effects.tracer" },

    ["Attachments"] = { ir = "attachments.slots" },
    ["Animations"] = { ir = "animations.base" },
    ["Hook_ModifyBodygroups"] = { ignore = "runtime hooks are not executed by adapters" }
}

FTBase.Adapters.ArcCW = FTBase.Adapters.Make({
    Name = "ArcCW",
    Aliases = {"ARCW", "arccw"},
    Rules = rules
})
