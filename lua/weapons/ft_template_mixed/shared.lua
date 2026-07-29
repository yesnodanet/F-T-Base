if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - Mixed TFA SWB MW"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "TFA"
using "SWB"
using "MW"

FT.Priority = { "TFA", "MW", "SWB" }
FT.Customization.Provider = "mixed"
FT.Visual.Default = "TFA"
FT.Visual.Inspect = "TFA"
FT.Visual.Attachments = "MW"
FT.Visual.HUD = "TFA"
FT.Visual.Presentation = "TFA"
FT.Merge = {
    ["recoil.procedural.vertical"] = "maximum",
    ["spread.ads"] = "minimum"
}

TFA.PrintName = "F&T Template - Mixed TFA SWB MW"
TFA.Category = "F&T Base Templates"
TFA.ViewModel = "models/weapons/tfa_ins2/c_cw_ar15.mdl"
TFA.WorldModel = "models/weapons/tfa_ins2/w_cw_ar15.mdl"
TFA.HoldType = "ar2"
TFA.UseHands = true
TFA.ViewModelFOV = 60
TFA.Description = "A mixed-domain fixture using the TFA AR-15 presentation and MW Gunsmith attachments."
TFA.Credits = "TFA Insurgency sample model; MW M4A1 attachment surface"
TFA.Bodygroups_V = {[0] = 0}
TFA.Bodygroups_W = {[0] = 0}
TFA.VElements = {
    receiver = {
        type = "Model",
        model = "models/weapons/tfa_ins2/upgrades/f_ar15_m4barrel.mdl",
        bone = "Weapon",
        pos = Vector(0, 0, 0.25),
        angle = Angle(0, 0, 0),
        size = Vector(1, 1, 1),
        active = true,
        bonemerge = false
    }
}
TFA.WElements = {
    receiver = {
        type = "Model",
        model = "models/weapons/tfa_ins2/upgrades/w_ar15_30mag.mdl",
        bone = "ATTACH_Standard",
        pos = Vector(0, 0, 0),
        angle = Angle(0, 0, 0),
        size = Vector(1, 1, 1),
        active = true,
        bonemerge = true
    }
}
TFA.Primary.Damage = 33
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 120
TFA.Primary.Ammo = "AR2"
TFA.Primary.Automatic = true
TFA.Primary.Sound = "TFA_INS2.CW_AR15.1"
TFA.Primary.RPM = 700
TFA.Primary.Cone = 0.02
TFA.Primary.IronAccuracy = 0.005
TFA.KickUp = 0.4
TFA.KickHorizontal = 0.2
TFA.ReloadSound = "TFA_INS2.CW_AR15.Reload"
TFA.ReloadDuration = 2.1
TFA.InspectTitle = "AR-15"
TFA.InspectType = "ASSAULT RIFLE"
TFA.InspectDescription = "TFA inspect and HUD remain authoritative while MW owns attachment presentation."
TFA.InspectCredits = "TFA Insurgency / Modern Warfare 2019 Sweps"
TFA.InspectPreview = {model = "models/weapons/tfa_ins2/c_cw_ar15.mdl", fov = 60}
TFA.InspectStats = {
    {label = "DAMAGE", path = "damage.base", value = 33},
    {label = "FIRE RATE", path = "fire.rpm", value = 700},
    {label = "ACCURACY", path = "spread.ads", value = 0.005}
}
TFA.InspectFalloff = {
    {range = 0, multiplier = 1},
    {range = 100, multiplier = 0.7},
    {range = 180, multiplier = 0}
}
TFA.InspectHints = {"TFA inspect controls are active", "MW owns the attachment surface"}
TFA.Customization.Title = "TFA / MW CUSTOMIZE"
TFA.Customization.Controls = {"MOUSE: SELECT", "LEFT CLICK: INSTALL", "RIGHT CLICK: REMOVE"}
TFA.Customization.Stats = {{label = "DAMAGE", path = "damage.base"}, {label = "RECOIL", path = "recoil.procedural.vertical"}}
TFA.Customization.Hints = {"TFA presentation and HUD are preserved for this mixed weapon"}
TFA.Customization.Preview = {model = "models/weapons/tfa_ins2/c_cw_ar15.mdl", fov = 60}
TFA.Customization.Animations = {
    open = {sequence = "draw"},
    inspect = {sequence = "idle"},
    install = {sequence = "idle"},
    remove = {sequence = "idle"}
}
TFA.Secondary.IronFOV = 58
TFA.Secondary.Scope = {
    enabled = true,
    magnification = 1.25,
    reticle = "sprites/redglow1"
}
TFA.IronSightsPos = Vector(-6.2, -2.8, 1.25)
TFA.IronSightsAng = Angle(0, 0, 0)
TFA.InspectPos = Vector(4, -2, -2)
TFA.InspectAng = Angle(12, 30, -8)
TFA.CustomizePos = Vector(3.5, -1, -1.5)
TFA.CustomizeAng = Angle(6, 20, -5)
TFA.InspectAnimation = ACT_VM_IDLE
TFA.CustomizeAnimation = ACT_VM_IDLE
TFA.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}

SWB.FireDelay = 0.082
SWB.HipSpread = 0.014
SWB.AimSpread = 0.006
SWB.RecoilPattern = {
    {0, 0.75},
    {-0.12, 0.92},
    {0.14, 1.08},
    {-0.16, 1.18}
}

MW.DamageMin = 21
MW.Range = 2200
MW.Penetration = 6
MW.Camera.Shake = 0.22
MW.Camera.Sway = 0.1
MW.Aim.FOV = 60
MW.Aim.Speed = 1.2
MW.Customization.Title = "GUNSMITH"
MW.Customization.Presets = {"DEFAULT", "MIXED AR-15"}
MW.Customization.Controls = {"MOUSE: SELECT", "LEFT CLICK: INSTALL", "RIGHT CLICK: REMOVE"}
MW.Customization.Stats = {
    {label = "DAMAGE", path = "damage.base"},
    {label = "ACCURACY", path = "spread.ads"},
    {label = "CONTROL", path = "recoil.procedural.vertical"}
}
MW.Customization.Hints = {"MW owns this attachment surface; TFA owns inspect and HUD"}
MW.Customization.Preview = {model = "models/weapons/tfa_ins2/c_cw_ar15.mdl", fov = 60}

MW.Attachments = {
    slots = {
        { id = "optic", name = "Optic", type = "optic", default = "hybrid_optic" },
        { id = "muzzle", name = "Muzzle", type = "muzzle", default = "brake" }
    },
    definitions = {
        hybrid_optic = {
            name = "Hybrid Optic",
            description = "Combines the precise sight picture of the mixed platform.",
            type = "optic",
            folder = "Optic",
            pros = {"Aim precision"},
            cons = {"Aim speed"},
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_carryhandle.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0),
                    skin = 0
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_carryhandle.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0),
                    skin = 0
                }
            },
            modifiers = {
                ["spread.ads"] = { multiply = 0.7 },
                ["ads.fov"] = { add = -5 }
            }
        },
        brake = {
            name = "Muzzle Brake",
            description = "Limits camera shake and vertical recoil.",
            type = "muzzle",
            folder = "Muzzle",
            pros = {"Recoil control"},
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_barsil.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_barsil.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["camera.shake"] = { multiply = 0.72 },
                ["recoil.scalar"] = { multiply = 0.84 }
            }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
