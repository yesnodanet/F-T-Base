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
    ["Attachments"] = { ir = "attachments.slots" },
    ["AttachmentDefinitions"] = { ir = "attachments.definitions" },
    ["AttachmentElements"] = { ir = "attachments.elements" },
    ["AttachmentIcons"] = { ir = "attachments.icons" },
    ["AttachmentModels"] = { ir = "attachments.visuals" },
    ["AttachmentDependencies"] = { ir = "attachments.dependencies" },
    ["AttachmentExclusions"] = { ir = "attachments.exclusions" }
}

FTBase.Adapters.TacRP = FTBase.Adapters.Make({
    Name = "TacRP",
    Provider = "tacrp",
    Aliases = {"TACRP", "tacrp"},
    Rules = rules
})
