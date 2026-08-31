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
    ["ViewModel"] = { ir = "rendering.viewModel" },
    ["WorldModel"] = { ir = "rendering.worldModel" },
    ["HoldType"] = { ir = "rendering.holdType" },
    ["ViewModelFOV"] = { ir = "rendering.viewModelFOV" },
    ["ViewModelFlip"] = { ir = "rendering.viewModelFlip" },
    ["Bodygroups"] = { ir = "rendering.bodygroups" },
    ["Bodygroups_V"] = { ir = "rendering.bodygroups.view" },
    ["Bodygroups_W"] = { ir = "rendering.bodygroups.world" },
    ["VElements"] = { ir = "rendering.elements.view" },
    ["WElements"] = { ir = "rendering.elements.world" },
    ["Elements"] = { ir = "rendering.elements" },
    ["ModelOffset"] = { ir = "rendering.modelOffsets" },

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
    ["AimPos"] = { ir = "ads.pos" },
    ["AimAng"] = { ir = "ads.ang" },
    ["ZoomAmount"] = { ir = "ads.magnification" },
    ["SpeedDec"] = { ir = "movement.sightedSpeed" },
    ["InspectPos"] = { ir = "camera.poses.inspect.pos" },
    ["InspectAng"] = { ir = "camera.poses.inspect.ang" },
    ["CustomizePos"] = { ir = "camera.poses.customize.pos" },
    ["CustomizeAng"] = { ir = "camera.poses.customize.ang" },
    ["InspectAnimation"] = { ir = "animations.inspect" },
    ["CustomizeAnimation"] = { ir = "ui.inspect.animation" },
    ["DrawCrosshair"] = { ir = "ui.crosshair" },
    ["DrawAmmo"] = { ir = "ui.drawAmmo" },

    ["Animations"] = { ir = "animations.base" },
    ["Attachments"] = { ir = "attachments.slots", transform = normalizeAttachmentMetadata },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions", transform = normalizeAttachmentMetadata },
    ["AttachmentElements"] = { ir = "attachments.elements", transform = normalizeAttachmentMetadata },
    ["AttachmentIcons"] = { ir = "attachments.icons", transform = normalizeAttachmentMetadata },
    ["AttachmentModels"] = { ir = "attachments.visuals", transform = normalizeAttachmentMetadata },
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
    ["Customization.Provider"] = { ir = "ui.customization.provider", transform = function() return "swb" end }
}

FTBase.Adapters.SWB = FTBase.Adapters.Make({
    Name = "SWB",
    Provider = "swb",
    Aliases = {"swb"},
    Rules = rules
})
