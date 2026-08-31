if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - TacRP ACR"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "TacRP"

FT.Visual.Default = "TacRP"

TacRP.PrintName = "Bushmaster ACR"
TacRP.Category = "Tactical RP"
TacRP.Description = "Civilian rifle offered as an advanced alternative to other popular platforms. Well-rounded and able to accept modern ammunition."
TacRP.Credits = "Model: End of Days; Texture: IppE; Sounds: Strelok and XLongWayHome; Animation: Tactical Intervention"
TacRP.Manufacturer = "Bushmaster Firearms LLC"
TacRP.Caliber = "5.56x45mm"
TacRP.ViewModel = "models/weapons/tacint_shark/v_masada.mdl"
TacRP.WorldModel = "models/weapons/tacint_shark/w_masada.mdl"
TacRP.DefaultSkin = 1
TacRP.HoldType = "ar2"

TacRP.InspectTitle = "BUSHMASTER ACR"
TacRP.InspectType = "ASSAULT RIFLE"
TacRP.InspectDescription = "A well-rounded civilian rifle with a modular Tactical RP attachment layout."
TacRP.InspectCredits = "End of Days / IppE / Strelok / XLongWayHome"
TacRP.InspectPreview = {
    model = "models/weapons/tacint_shark/v_masada.mdl",
    viewModel = "models/weapons/tacint_shark/v_masada.mdl",
    fov = 60,
    skin = 1
}
TacRP.InspectStats = {
    {label = "DAMAGE", path = "damage.base", value = 25},
    {label = "FIRE RATE", path = "fire.rpm", value = 550},
    {label = "PENETRATION", path = "ballistics.penetration.power", value = 7},
    {label = "STABILITY", path = "recoil.procedural.recovery", value = 0.55}
}
TacRP.InspectFalloff = {
    {range = 1000, multiplier = 1},
    {range = 2000, multiplier = 0.7},
    {range = 3000, multiplier = 0}
}
TacRP.InspectHints = {"Use the slot grid to inspect compatible TacRP categories"}
TacRP.InspectBlur = true
TacRP.HideHUD = true
TacRP.Customization.Title = "ATTACHMENTS"
TacRP.Customization.Presets = {"DEFAULT", "ACR"}
TacRP.Customization.Controls = {"MOUSE: SELECT SLOT", "LEFT CLICK: INSTALL", "RIGHT CLICK: REMOVE"}
TacRP.Customization.Stats = {
    {label = "DAMAGE", path = "damage.base"},
    {label = "ACCURACY", path = "spread.ads"},
    {label = "HANDLING", path = "movement.speed"},
    {label = "RECOIL", path = "recoil.procedural.vertical"}
}
TacRP.Customization.Hints = {"Compatible categories are shown for each slot"}
TacRP.Customization.Preview = {
    model = "models/weapons/tacint_shark/v_masada.mdl",
    fov = 60,
    skin = 1
}
TacRP.Customization.Animations = {
    open = {sequence = "draw"},
    inspect = {sequence = "inspect"},
    install = {sequence = "fire1_M"},
    remove = {sequence = "fire_iron"}
}

TacRP.Damage_Max = 25
TacRP.Damage_Min = 14
TacRP.Range_Min = 1000
TacRP.Range_Max = 3000
TacRP.Penetration = 7
TacRP.ArmorPenetration = 0.7
TacRP.MuzzleVelocity = 25000
TacRP.RPM = 550
TacRP.Automatic = true
TacRP.Spread = 0.003
TacRP.Spread_Sights = 0.003
TacRP.Spread_Move = 0.003
TacRP.RecoilSpreadPenalty = 0.0018
TacRP.RecoilKick = 3
TacRP.RecoilStability = 0.55
TacRP.FreeAimAngle = 4.5
TacRP.BlindFire = true
TacRP.Sway = 1.25
TacRP.ReloadTimeMult = 1
TacRP.AimFOV = 70
TacRP.AimPos = Vector(-3.8, -7, -4.5)
TacRP.AimAng = Angle(0.66, -0.1, -1.4)
TacRP.InspectPos = Vector(0, -1, -2)
TacRP.InspectAng = Angle(12, 24, 0)
TacRP.CustomizePos = Vector(0, -1, -1)
TacRP.CustomizeAng = Angle(8, 28, 0)
TacRP.InspectAnimation = {sequence = "inspect"}
TacRP.CustomizeAnimation = {sequence = "draw"}
TacRP.Scope = {
    magnification = 1.1,
    reticle = "sprites/redglow1",
    hideWeapon = false
}
TacRP.ClipSize = 30
TacRP.Ammo = "smg1"
TacRP.Sound_Shoot = "Tacint_shark/weapons/masada/masada_unsil.wav"
TacRP.Sound_Shoot_Silenced = "Tacint_shark/weapons/masada/masada_sil.wav"
TacRP.MuzzleEffect = "muzzleflash_ak47"
TacRP.Animations = {
    fire = {sequence = "fire1_M"},
    fire_iron = {sequence = "dryfire"},
    reload = {sequence = "reload"},
    deploy = {sequence = "draw"},
    inspect = {sequence = "inspect"}
}

TacRP.AttachmentElements = {
    foldstock = {
        BGs_VM = {{1, 1}},
        BGs_WM = {{1, 1}}
    },
    sights = {
        BGs_VM = {{2, 1}, {3, 1}},
        BGs_WM = {{2, 1}}
    }
}

TacRP.Attachments = {
    {id = "optic", name = "Optic", type = {"optic_cqb", "optic_medium"}},
    {id = "muzzle", name = "Muzzle", type = "silencer"},
    {id = "tactical", name = "Tactical", type = {"tactical", "tactical_zoom", "tactical_ebullet"}},
    {id = "accessory", name = "Accessory", type = {"acc", "acc_foldstock2", "acc_sling", "acc_duffle", "perk_extendedmag"}},
    {id = "bolt", name = "Bolt", type = "bolt_automatic"},
    {id = "trigger", name = "Trigger", type = "trigger_semi"},
    {id = "ammo", name = "Ammo", type = {"ammo_rifle", "ammo_masada"}},
    {id = "perk", name = "Perk", type = {"perk", "perk_melee", "perk_shooting", "perk_reload"}}
}

TacRP.AttachmentDefinitions = {
    sights = {
        name = "Optic Mount",
        type = "optic",
        icon = "entities/tacrp_eo_masada",
        elements = {sights = true}
    },
    foldstock = {
        name = "Folding Stock",
        type = "stock",
        icon = "entities/tacrp_eo_masada",
        elements = {foldstock = true}
    },
    masada_magazine = {
        name = "ACR Magazine",
        type = "magazine",
        icon = "entities/tacrp_eo_masada",
            visuals = {
                view = {
                    model = "models/weapons/tacint_shark/magazines/masada.mdl",
                    bone = "ValveBiped.m4_rootbone",
                    pos = Vector(-1.55, 25, 0),
                    ang = Angle(90, 0, 0),
                    skin = 1,
                    bodygroups = {[0] = 0}
                },
                world = {
                    model = "models/weapons/tacint_shark/magazines/masada.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0),
                    skin = 1,
                    bodygroups = {[0] = 0}
                }
            }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
