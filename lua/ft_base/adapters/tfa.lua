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
    ["UseHands"] = { ir = "rendering.useHands" },
    ["ViewModel"] = { ir = "rendering.viewModel" },
    ["WorldModel"] = { ir = "rendering.worldModel" },
    ["HoldType"] = { ir = "rendering.holdType" },
    ["DrawAmmo"] = { ir = "ui.drawAmmo" },

    ["Primary.Damage"] = { ir = "damage.base" },
    ["Primary.NumShots"] = { ir = "ballistics.pellets" },
    ["Primary.Cone"] = { ir = "spread.hip" },
    ["Primary.IronAccuracy"] = { ir = "spread.ads" },
    ["Primary.Delay"] = { ir = "fire.delay" },
    ["Primary.RPM"] = { ir = "fire.rpm" },
    ["Primary.Automatic"] = { ir = "fire.automatic" },
    ["Primary.ClipSize"] = { ir = "ammo.clipSize" },
    ["Primary.DefaultClip"] = { ir = "ammo.defaultClip" },
    ["Primary.Ammo"] = { ir = "ammo.type" },
    ["Primary.Sound"] = { ir = "sounds.fire.layers", transform = fireLayer },

    ["Secondary.IronFOV"] = { ir = "ads.fov" },
    ["IronSightsPos"] = { ir = "ads.pos" },
    ["IronSightsAng"] = { ir = "ads.ang" },
    ["RunSightsPos"] = { ir = "camera.sprint.pos" },
    ["RunSightsAng"] = { ir = "camera.sprint.ang" },

    ["MuzzleFlashEffect"] = { ir = "effects.muzzle" },
    ["ShellAttachment"] = { ir = "effects.shell" },
    ["TracerName"] = { ir = "effects.tracer" },

    ["Recoil"] = { ir = "recoil.scalar" },
    ["RecoilInstructions"] = { ir = "recoil.pattern" },
    ["KickUp"] = { ir = "recoil.procedural.vertical" },
    ["KickHorizontal"] = { ir = "recoil.procedural.horizontal" },

    ["MoveSpeed"] = { ir = "movement.speed" },
    ["IronSightsMoveSpeed"] = { ir = "movement.sightedSpeed" },

    ["SequenceLengthOverride"] = { ir = "animations.base", deprecated = "FT.Animations.Base" },
    ["EventTable"] = { ir = "animations.events" },
    ["Attachments"] = { ir = "attachments.slots" }
}

FTBase.Adapters.TFA = FTBase.Adapters.Make({
    Name = "TFA",
    Aliases = {"TFA_BASE"},
    Rules = rules
})
