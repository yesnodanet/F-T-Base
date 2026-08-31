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
    ["UseHands"] = { ir = "rendering.useHands" },
    ["ViewModel"] = { ir = "rendering.viewModel" },
    ["WorldModel"] = { ir = "rendering.worldModel" },
    ["ViewModelFOV"] = { ir = "rendering.viewModelFOV" },
    ["ViewModelFlip"] = { ir = "rendering.viewModelFlip" },
    ["Bodygroups"] = { ir = "rendering.bodygroups" },
    ["DefaultBodygroups"] = { ir = "rendering.bodygroups.default" },
    ["DefaultSkin"] = { ir = "rendering.skins.default" },
    ["DefaultWMSkin"] = { ir = "rendering.skins.world" },
    ["DefaultWMBodygroups"] = { ir = "rendering.bodygroups.world" },
    ["Elements"] = { ir = "rendering.elements" },
    ["ModelOffset"] = { ir = "rendering.modelOffsets" },
    ["MuzzleAttachment"] = { ir = "rendering.muzzleAttachment" },
    ["ShellAttachment"] = { ir = "rendering.shellAttachment" },
    ["ShellModel"] = { ir = "effects.shell" },

    ["Damage"] = { ir = "damage.base" },
    ["DamageMin"] = { ir = "damage.minimum" },
    ["Range"] = { ir = "ballistics.damageCurve.maxRange" },
    ["Penetration"] = { ir = "ballistics.penetration.power" },
    ["Num"] = { ir = "ballistics.pellets" },

    ["Delay"] = { ir = "fire.delay" },
    ["RPM"] = { ir = "fire.rpm" },
    ["Automatic"] = { ir = "fire.automatic" },
    ["Firemodes"] = { ir = "fire.modes" },
    ["ChamberSize"] = { ir = "ammo.chamberSize" },
    ["Primary.ClipSize"] = { ir = "ammo.clipSize" },
    ["Primary.DefaultClip"] = { ir = "ammo.defaultClip" },
    ["Primary.Ammo"] = { ir = "ammo.type" },

    ["AccuracyMOA"] = { ir = "spread.hip" },
    ["Dispersion"] = { ir = "spread.hip" },
    ["HipDispersion"] = { ir = "spread.hip" },
    ["MoveDispersion"] = { ir = "spread.movement" },

    ["Recoil"] = { ir = "recoil.scalar" },
    ["RecoilSide"] = { ir = "recoil.procedural.horizontal" },
    ["VisualRecoilMult"] = { ir = "camera.shake" },
    ["SightedSpeedMult"] = { ir = "movement.sightedSpeed" },
    ["FreeAimAngle"] = { ir = "camera.freeAim.radius" },
    ["Sway"] = { ir = "camera.sway" },
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

    ["ShootSound"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["ShootSoundSilenced"] = { ir = "sounds.fire.suppressed" },
    ["DistantShootSound"] = { ir = "sounds.fire.distant" },
    ["MuzzleEffect"] = { ir = "effects.muzzle" },
    ["Tracer"] = { ir = "effects.tracer" },

    ["Attachments"] = { ir = "attachments.slots", transform = normalizeAttachmentMetadata },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions", transform = normalizeAttachmentMetadata },
    ["AttachmentElements"] = { ir = "attachments.elements", transform = normalizeAttachmentMetadata },
    ["AttachmentIcons"] = { ir = "attachments.icons", transform = normalizeAttachmentMetadata },
    ["AttachmentIcon"] = { ir = "attachments.icons", transform = normalizeAttachmentMetadata },
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
    ["Animations"] = { ir = "animations.base" },
    ["Hook_ModifyBodygroups"] = { ignore = "runtime hooks are not executed by adapters" }
}

FTBase.Adapters.ArcCW = FTBase.Adapters.Make({
    Name = "ArcCW",
    Provider = "arccw",
    Aliases = {"ARCW", "arccw"},
    Rules = rules
})
