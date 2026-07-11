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
    ["HoldType"] = { ir = "rendering.holdType" },

    ["Damage"] = { ir = "damage.base" },
    ["NumShots"] = { ir = "ballistics.pellets" },
    ["FireDelay"] = { ir = "fire.delay" },
    ["Automatic"] = { ir = "fire.automatic" },
    ["ClipSize"] = { ir = "ammo.clipSize" },
    ["Ammo"] = { ir = "ammo.type" },

    ["HipSpread"] = { ir = "spread.hip" },
    ["AimSpread"] = { ir = "spread.ads" },
    ["SpreadPerShot"] = { ir = "spread.perShot" },
    ["MaxSpreadInc"] = { ir = "spread.movement" },

    ["Recoil"] = { ir = "recoil.scalar" },
    ["RecoilPattern"] = { ir = "recoil.pattern" },
    ["KickUp"] = { ir = "recoil.procedural.vertical" },
    ["KickSide"] = { ir = "recoil.procedural.horizontal" },

    ["FireSound"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["DistantSound"] = { ir = "sounds.fire.distant" },
    ["SuppressorSound"] = { ir = "sounds.fire.suppressed" },
    ["MuzzleEffect"] = { ir = "effects.muzzle" },
    ["Tracer"] = { ir = "effects.tracer" },

    ["AimPos"] = { ir = "ads.pos" },
    ["AimAng"] = { ir = "ads.ang" },
    ["AimFOV"] = { ir = "ads.fov" },
    ["SpeedDec"] = { ir = "movement.sightedSpeed" },

    ["Animations"] = { ir = "animations.base" },
    ["Attachments"] = { ir = "attachments.slots" }
}

FTBase.Adapters.SWB = FTBase.Adapters.Make({
    Name = "SWB",
    Aliases = {"swb"},
    Rules = rules
})
