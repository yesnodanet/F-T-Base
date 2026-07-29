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

FT.Visual.Default = "ArcCW"

ArcCW.PrintName = "F&T Template - ArcCW Dialect"
ArcCW.Category = "F&T Base Templates"
ArcCW.ViewModel = "models/weapons/c_irifle.mdl"
ArcCW.WorldModel = "models/weapons/w_irifle.mdl"
ArcCW.ViewModelFOV = 63
ArcCW.DefaultBodygroups = {[0] = 0}
ArcCW.DefaultWMBodygroups = {[0] = 0}
ArcCW.DefaultSkin = 0
ArcCW.DefaultWMSkin = 0
ArcCW.Elements = {
    template_receiver = {skin = 0, bodygroups = {[0] = 0}}
}
ArcCW.Damage = 30
ArcCW.DamageMin = 19
ArcCW.Range = 2100
ArcCW.RPM = 680
ArcCW.Automatic = true
ArcCW.Firemodes = {"auto", "semi"}
ArcCW.Primary.ClipSize = 30
ArcCW.Primary.DefaultClip = 120
ArcCW.Primary.Ammo = "AR2"
ArcCW.HipDispersion = 0.014
ArcCW.MoveDispersion = 0.009
ArcCW.Recoil = 0.92
ArcCW.RecoilSide = 0.2
ArcCW.VisualRecoilMult = 0.24
ArcCW.Sway = 0.08
ArcCW.FreeAimAngle = 0.3
ArcCW.Scope = {
    type = "prism",
    magnification = 1.35,
    reticle = "ft_base/providers/arccw/hud/default.png",
    hideWeapon = false
}
ArcCW.InspectPos = Vector(-2.3, 0, -0.4)
ArcCW.InspectAng = Angle(4, 23, 0)
ArcCW.CustomizePos = Vector(-3.5, 0, -0.9)
ArcCW.CustomizeAng = Angle(7, 33, 0)
ArcCW.DrawCrosshair = true
ArcCW.DrawAmmo = true
ArcCW.ShootSound = "Weapon_AR2.Single"
ArcCW.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
ArcCW.InspectAnimation = ACT_VM_DRAW
ArcCW.CustomizeAnimation = ACT_VM_DRAW
ArcCW.Attachments = {
    { id = "optic", name = "Optic", type = "optic", default = "prism" },
    { id = "barrel", name = "Barrel", type = "barrel", default = "short_barrel" }
}
ArcCW.AttachmentDefinitions = {
    prism = {
        name = "Prism Sight",
        description = "A compact magnified optic presented through the ArcCW provider.",
        type = "optic",
        icon = "ft_base/providers/arccw/hud/default.png",
        visuals = {
            view = {
                model = "models/weapons/c_pistol.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(4.1, -1.5, 0.9),
                ang = Angle(0, 90, 0),
                scale = 0.18,
                skin = 0,
                materials = {[0] = "models/shiny"}
            },
            world = {
                model = "models/weapons/w_pistol.mdl",
                attachment = "muzzle",
                pos = Vector(-10, 0, 2),
                ang = Angle(0, 180, 0),
                scale = 0.16,
                bodygroups = {[0] = 0}
            }
        },
        modifiers = { ["spread.ads"] = { multiply = 0.76 } }
    },
    short_barrel = {
        name = "Short Barrel",
        description = "Trades range for faster movement and a shorter visual profile.",
        type = "barrel",
        visuals = {
            view = {
                model = "models/props_c17/TrapPropeller_Engine.mdl",
                attachment = "muzzle",
                pos = Vector(-1, 0, 0),
                ang = Angle(0, 0, 90),
                scale = 0.04,
                elements = {skin = 0, material = "models/shiny"}
            },
            world = {
                model = "models/props_c17/TrapPropeller_Engine.mdl",
                attachment = "muzzle",
                pos = Vector(-1, 0, 0),
                ang = Angle(0, 0, 90),
                scale = 0.04,
                color = {r = 176, g = 184, b = 194, a = 255}
            }
        },
        modifiers = { ["movement.speed"] = { multiply = 1.08 } }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
