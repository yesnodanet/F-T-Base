if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - SWB Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "SWB"

FT.Visual.Default = "SWB"

SWB.PrintName = "F&T Template - SWB Dialect"
SWB.Category = "F&T Base Templates"
SWB.ViewModel = "models/weapons/c_smg1.mdl"
SWB.WorldModel = "models/weapons/w_smg1.mdl"
SWB.HoldType = "smg"
SWB.ViewModelFOV = 62
SWB.Bodygroups_V = {[0] = 0}
SWB.Bodygroups_W = {[0] = 0}
SWB.VElements = {
    template_receiver = {skin = 0, bodygroups = {[0] = 0}}
}
SWB.WElements = {
    template_receiver = {skin = 0, bodygroups = {[0] = 0}}
}

SWB.Damage = 26
SWB.NumShots = 1
SWB.FireDelay = 0.075
SWB.Automatic = true
SWB.ClipSize = 36
SWB.DefaultClip = 144
SWB.Ammo = "SMG1"
SWB.HipSpread = 0.019
SWB.AimSpread = 0.008
SWB.SpreadPerShot = 0.001
SWB.MaxSpreadInc = 0.012
SWB.FireSound = "Weapon_SMG1.Single"
SWB.ReloadSound = "Weapon_SMG1.Reload"
SWB.ReloadDuration = 2.35

SWB.Recoil = 1
SWB.KickUp = 0.7
SWB.KickSide = 0.3
SWB.RecoilPattern = {
    {-0.08, 0.7},
    {0.1, 0.82},
    {-0.12, 0.94},
    {0.13, 1.05}
}

SWB.AimFOV = 62
SWB.AimPos = Vector(-5, -4.5, 1.8)
SWB.AimAng = Angle(0, 0, 0)
SWB.ZoomAmount = 1.15
SWB.SpeedDec = 0.82
SWB.InspectPos = Vector(-2.1, 0, -0.3)
SWB.InspectAng = Angle(3, 21, 0)
SWB.CustomizePos = Vector(-3.2, 0, -0.8)
SWB.CustomizeAng = Angle(6, 30, 0)
SWB.DrawCrosshair = true
SWB.DrawAmmo = true
SWB.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
SWB.InspectAnimation = ACT_VM_DRAW
SWB.CustomizeAnimation = ACT_VM_DRAW

SWB.Attachments = {
    { id = "optic", name = "Optic", type = "optic", default = "holo" },
    { id = "stock", name = "Stock", type = "stock", default = "light_stock" }
}

SWB.AttachmentDefinitions = {
    holo = {
        name = "Holographic Sight",
        description = "Improves aimed precision.",
        type = "optic",
        icon = "ft_base/providers/swb/rifle_aim",
        visuals = {
            view = {
                model = "models/weapons/c_pistol.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(4, -1.4, 0.7),
                ang = Angle(0, 90, 0),
                scale = 0.18,
                skin = 0,
                bodygroups = {[0] = 0}
            },
            world = {
                model = "models/weapons/w_pistol.mdl",
                attachment = "muzzle",
                pos = Vector(-9, 0, 2),
                ang = Angle(0, 180, 0),
                scale = 0.16,
                materials = {[0] = "models/shiny"}
            }
        },
        modifiers = {
            ["spread.ads"] = { multiply = 0.72 }
        }
    },
    light_stock = {
        name = "Light Stock",
        description = "Faster aim transition with less recoil recovery.",
        type = "stock",
        visuals = {
            view = {
                model = "models/props_c17/oildrum001.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(-4, 0, 0),
                ang = Angle(90, 0, 0),
                scale = 0.025,
                material = "models/shiny"
            },
            world = {
                model = "models/props_c17/oildrum001.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(-4, 0, 0),
                ang = Angle(90, 0, 0),
                scale = 0.025,
                elements = {skin = 0, bodygroups = {[0] = 0}}
            }
        },
        modifiers = {
            ["ads.speed"] = { multiply = 1.2 },
            ["recoil.scalar"] = { multiply = 0.9 }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
