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
    ["WorldModelMirror"] = { ir = "rendering.worldModelMirror" },
    ["VModel"] = { ir = "rendering.viewModel" },
    ["WModel"] = { ir = "rendering.worldModel" },
    ["ViewModelFOV"] = { ir = "rendering.viewModelFOV" },
    ["ViewModelFOVBase"] = { ir = "rendering.viewModelFOV" },
    ["ViewModelFlip"] = { ir = "rendering.viewModelFlip" },
    ["Bodygroups"] = { ir = "rendering.bodygroups" },
    ["DefaultBodygroups"] = { ir = "rendering.bodygroups.default" },
    ["DefaultSkin"] = { ir = "rendering.skins.default" },
    ["Elements"] = { ir = "rendering.elements" },
    ["ModelOffset"] = { ir = "rendering.modelOffsets" },
    ["MuzzleAttachment"] = { ir = "rendering.muzzleAttachment" },
    ["ShellAttachment"] = { ir = "rendering.shellAttachment" },

    ["DamageMax"] = { ir = "damage.base" },
    ["DamageMin"] = { ir = "damage.minimum" },
    ["RangeMax"] = { ir = "ballistics.damageCurve.maxRange" },
    ["RangeMin"] = { ir = "ballistics.damageCurve.minRange" },
    ["PhysBulletMuzzleVelocity"] = { ir = "ballistics.muzzleVelocity" },
    ["Penetration"] = { ir = "ballistics.penetration.power" },
    ["Num"] = { ir = "ballistics.pellets" },

    ["RPM"] = { ir = "fire.rpm" },
    ["Firemode"] = { ir = "fire.modes" },
    ["Firemodes"] = { ir = "fire.modes" },
    ["Automatic"] = { ir = "fire.automatic" },
    ["ClipSize"] = { ir = "ammo.clipSize" },
    ["DefaultClip"] = { ir = "ammo.defaultClip" },
    ["Ammo"] = { ir = "ammo.type" },

    ["Spread"] = { ir = "spread.hip" },
    ["SpreadMultSights"] = { ir = "spread.ads", merge = "multiply" },
    ["SpreadAddMove"] = { ir = "spread.movement" },
    ["SpreadAddRecoil"] = { ir = "spread.perShot" },
    ["SpreadSights"] = { ir = "spread.ads" },

    ["Recoil.Up"] = { ir = "recoil.procedural.vertical" },
    ["Recoil.Side"] = { ir = "recoil.procedural.horizontal" },
    ["Recoil.Roll"] = { ir = "recoil.procedural.roll" },
    ["Recoil.RandomUp"] = { ir = "recoil.procedural.randomness" },
    ["Recoil.RandomSide"] = { ir = "recoil.procedural.randomness", merge = "maximum" },
    ["Recoil.Pattern"] = { ir = "recoil.pattern" },
    ["RecoilUp"] = { ir = "recoil.procedural.vertical" },
    ["RecoilSide"] = { ir = "recoil.procedural.horizontal" },
    ["RecoilRandomUp"] = { ir = "recoil.procedural.randomness" },
    ["RecoilRandomSide"] = { ir = "recoil.procedural.randomness", merge = "maximum" },

    ["VisualRecoilUp"] = { ir = "camera.shake" },
    ["VisualRecoilSide"] = { ir = "camera.microJitter" },
    ["Sway"] = { ir = "camera.sway" },
    ["FreeAimRadius"] = { ir = "camera.freeAim.radius" },
    ["FreeAim"] = { ir = "camera.freeAim" },
    ["CustomizePos"] = { ir = "camera.poses.customize.pos" },
    ["CustomizeAng"] = { ir = "camera.poses.customize.ang" },
    ["CustomizeSnapshotPos"] = { ir = "ui.customization.preview.pos" },
    ["CustomizeSnapshotFOV"] = { ir = "ui.customization.preview.fov" },
    ["InspectPos"] = { ir = "camera.poses.inspect.pos" },
    ["InspectAng"] = { ir = "camera.poses.inspect.ang" },
    ["CustomizeAnimation"] = { ir = "ui.inspect.animation" },
    ["InspectAnimation"] = { ir = "animations.inspect" },
    ["Sight"] = { ir = "ads.scopes" },
    ["Scope"] = { ir = "ads.scopes" },
    ["DrawCrosshair"] = { ir = "ui.crosshair" },
    ["DrawAmmo"] = { ir = "ui.drawAmmo" },

    ["ShootSound"] = { ir = "sounds.fire.layers", transform = fireLayer },
    ["DistantShootSound"] = { ir = "sounds.fire.distant" },
    ["SilencerShootSound"] = { ir = "sounds.fire.suppressed" },
    ["MuzzleParticle"] = { ir = "effects.muzzle" },
    ["ShellModel"] = { ir = "effects.shell" },

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
    ["Hook_TranslateAnimation"] = { ignore = "runtime hooks are not executed by adapters" }
}

FTBase.Adapters.ARC9 = FTBase.Adapters.Make({
    Name = "ARC9",
    Provider = "arc9",
    Aliases = {"arc9"},
    Rules = rules
})
