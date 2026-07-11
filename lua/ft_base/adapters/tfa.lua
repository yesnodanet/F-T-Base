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
    ["ReloadSound"] = { ir = "sounds.reload.reload" },
    ["ReloadDuration"] = { ir = "animations.reloadDuration" },

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
    ["Animations"] = { ir = "animations.base" },
    ["EventTable"] = { ir = "animations.events" },
    ["Attachments"] = { ir = "attachments.slots" },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions" }
}

FTBase.Adapters.TFA = FTBase.Adapters.Make({
    Name = "TFA",
    Aliases = {"TFA_BASE"},
    Rules = rules
})
