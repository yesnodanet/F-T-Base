if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - ARC9 Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "ARC9"

FT.Visual.Default = "ARC9"

ARC9.PrintName = "F&T Template - ARC9 Dialect"
ARC9.Category = "F&T Base Templates"
ARC9.ViewModel = "models/weapons/c_irifle.mdl"
ARC9.WorldModel = "models/weapons/w_irifle.mdl"
ARC9.ViewModelFOV = 62
ARC9.DefaultBodygroups = {[0] = 0}
ARC9.DefaultSkin = 0
ARC9.Elements = {
    template_receiver = {skin = 0, bodygroups = {[0] = 0}}
}
ARC9.MuzzleAttachment = "muzzle"
ARC9.DamageMax = 32
ARC9.DamageMin = 20
ARC9.RangeMax = 2300
ARC9.RPM = 700
ARC9.Automatic = true
ARC9.ClipSize = 30
ARC9.DefaultClip = 120
ARC9.Ammo = "AR2"
ARC9.Spread = 0.012
ARC9.SpreadMultSights = 0.45
ARC9.SpreadAddMove = 0.009
ARC9.RecoilUp = 0.82
ARC9.RecoilSide = 0.18
ARC9.VisualRecoilUp = 0.24
ARC9.VisualRecoilSide = 0.05
ARC9.Sway = 0.08
ARC9.FreeAimRadius = 0.35
ARC9.Scope = {
    type = "red_dot",
    magnification = 1.2,
    reticle = "ft_base/providers/arc9/ui/att.png",
    hideWeapon = false
}
ARC9.InspectPos = Vector(-2.2, 0, -0.3)
ARC9.InspectAng = Angle(4, 22, 0)
ARC9.CustomizePos = Vector(-3.6, 0, -0.8)
ARC9.CustomizeAng = Angle(7, 34, 0)
ARC9.DrawCrosshair = true
ARC9.DrawAmmo = true
ARC9.ShootSound = "Weapon_AR2.Single"
ARC9.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
ARC9.InspectAnimation = ACT_VM_DRAW
ARC9.CustomizeAnimation = ACT_VM_DRAW
ARC9.Attachments = {
    { id = "optic", name = "Optic", type = "optic", default = "micro_red_dot" },
    { id = "underbarrel", name = "Underbarrel", type = "underbarrel", default = "vertical_grip" }
}
ARC9.AttachmentDefinitions = {
    micro_red_dot = {
        name = "Micro Red Dot",
        description = "A compact ARC9-style optic with a clean sight picture.",
        type = "optic",
        icon = "ft_base/providers/arc9/ui/att.png",
        visuals = {
            view = {
                model = "models/weapons/c_pistol.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(4.2, -1.4, 0.8),
                ang = Angle(0, 90, 0),
                scale = 0.18,
                skin = 0,
                bodygroups = {[0] = 0}
            },
            world = {
                model = "models/weapons/w_pistol.mdl",
                attachment = "muzzle",
                pos = Vector(-10, 0, 2),
                ang = Angle(0, 180, 0),
                scale = 0.16,
                materials = {[0] = "models/shiny"}
            }
        },
        modifiers = { ["spread.ads"] = { multiply = 0.74 } }
    },
    vertical_grip = {
        name = "Vertical Grip",
        description = "Stabilizes the weapon while preserving ARC9 handling.",
        type = "underbarrel",
        visuals = {
            view = {
                model = "models/props_c17/oildrum001.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(7, 0, -3),
                ang = Angle(90, 0, 0),
                scale = 0.025,
                material = "models/shiny"
            },
            world = {
                model = "models/props_c17/oildrum001.mdl",
                attachment = "muzzle",
                pos = Vector(-7, 0, -2),
                ang = Angle(90, 0, 0),
                scale = 0.025,
                elements = {skin = 0, bodygroups = {[0] = 0}}
            }
        },
        modifiers = { ["recoil.scalar"] = { multiply = 0.86 } }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
