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

    ["Attachments"] = { ir = "attachments.slots" },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions" },
    ["AttachmentElements"] = { ir = "attachments.elements" },
    ["AttachmentIcons"] = { ir = "attachments.icons" },
    ["AttachmentIcon"] = { ir = "attachments.icons" },
    ["AttachmentModels"] = { ir = "attachments.visuals" },
    ["Animations"] = { ir = "animations.base" },
    ["Hook_ModifyBodygroups"] = { ignore = "runtime hooks are not executed by adapters" }
}

FTBase.Adapters.ArcCW = FTBase.Adapters.Make({
    Name = "ArcCW",
    Provider = "arccw",
    Aliases = {"ARCW", "arccw"},
    Rules = rules
})
