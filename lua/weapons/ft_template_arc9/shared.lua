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

ARC9.PrintName = "F&T Template - ARC9 Dialect"
ARC9.Category = "F&T Base Templates"
ARC9.ViewModel = "models/weapons/c_irifle.mdl"
ARC9.WorldModel = "models/weapons/w_irifle.mdl"
ARC9.DamageMax = 32
ARC9.DamageMin = 20
ARC9.RangeMax = 2300
ARC9.RPM = 700
ARC9.Automatic = true
ARC9.ClipSize = 30
ARC9.DefaultClip = 120
ARC9.Ammo = "AR2"
ARC9.Spread = 0.012
ARC9.RecoilUp = 0.82
ARC9.RecoilSide = 0.18
ARC9.ShootSound = "Weapon_AR2.Single"
ARC9.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
ARC9.Attachments = {
    { id = "optic", name = "Optic", type = "optic" },
    { id = "underbarrel", name = "Underbarrel", type = "underbarrel" }
}
ARC9.AttachmentDefinitions = {
    micro_red_dot = {
        name = "Micro Red Dot",
        type = "optic",
        icon = "ft_base/providers/arc9/ui/att.png",
        visuals = {
            view = {model = "models/weapons/c_pistol.mdl", pos = Vector(2, 0, 1), scale = 0.22},
            world = {model = "models/weapons/w_pistol.mdl", pos = Vector(2, 0, 1), scale = 0.22}
        },
        modifiers = { ["spread.ads"] = { multiply = 0.74 } }
    },
    vertical_grip = {
        name = "Vertical Grip",
        type = "underbarrel",
        visuals = {
            view = {model = "models/props_c17/oildrum001.mdl", scale = 0.04},
            world = {model = "models/props_c17/oildrum001.mdl", scale = 0.04}
        },
        modifiers = { ["recoil.scalar"] = { multiply = 0.86 } }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
