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
    ["ViewModel"] = { ir = "rendering.viewModel" },
    ["WorldModel"] = { ir = "rendering.worldModel" },

    ["Damage"] = { ir = "damage.base" },
    ["DamageMin"] = { ir = "damage.minimum" },
    ["Range"] = { ir = "ballistics.damageCurve.maxRange" },
    ["Penetration"] = { ir = "ballistics.penetration.power" },
    ["Projectile"] = { ir = "ballistics.mode", transform = function(value) return value and "projectile" or "hitscan" end },
    ["ProjectileVelocity"] = { ir = "ballistics.muzzleVelocity" },
    ["ProjectileDrag"] = { ir = "ballistics.drag" },
    ["ProjectileGravity"] = { ir = "ballistics.gravity" },

    ["RPM"] = { ir = "fire.rpm" },
    ["FireDelay"] = { ir = "fire.delay" },
    ["Automatic"] = { ir = "fire.automatic" },
    ["ClipSize"] = { ir = "ammo.clipSize" },
    ["Ammo"] = { ir = "ammo.type" },

    ["Spread"] = { ir = "spread.hip" },
    ["ADSSpread"] = { ir = "spread.ads" },
    ["MoveSpread"] = { ir = "spread.movement" },

    ["Recoil.Vertical"] = { ir = "recoil.procedural.vertical" },
    ["Recoil.Horizontal"] = { ir = "recoil.procedural.horizontal" },
    ["Recoil.Roll"] = { ir = "recoil.procedural.roll" },
    ["Recoil.Randomness"] = { ir = "recoil.procedural.randomness" },
    ["Recoil.Pattern"] = { ir = "recoil.pattern" },

    ["Camera.Shake"] = { ir = "camera.shake" },
    ["Camera.Sway"] = { ir = "camera.sway" },
    ["Camera.Breathing"] = { ir = "camera.breathing" },
    ["Camera.Landing"] = { ir = "camera.landing" },
    ["Camera.Sprint"] = { ir = "camera.sprint" },

    ["Aim.FOV"] = { ir = "ads.fov" },
    ["Aim.Speed"] = { ir = "ads.speed" },

    ["Sound.Fire"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["Sound.FireDistant"] = { ir = "sounds.fire.distant" },
    ["Sound.FireSuppressed"] = { ir = "sounds.fire.suppressed" },
    ["Sound.IndoorTail"] = { ir = "sounds.fire.indoorTail" },
    ["Sound.OutdoorTail"] = { ir = "sounds.fire.outdoorTail" },
    ["Sound.Mechanical"] = { ir = "sounds.mechanical" },

    ["Effects.Muzzle"] = { ir = "effects.muzzle" },
    ["Effects.Tracer"] = { ir = "effects.tracer" },
    ["Animations"] = { ir = "animations.base" },
    ["Attachments"] = { ir = "attachments.slots" }
}

FTBase.Adapters.MW = FTBase.Adapters.Make({
    Name = "MW",
    Aliases = {"MWBase", "MW Base", "ModernWarfare"},
    Rules = rules
})
