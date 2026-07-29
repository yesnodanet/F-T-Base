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
TFA.ViewModel = "models/weapons/c_irifle.mdl"
TFA.WorldModel = "models/weapons/w_irifle.mdl"
TFA.HoldType = "ar2"
TFA.UseHands = true
TFA.ViewModelFOV = 60
TFA.Bodygroups_V = {[0] = 0}
TFA.Bodygroups_W = {[0] = 0}
TFA.VElements = {
    receiver = {skin = 0, bodygroups = {[0] = 0}}
}
TFA.WElements = {
    receiver = {skin = 0, bodygroups = {[0] = 0}}
}
TFA.Primary.Damage = 30
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 120
TFA.Primary.Ammo = "AR2"
TFA.Primary.Automatic = true
TFA.Primary.Sound = "Weapon_AR2.Single"
TFA.KickUp = 0.78
TFA.KickHorizontal = 0.18
TFA.ReloadSound = "Weapon_AR2.Reload"
TFA.ReloadDuration = 2.1
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
            icon = "ft_base/providers/mw/mw_logo.png",
            visuals = {
                view = {
                    model = "models/weapons/c_pistol.mdl",
                    bone = "ValveBiped.Bip01_R_Hand",
                    pos = Vector(5.5, -1.4, 2.6),
                    ang = Angle(0, 90, 0),
                    scale = 0.18,
                    skin = 0,
                    bodygroups = {[0] = 0},
                    elements = {bodygroups = {[0] = 0}}
                },
                world = {
                    model = "models/weapons/w_pistol.mdl",
                    attachment = "muzzle",
                    pos = Vector(-8, 0, 2),
                    ang = Angle(0, 90, 0),
                    scale = 0.18,
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
            visuals = {
                view = {
                    model = "models/props_c17/TrapPropeller_Engine.mdl",
                    attachment = "muzzle",
                    pos = Vector(2.5, 0, 0),
                    ang = Angle(0, 90, 0),
                    scale = 0.035,
                    material = "models/shiny",
                    bodygroups = {[0] = 0}
                },
                world = {
                    model = "models/props_c17/TrapPropeller_Engine.mdl",
                    attachment = "muzzle",
                    pos = Vector(2, 0, 0),
                    ang = Angle(0, 90, 0),
                    scale = 0.035,
                    material = "models/shiny"
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
