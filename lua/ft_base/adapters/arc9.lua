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

    ["DamageMax"] = { ir = "damage.base" },
    ["DamageMin"] = { ir = "damage.minimum" },
    ["RangeMax"] = { ir = "ballistics.damageCurve.maxRange" },
    ["RangeMin"] = { ir = "ballistics.damageCurve.minRange" },
    ["PhysBulletMuzzleVelocity"] = { ir = "ballistics.muzzleVelocity" },
    ["Penetration"] = { ir = "ballistics.penetration.power" },
    ["Num"] = { ir = "ballistics.pellets" },

    ["RPM"] = { ir = "fire.rpm" },
    ["Firemode"] = { ir = "fire.modes" },
    ["Firemodes"] = { ir = "fire.modes" },
    ["Automatic"] = { ir = "fire.automatic" },
    ["ClipSize"] = { ir = "ammo.clipSize" },
    ["Ammo"] = { ir = "ammo.type" },

    ["Spread"] = { ir = "spread.hip" },
    ["SpreadMultSights"] = { ir = "spread.ads", merge = "multiply" },
    ["SpreadAddMove"] = { ir = "spread.movement" },
    ["SpreadAddRecoil"] = { ir = "spread.perShot" },

    ["Recoil.Up"] = { ir = "recoil.procedural.vertical" },
    ["Recoil.Side"] = { ir = "recoil.procedural.horizontal" },
    ["Recoil.Roll"] = { ir = "recoil.procedural.roll" },
    ["Recoil.RandomUp"] = { ir = "recoil.procedural.randomness" },
    ["Recoil.RandomSide"] = { ir = "recoil.procedural.randomness", merge = "maximum" },
    ["Recoil.Pattern"] = { ir = "recoil.pattern" },
    ["RecoilUp"] = { ir = "recoil.procedural.vertical" },
    ["RecoilSide"] = { ir = "recoil.procedural.horizontal" },
    ["RecoilRandomUp"] = { ir = "recoil.procedural.randomness" },
    ["RecoilRandomSide"] = { ir = "recoil.procedural.randomness", merge = "maximum" },

    ["VisualRecoilUp"] = { ir = "camera.shake" },
    ["VisualRecoilSide"] = { ir = "camera.microJitter" },
    ["Sway"] = { ir = "camera.sway" },
    ["FreeAimRadius"] = { ir = "camera.freeAim.radius" },

    ["ShootSound"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["DistantShootSound"] = { ir = "sounds.fire.distant" },
    ["SilencerShootSound"] = { ir = "sounds.fire.suppressed" },
    ["MuzzleParticle"] = { ir = "effects.muzzle" },
    ["ShellModel"] = { ir = "effects.shell" },

    ["Attachments"] = { ir = "attachments.slots" },
    ["Animations"] = { ir = "animations.base" },
    ["Hook_TranslateAnimation"] = { ignore = "runtime hooks are not executed by adapters" }
}

FTBase.Adapters.ARC9 = FTBase.Adapters.Make({
    Name = "ARC9",
    Aliases = {"arc9"},
    Rules = rules
})
