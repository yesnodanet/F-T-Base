if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - TFA Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "TFA"

FT.Visual.Default = "TFA"

TFA.PrintName = "F&T Template - TFA Dialect"
TFA.Category = "F&T Base Templates"
TFA.ViewModel = "models/weapons/c_irifle.mdl"
TFA.WorldModel = "models/weapons/w_irifle.mdl"
TFA.HoldType = "ar2"
TFA.UseHands = true
TFA.ViewModelFOV = 60
TFA.Bodygroups_V = {[0] = 0}
TFA.Bodygroups_W = {[0] = 0}
TFA.DrawAmmo = true

TFA.Primary.Damage = 31
TFA.Primary.NumShots = 1
TFA.Primary.Cone = 0.014
TFA.Primary.IronAccuracy = 0.006
TFA.Primary.RPM = 680
TFA.Primary.Automatic = true
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 120
TFA.Primary.Ammo = "AR2"
TFA.Primary.Sound = "Weapon_AR2.Single"

TFA.Secondary.IronFOV = 60
TFA.Secondary.Scope = {
    type = "reflex",
    magnification = 1.15,
    reticle = "ft_base/providers/tfa/inspectionhud/qmark",
    hideWeapon = false
}
TFA.IronSightsPos = Vector(-5.2, -4.8, 2)
TFA.IronSightsAng = Angle(0, 0, 0)
TFA.InspectPos = Vector(-2.4, 0, -0.4)
TFA.InspectAng = Angle(3, 24, 0)
TFA.CustomizePos = Vector(-3.4, 0, -0.8)
TFA.CustomizeAng = Angle(6, 32, 0)

TFA.KickUp = 0.86
TFA.KickHorizontal = 0.22
TFA.RecoilInstructions = {
    {0.02, 0.82},
    {-0.12, 0.96},
    {0.18, 1.08},
    {-0.16, 1.16}
}

TFA.ReloadSound = "Weapon_AR2.Reload"
TFA.ReloadDuration = 2.15
TFA.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
TFA.InspectAnimation = ACT_VM_DRAW
TFA.CustomizeAnimation = ACT_VM_DRAW

TFA.Attachments = {
    { id = "optic", name = "Optic", type = "optic", default = "reflex" },
    { id = "muzzle", name = "Muzzle", type = "muzzle", default = "compensator" }
}

TFA.AttachmentDefinitions = {
    reflex = {
        name = "Reflex Sight",
        description = "Tighter aiming spread with a slightly narrower view.",
        type = "optic",
        icon = "ft_base/providers/tfa/inspectionhud/qmark",
        visuals = {
            view = {
                model = "models/weapons/c_pistol.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(4, -1.5, 0.7),
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
            ["spread.ads"] = { multiply = 0.78 },
            ["ads.fov"] = { add = -4 }
        }
    },
    compensator = {
        name = "Compensator",
        description = "Reduces vertical recoil at the cost of hip-fire spread.",
        type = "muzzle",
        visuals = {
            view = {
                model = "models/props_c17/TrapPropeller_Engine.mdl",
                attachment = "muzzle",
                ang = Angle(0, 0, 90),
                scale = 0.04,
                elements = {skin = 0, bodygroups = {[0] = 0}}
            },
            world = {
                model = "models/props_c17/TrapPropeller_Engine.mdl",
                attachment = "muzzle",
                ang = Angle(0, 0, 90),
                scale = 0.04,
                color = {r = 190, g = 196, b = 204, a = 255}
            }
        },
        modifiers = {
            ["recoil.scalar"] = { multiply = 0.8 },
            ["spread.hip"] = { add = 0.002 }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
