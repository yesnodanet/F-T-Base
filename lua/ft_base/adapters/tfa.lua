FTBase = FTBase or {}
FTBase.Adapters = FTBase.Adapters or {}

local normalizeAttachmentMetadata = FTBase.Adapters.NormalizeAttachmentMetadata

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
    ["Author"] = { ir = "meta.author" },
    ["Manufacturer"] = { ir = "meta.manufacturer" },
    ["Caliber"] = { ir = "meta.caliber" },
    ["Description"] = { ir = "ui.inspect.description", transform = function(value) return value end },
    ["Credits"] = { ir = "ui.inspect.credits", transform = function(value) return value end },
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
    ["Primary.SpreadMultiplierMax"] = { ir = "spread.maximum" },
    ["Primary.SpreadIncrement"] = { ir = "spread.perShot" },
    ["Primary.SpreadRecovery"] = { ir = "spread.recovery" },
    ["Primary.KickUp"] = { ir = "recoil.procedural.vertical" },
    ["Primary.KickHorizontal"] = { ir = "recoil.procedural.horizontal" },
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
    ["Attachments"] = { ir = "attachments.slots", transform = normalizeAttachmentMetadata },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions", transform = normalizeAttachmentMetadata },
    ["AttachmentElements"] = { ir = "attachments.elements", transform = normalizeAttachmentMetadata },
    ["AttachmentDependencies"] = { ir = "attachments.dependencies" },
    ["AttachmentExclusions"] = { ir = "attachments.exclusions" },
    ["AttachmentIconOverride"] = { ir = "attachments.icons", transform = normalizeAttachmentMetadata },
    ["AttachmentViewOffset"] = { ir = "attachments.visuals", transform = normalizeAttachmentMetadata },
    ["InspectTitle"] = { ir = "ui.inspect.title" },
    ["InspectType"] = { ir = "ui.inspect.type" },
    ["InspectDescription"] = { ir = "ui.inspect.description", transform = function(value) return value end },
    ["InspectCredits"] = { ir = "ui.inspect.credits", transform = function(value) return value end },
    ["InspectPreview"] = { ir = "ui.inspect.preview", transform = function(value) return value end },
    ["InspectStats"] = { ir = "ui.inspect.stats", transform = function(value) return value end },
    ["InspectFalloff"] = { ir = "ui.inspect.falloff", transform = function(value) return value end },
    ["InspectHints"] = { ir = "ui.inspect.hints", transform = function(value) return value end },
    ["InspectBlur"] = { ir = "ui.inspect.blur" },
    ["HideHUD"] = { ir = "ui.inspect.hideHud" },
    ["Customization.Title"] = { ir = "ui.customization.title" },
    ["Customization.Presets"] = { ir = "ui.customization.presets", transform = function(value) return value end },
    ["Customization.Controls"] = { ir = "ui.customization.controls", transform = function(value) return value end },
    ["Customization.Stats"] = { ir = "ui.customization.stats", transform = function(value) return value end },
    ["Customization.Hints"] = { ir = "ui.customization.hints", transform = function(value) return value end },
    ["Customization.Preview"] = { ir = "ui.customization.preview", transform = function(value) return value end },
    ["Customization.Animations"] = { ir = "ui.customization.animations", transform = function(value) return value end },
    ["Customization.Provider"] = { ir = "ui.customization.provider", transform = function() return "tfa" end }
}

FTBase.Adapters.TFA = FTBase.Adapters.Make({
    Name = "TFA",
    Provider = "tfa",
    Aliases = {"TFA_BASE"},
    Rules = rules
})
