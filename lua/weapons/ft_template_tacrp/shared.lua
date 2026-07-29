if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - TacRP Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "TacRP"

FT.Visual.Default = "TacRP"

TacRP.PrintName = "F&T Template - TacRP Dialect"
TacRP.Category = "F&T Base Templates"
TacRP.ViewModel = "models/weapons/c_irifle.mdl"
TacRP.WorldModel = "models/weapons/w_irifle.mdl"
TacRP.ViewModelFOV = 61
TacRP.DefaultBodygroups = {[0] = 0}
TacRP.DefaultWMBodygroups = {[0] = 0}
TacRP.DefaultSkin = 0
TacRP.DefaultWMSkin = 0
TacRP.Elements = {
    template_receiver = {skin = 0, bodygroups = {[0] = 0}}
}
TacRP.Damage_Max = 31
TacRP.Damage_Min = 20
TacRP.Range_Max = 2250
TacRP.RPM = 690
TacRP.Automatic = true
TacRP.ClipSize = 30
TacRP.DefaultClip = 120
TacRP.Ammo = "AR2"
TacRP.Spread = 0.013
TacRP.Spread_Sights = 0.0055
TacRP.Spread_Move = 0.009
TacRP.RecoilKick = 0.88
TacRP.RecoilSpreadPenalty = 0.001
TacRP.RecoilStability = 0.95
TacRP.FreeAimAngle = 0.3
TacRP.Sway = 0.08
TacRP.BlindFire = false
TacRP.Scope = {
    type = "compact",
    magnification = 1.3,
    reticle = "ft_base/providers/tacrp/hud/news.png",
    hideWeapon = false
}
TacRP.InspectPos = Vector(-2.4, 0, -0.4)
TacRP.InspectAng = Angle(4, 24, 0)
TacRP.CustomizePos = Vector(-3.6, 0, -0.9)
TacRP.CustomizeAng = Angle(7, 34, 0)
TacRP.DrawCrosshair = true
TacRP.DrawAmmo = true
TacRP.Sound_Shoot = "Weapon_AR2.Single"
TacRP.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
TacRP.InspectAnimation = ACT_VM_DRAW
TacRP.CustomizeAnimation = ACT_VM_DRAW
TacRP.Attachments = {
    { id = "optic", name = "Optic", type = "optic", default = "compact_optic" },
    { id = "muzzle", name = "Muzzle", type = "muzzle", default = "flash_hider" }
}
TacRP.AttachmentDefinitions = {
    compact_optic = {
        name = "Compact Optic",
        description = "A lightweight optic using TacRP inspect and HUD presentation.",
        type = "optic",
        icon = "ft_base/providers/tacrp/hud/news.png",
        visuals = {
            view = {
                model = "models/weapons/c_pistol.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(4.1, -1.4, 0.8),
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
        modifiers = { ["spread.ads"] = { multiply = 0.75 } }
    },
    flash_hider = {
        name = "Flash Hider",
        description = "Reduces visual kick while retaining the rifle's handling.",
        type = "muzzle",
        visuals = {
            view = {
                model = "models/props_c17/TrapPropeller_Engine.mdl",
                attachment = "muzzle",
                ang = Angle(0, 0, 90),
                scale = 0.04,
                material = "models/shiny"
            },
            world = {
                model = "models/props_c17/TrapPropeller_Engine.mdl",
                attachment = "muzzle",
                ang = Angle(0, 0, 90),
                scale = 0.04,
                elements = {skin = 0, bodygroups = {[0] = 0}},
                color = {r = 184, g = 192, b = 202, a = 255}
            }
        },
        modifiers = { ["camera.shake"] = { multiply = 0.84 } }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
