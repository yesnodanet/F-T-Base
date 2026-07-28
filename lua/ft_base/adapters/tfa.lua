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
    ["ViewModelFOV"] = { ir = "rendering.viewModelFOV" },
    ["Secondary.ViewModelFOV"] = { ir = "rendering.viewModelFOV" },
    ["ViewModelFlip"] = { ir = "rendering.viewModelFlip" },
    ["Bodygroups_V"] = { ir = "rendering.bodygroups.view" },
    ["Bodygroups_W"] = { ir = "rendering.bodygroups.world" },
    ["VElements"] = { ir = "rendering.elements.view" },
    ["WElements"] = { ir = "rendering.elements.world" },
    ["VElementRenderOrder"] = { ir = "rendering.elements.viewOrder" },
    ["WElementRenderOrder"] = { ir = "rendering.elements.worldOrder" },
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
    ["Secondary.Scope"] = { ir = "ads.scopes" },
    ["Scope"] = { ir = "ads.scopes" },
    ["IronSightsPos"] = { ir = "ads.pos" },
    ["IronSightsAng"] = { ir = "ads.ang" },
    ["RunSightsPos"] = { ir = "camera.sprint.pos" },
    ["RunSightsAng"] = { ir = "camera.sprint.ang" },
    ["InspectPos"] = { ir = "camera.poses.inspect.pos" },
    ["InspectAng"] = { ir = "camera.poses.inspect.ang" },
    ["CustomizePos"] = { ir = "camera.poses.customize.pos" },
    ["CustomizeAng"] = { ir = "camera.poses.customize.ang" },

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
    ["InspectAnimation"] = { ir = "animations.inspect" },
    ["CustomizeAnimation"] = { ir = "ui.inspect.animation" },
    ["Attachments"] = { ir = "attachments.slots" },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions" },
    ["AttachmentDependencies"] = { ir = "attachments.dependencies" },
    ["AttachmentExclusions"] = { ir = "attachments.exclusions" },
    ["AttachmentIconOverride"] = { ir = "attachments.icons" },
    ["AttachmentViewOffset"] = { ir = "attachments.visuals" },
    ["Customization.Provider"] = { ir = "ui.customization.provider", transform = function() return "tfa" end }
}

FTBase.Adapters.TFA = FTBase.Adapters.Make({
    Name = "TFA",
    Provider = "tfa",
    Aliases = {"TFA_BASE"},
    Rules = rules
})
