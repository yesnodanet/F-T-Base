FTBase = FTBase or {}
FTBase.Adapters = FTBase.Adapters or {}

local function fireLayer(value)
    if type(value) == "table" then
        if value[1] and type(value[1]) == "table" then
            return value
        end

        if value[1] then
            local layers = {}

            for _, sound in ipairs(value) do
                layers[#layers + 1] = { sound = sound, role = "body" }
            end

            return layers
        end
    end

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
    ["DefaultClip"] = { ir = "ammo.defaultClip" },
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
    ["ReloadSound"] = { ir = "sounds.reload.reload" },
    ["ReloadDuration"] = { ir = "animations.reloadDuration" },
    ["DistantSound"] = { ir = "sounds.fire.distant" },
    ["SuppressorSound"] = { ir = "sounds.fire.suppressed" },
    ["MuzzleEffect"] = { ir = "effects.muzzle" },
    ["Tracer"] = { ir = "effects.tracer" },

    ["AimPos"] = { ir = "ads.pos" },
    ["AimAng"] = { ir = "ads.ang" },
    ["AimFOV"] = { ir = "ads.fov" },
    ["SpeedDec"] = { ir = "movement.sightedSpeed" },

    ["Animations"] = { ir = "animations.base" },
    ["Attachments"] = { ir = "attachments.slots" },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions" }
}

FTBase.Adapters.SWB = FTBase.Adapters.Make({
    Name = "SWB",
    Aliases = {"swb"},
    Rules = rules
})
