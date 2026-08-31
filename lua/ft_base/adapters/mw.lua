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
    ["SubCategory"] = { ir = "meta.subCategory" },
    ["Author"] = { ir = "meta.author" },
    ["Manufacturer"] = { ir = "meta.manufacturer" },
    ["Caliber"] = { ir = "meta.caliber" },
    ["Description"] = { ir = "ui.inspect.description", transform = function(value) return value end },
    ["Credits"] = { ir = "ui.inspect.credits", transform = function(value) return value end },
    ["Spawnable"] = { ir = "meta.spawnable" },
    ["UseHands"] = { ir = "rendering.useHands" },
    ["ViewModel"] = { ir = "rendering.viewModel" },
    ["WorldModel"] = { ir = "rendering.worldModel" },
    ["HoldType"] = { ir = "rendering.holdType" },
    ["ViewModelFOV"] = { ir = "rendering.viewModelFOV" },
    ["ViewModelFlip"] = { ir = "rendering.viewModelFlip" },
    ["VModel"] = { ir = "rendering.viewModel" },
    ["Bodygroups"] = { ir = "rendering.bodygroups" },
    ["DefaultBodygroups"] = { ir = "rendering.bodygroups.default" },
    ["DefaultSkin"] = { ir = "rendering.skins.default" },
    ["Elements"] = { ir = "rendering.elements" },
    ["ModelOffset"] = { ir = "rendering.modelOffsets" },

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
    ["DefaultClip"] = { ir = "ammo.defaultClip" },
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
    ["Aim.Pos"] = { ir = "ads.pos" },
    ["Aim.Ang"] = { ir = "ads.ang" },
    ["Aim.Scope"] = { ir = "ads.scopes" },
    ["Zoom"] = { ir = "ads.scopes" },
    ["CustomizePos"] = { ir = "camera.poses.customize.pos" },
    ["CustomizeAng"] = { ir = "camera.poses.customize.ang" },
    ["InspectPos"] = { ir = "camera.poses.inspect.pos" },
    ["InspectAng"] = { ir = "camera.poses.inspect.ang" },
    ["CustomizeAnimation"] = { ir = "ui.inspect.animation" },
    ["InspectAnimation"] = { ir = "animations.inspect" },
    ["DrawCrosshair"] = { ir = "ui.crosshair" },
    ["DrawAmmo"] = { ir = "ui.drawAmmo" },

    ["Sound.Fire"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["Sound.FireDistant"] = { ir = "sounds.fire.distant" },
    ["Sound.FireSuppressed"] = { ir = "sounds.fire.suppressed" },
    ["Sound.IndoorTail"] = { ir = "sounds.fire.indoorTail" },
    ["Sound.OutdoorTail"] = { ir = "sounds.fire.outdoorTail" },
    ["Sound.Mechanical"] = { ir = "sounds.mechanical" },
    ["Sound.Reload"] = { ir = "sounds.reload.reload" },
    ["Reload.Duration"] = { ir = "animations.reloadDuration" },

    ["Effects.Muzzle"] = { ir = "effects.muzzle" },
    ["Effects.Tracer"] = { ir = "effects.tracer" },
    ["Animations"] = { ir = "animations.base" },
    ["Attachments"] = { ir = "attachments.slots", transform = normalizeAttachmentMetadata },
    ["Attachments.Slots"] = { ir = "attachments.slots", transform = normalizeAttachmentMetadata },
    ["Attachments.Definitions"] = { ir = "attachments.definitions", transform = normalizeAttachmentMetadata },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions", transform = normalizeAttachmentMetadata },
    ["AttachmentElements"] = { ir = "attachments.elements", transform = normalizeAttachmentMetadata },
    ["AttachmentIcons"] = { ir = "attachments.icons", transform = normalizeAttachmentMetadata },
    ["AttachmentModels"] = { ir = "attachments.visuals", transform = normalizeAttachmentMetadata },
    ["AttachmentDependencies"] = { ir = "attachments.dependencies" },
    ["AttachmentExclusions"] = { ir = "attachments.exclusions" },
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
    ["Customization.Provider"] = { ir = "ui.customization.provider", transform = function() return "mw" end }
}

FTBase.Adapters.MW = FTBase.Adapters.Make({
    Name = "MW",
    Provider = "mw",
    Aliases = {"MWBase", "MW Base", "ModernWarfare"},
    Rules = rules
})
