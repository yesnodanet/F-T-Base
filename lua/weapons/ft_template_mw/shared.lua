if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - MW Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "MW"

FT.Visual.Default = "MW"

MW.PrintName = "F&T Template - MW Dialect"
MW.Category = "F&T Base Templates"
MW.ViewModel = "models/weapons/c_irifle.mdl"
MW.WorldModel = "models/weapons/w_irifle.mdl"
MW.HoldType = "ar2"
MW.UseHands = true
MW.ViewModelFOV = 60
MW.DefaultBodygroups = {[0] = 0}
MW.DefaultSkin = 0
MW.Elements = {
    template_receiver = {skin = 0, bodygroups = {[0] = 0}}
}
MW.ModelOffset = {
    view = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
    world = {pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
}

MW.Damage = 34
MW.DamageMin = 22
MW.Range = 2400
MW.Penetration = 8
MW.RPM = 720
MW.Automatic = true
MW.ClipSize = 30
MW.DefaultClip = 120
MW.Ammo = "AR2"
MW.Spread = 0.012
MW.ADSSpread = 0.005
MW.MoveSpread = 0.01

MW.Recoil.Vertical = 0.9
MW.Recoil.Horizontal = 0.24
MW.Recoil.Roll = 0.05
MW.Recoil.Pattern = {
    {0.04, 0.82},
    {-0.15, 1.02},
    {0.18, 1.16},
    {-0.2, 1.28}
}

MW.Camera.Shake = 0.28
MW.Camera.Sway = 0.08
MW.Camera.Breathing = 0.04
MW.Camera.Landing = 0.12
MW.Camera.Sprint = {
    bob = 0.2,
    pos = Vector(1, 0, -1.2),
    ang = Angle(-2, 8, 0)
}
MW.Aim.FOV = 58
MW.Aim.Speed = 1.3
MW.Aim.Pos = Vector(-5.1, -4.7, 2)
MW.Aim.Ang = Angle(0, 0, 0)
MW.Aim.Scope = {
    type = "red_dot",
    magnification = 1.25,
    reticle = "ft_base/providers/mw/mw_logo.png",
    hideWeapon = false
}
MW.InspectPos = Vector(-2.5, 0, -0.5)
MW.InspectAng = Angle(4, 25, 0)
MW.CustomizePos = Vector(-3.8, 0, -1)
MW.CustomizeAng = Angle(8, 36, 0)
MW.DrawCrosshair = true
MW.DrawAmmo = true

MW.Sound.Fire = "Weapon_AR2.Single"
MW.Sound.Reload = "Weapon_AR2.Reload"
MW.Reload.Duration = 2.05
MW.Effects.Muzzle = "MuzzleEffect"
MW.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
MW.InspectAnimation = ACT_VM_DRAW
MW.CustomizeAnimation = ACT_VM_DRAW

MW.Attachments = {
    slots = {
        { id = "optic", name = "Optic", type = "optic", default = "red_dot" },
        { id = "barrel", name = "Barrel", type = "barrel", default = "long_barrel" }
    },
    definitions = {
        red_dot = {
            name = "Red Dot Sight",
            description = "Tighter aiming spread and a focused sight picture.",
            type = "optic",
            icon = "ft_base/providers/mw/mw_logo.png",
            visuals = {
                view = {
                    model = "models/weapons/c_pistol.mdl",
                    bone = "ValveBiped.Bip01_R_Hand",
                    pos = Vector(4.3, -1.4, 0.8),
                    ang = Angle(0, 90, 0),
                    scale = 0.18,
                    skin = 0,
                    materials = {[0] = "models/shiny"},
                    bodygroups = {[0] = 0}
                },
                world = {
                    model = "models/weapons/w_pistol.mdl",
                    attachment = "muzzle",
                    pos = Vector(-10, 0, 2),
                    ang = Angle(0, 180, 0),
                    scale = 0.16,
                    material = "models/shiny"
                }
            },
            modifiers = {
                ["spread.ads"] = { multiply = 0.76 },
                ["ads.fov"] = { add = -3 }
            }
        },
        long_barrel = {
            name = "Long Barrel",
            description = "Better damage retention and less horizontal recoil.",
            type = "barrel",
            visuals = {
                view = {
                    model = "models/props_c17/TrapPropeller_Engine.mdl",
                    attachment = "muzzle",
                    pos = Vector(0.5, 0, 0),
                    ang = Angle(0, 0, 90),
                    scale = 0.045,
                    elements = {skin = 0, bodygroups = {[0] = 0}}
                },
                world = {
                    model = "models/props_c17/TrapPropeller_Engine.mdl",
                    attachment = "muzzle",
                    pos = Vector(0.5, 0, 0),
                    ang = Angle(0, 0, 90),
                    scale = 0.045,
                    color = {r = 196, g = 202, b = 210, a = 255}
                }
            },
            modifiers = {
                ["damage.minimum"] = { add = 4 },
                ["recoil.scalar"] = { multiply = 0.9 }
            }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
