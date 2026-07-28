if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - ArcCW Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "ArcCW"

ArcCW.PrintName = "F&T Template - ArcCW Dialect"
ArcCW.Category = "F&T Base Templates"
ArcCW.ViewModel = "models/weapons/c_irifle.mdl"
ArcCW.WorldModel = "models/weapons/w_irifle.mdl"
ArcCW.Damage = 30
ArcCW.DamageMin = 19
ArcCW.Range = 2100
ArcCW.RPM = 680
ArcCW.Automatic = true
ArcCW.Primary.ClipSize = 30
ArcCW.Primary.DefaultClip = 120
ArcCW.Primary.Ammo = "AR2"
ArcCW.Spread = 0.014
ArcCW.Recoil = 0.92
ArcCW.ShootSound = "Weapon_AR2.Single"
ArcCW.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
ArcCW.Attachments = {
    { id = "optic", name = "Optic", type = "optic" },
    { id = "barrel", name = "Barrel", type = "barrel" }
}
ArcCW.AttachmentDefinitions = {
    prism = {
        name = "Prism Sight",
        type = "optic",
        icon = "ft_base/providers/arccw/hud/atts/default.png",
        visuals = {
            view = {model = "models/weapons/c_pistol.mdl", pos = Vector(2, 0, 1), scale = 0.22},
            world = {model = "models/weapons/w_pistol.mdl", pos = Vector(2, 0, 1), scale = 0.22}
        },
        modifiers = { ["spread.ads"] = { multiply = 0.76 } }
    },
    short_barrel = {
        name = "Short Barrel",
        type = "barrel",
        visuals = {
            view = {model = "models/props_c17/TrapPropeller_Engine.mdl", scale = 0.05},
            world = {model = "models/props_c17/TrapPropeller_Engine.mdl", scale = 0.05}
        },
        modifiers = { ["movement.speed"] = { multiply = 1.08 } }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
