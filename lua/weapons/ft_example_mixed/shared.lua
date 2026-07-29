if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Mixed Dialect Rifle"
SWEP.Category = "F&T Base Examples"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "TFA"
using "ARC9"
using "MW"
using "TacRP"

FT.Priority = {
    "ARC9",
    "MW",
    "TFA"
}
FT.Customization.Provider = "mixed"
FT.Visual.Default = "TFA"
FT.Visual.Inspect = "TFA"
FT.Visual.Attachments = "MW"
FT.Visual.HUD = "TFA"
FT.Visual.Presentation = "TFA"

TFA.PrintName = "F&T Mixed Dialect Rifle"
TFA.Category = "F&T Base Examples"
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
TFA.Primary.Damage = 35
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 90
TFA.Primary.Ammo = "SMG1"
TFA.Primary.Sound = "Weapon_AR2.Single"
TFA.Primary.RPM = 650
TFA.Primary.Automatic = true
TFA.Primary.Cone = 0.012
TFA.Primary.IronAccuracy = 0.005
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

ARC9.Recoil.Up = 0.8
ARC9.Recoil.Side = 0.24
ARC9.Spread = 0.012

MW.Camera.Shake = 0.35
MW.Camera.Sway = 0.15

TacRP.BlindFire = true

FT.Meta.Category = "F&T Base Examples"
FT.Rendering.HoldType = "ar2"
FT.Ballistics.Mode = "hitscan"
FT.Ballistics.Penetration = {
    power = 8,
    materials = {
        wood = 1,
        metal = 0.35
    }
}

FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1},
    {0.2, 2.7},
    {-0.3, 3.0}
}

FT.Animations.Base = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}

MW.Attachments = {
    slots = {
        {
            id = "optic",
            type = "optic",
            name = "Optic",
            default = "reflex"
        },
        {
            id = "muzzle",
            type = "muzzle",
            name = "Muzzle",
            default = "compensator"
        }
    },
    definitions = {
        reflex = {
            name = "Operator Reflex",
            description = "Clear sight picture with faster target acquisition.",
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
                    elements = {skin = 0, bodygroups = {[0] = 0}}
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
                ["spread.ads"] = {multiply = 0.72},
                ["ads.fov"] = {add = -4},
                ["ads.speed"] = {multiply = 1.08}
            }
        },
        combat_scope = {
            name = "Combat Scope",
            description = "Narrower field of view and improved precision at range.",
            type = "optic",
            icon = "ft_base/providers/mw/mw_logo.png",
            visuals = {
                view = {
                    model = "models/items/battery.mdl",
                    bone = "ValveBiped.Bip01_R_Hand",
                    pos = Vector(5.8, -1.6, 2.7),
                    ang = Angle(0, 90, 0),
                    scale = 0.35,
                    material = "models/shiny",
                    color = {r = 150, g = 170, b = 180, a = 255}
                },
                world = {
                    model = "models/items/battery.mdl",
                    attachment = "muzzle",
                    pos = Vector(-8, 0, 2),
                    ang = Angle(0, 90, 0),
                    scale = 0.35,
                    material = "models/shiny"
                }
            },
            modifiers = {
                ["spread.ads"] = {multiply = 0.58},
                ["ads.fov"] = {add = -12},
                ["ads.speed"] = {multiply = 0.82}
            }
        },
        compensator = {
            name = "Tactical Compensator",
            description = "Controls climb while slightly increasing hip spread.",
            type = "muzzle",
            icon = "ft_base/providers/mw/mw_logo.png",
            visuals = {
                view = {
                    model = "models/props_c17/TrapPropeller_Engine.mdl",
                    attachment = "muzzle",
                    pos = Vector(2.5, 0, 0),
                    ang = Angle(0, 90, 0),
                    scale = 0.035,
                    skin = 0,
                    bodygroups = {[0] = 0}
                },
                world = {
                    model = "models/props_c17/TrapPropeller_Engine.mdl",
                    attachment = "muzzle",
                    pos = Vector(2, 0, 0),
                    ang = Angle(0, 90, 0),
                    scale = 0.035,
                    skin = 0
                }
            },
            modifiers = {
                ["recoil.scalar"] = {multiply = 0.82},
                ["camera.shake"] = {multiply = 0.78},
                ["spread.hip"] = {add = 0.0015}
            }
        },
        suppressor = {
            name = "Lightweight Suppressor",
            description = "Suppresses the firing report at a small damage cost.",
            type = "muzzle",
            icon = "ft_base/providers/mw/mw_logo.png",
            visuals = {
                view = {
                    model = "models/props_junk/PopCan01a.mdl",
                    attachment = "muzzle",
                    pos = Vector(3, 0, 0),
                    ang = Angle(0, 90, 0),
                    scale = 0.2,
                    material = "models/shiny",
                    color = {r = 55, g = 58, b = 62, a = 255}
                },
                world = {
                    model = "models/props_junk/PopCan01a.mdl",
                    attachment = "muzzle",
                    pos = Vector(2.5, 0, 0),
                    ang = Angle(0, 90, 0),
                    scale = 0.2,
                    material = "models/shiny",
                    color = {r = 55, g = 58, b = 62, a = 255}
                }
            },
            modifiers = {
                ["sounds.fire.suppressed"] = {set = "Weapon_AR2.NPC_Single"},
                ["damage.minimum"] = {multiply = 0.92},
                ["camera.shake"] = {multiply = 0.86}
            }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
