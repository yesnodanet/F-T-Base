FTBase = FTBase or {}
FTBase.Adapters = FTBase.Adapters or {}

local normalizeAttachmentMetadata = FTBase.Adapters.NormalizeAttachmentMetadata

local function fireLayer(value)
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
    ["DefaultBodygroups"] = { ir = "rendering.bodygroups.default" },
    ["DefaultWMBodygroups"] = { ir = "rendering.bodygroups.world" },
    ["DefaultSkin"] = { ir = "rendering.skins.default" },
    ["DefaultWMSkin"] = { ir = "rendering.skins.world" },
    ["Elements"] = { ir = "rendering.elements" },
    ["ModelOffset"] = { ir = "rendering.modelOffsets" },

    ["Damage_Max"] = { ir = "damage.base" },
    ["Damage_Min"] = { ir = "damage.minimum" },
    ["BodyDamageMultipliers"] = { ir = "damage.hitgroups" },
    ["Range_Max"] = { ir = "ballistics.damageCurve.maxRange" },
    ["Range_Min"] = { ir = "ballistics.damageCurve.minRange" },
    ["MuzzleVelocity"] = { ir = "ballistics.muzzleVelocity" },
    ["Penetration"] = { ir = "ballistics.penetration.power" },
    ["ArmorPenetration"] = { ir = "ballistics.armor.scale" },
    ["Num"] = { ir = "ballistics.pellets" },

    ["RPM"] = { ir = "fire.rpm" },
    ["FireDelay"] = { ir = "fire.delay" },
    ["Automatic"] = { ir = "fire.automatic" },
    ["ClipSize"] = { ir = "ammo.clipSize" },
    ["DefaultClip"] = { ir = "ammo.defaultClip" },
    ["Ammo"] = { ir = "ammo.type" },

    ["Spread"] = { ir = "spread.hip" },
    ["Spread_Sights"] = { ir = "spread.ads" },
    ["Spread_Move"] = { ir = "spread.movement" },

    ["RecoilKick"] = { ir = "recoil.procedural.vertical" },
    ["RecoilSpreadPenalty"] = { ir = "spread.perShot" },
    ["RecoilStability"] = { ir = "recoil.procedural.recovery" },

    ["FreeAimAngle"] = { ir = "camera.freeAim.radius" },
    ["BlindFire"] = { ir = "movement.blindFire" },
    ["Sway"] = { ir = "camera.sway" },
    ["AimFOV"] = { ir = "ads.fov" },
    ["AimPos"] = { ir = "ads.pos" },
    ["AimAng"] = { ir = "ads.ang" },
    ["CustomizePos"] = { ir = "camera.poses.customize.pos" },
    ["CustomizeAng"] = { ir = "camera.poses.customize.ang" },
    ["InspectPos"] = { ir = "camera.poses.inspect.pos" },
    ["InspectAng"] = { ir = "camera.poses.inspect.ang" },
    ["CustomizeAnimation"] = { ir = "ui.inspect.animation" },
    ["InspectAnimation"] = { ir = "animations.inspect" },
    ["Sight"] = { ir = "ads.scopes" },
    ["Scope"] = { ir = "ads.scopes" },
    ["DrawCrosshair"] = { ir = "ui.crosshair" },
    ["DrawAmmo"] = { ir = "ui.drawAmmo" },

    ["Sound_Shoot"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["Sound_Shoot_Silenced"] = { ir = "sounds.fire.suppressed" },
    ["Sound_Shoot_Distant"] = { ir = "sounds.fire.distant" },
    ["MuzzleEffect"] = { ir = "effects.muzzle" },
    ["Tracer"] = { ir = "effects.tracer" },

    ["ReloadTimeMult"] = { ir = "movement.reloadSpeed" },
    ["Animations"] = { ir = "animations.base" },
    ["Attachments"] = { ir = "attachments.slots", transform = normalizeAttachmentMetadata },
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
    ["Customization.Animations"] = { ir = "ui.customization.animations", transform = function(value) return value end }
}

FTBase.Adapters.TacRP = FTBase.Adapters.Make({
    Name = "TacRP",
    Provider = "tacrp",
    Aliases = {"TACRP", "tacrp"},
    Rules = rules
})
