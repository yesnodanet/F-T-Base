if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Native UI Template - ArcCW AKM"
SWEP.Category = "F&T Native UI Templates / ArcCW"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTUIBridge = {
    dialect = "ArcCW",
    provider = "arccw",
    clientOnly = true,
    uiOnly = true,
    sampleClass = "arccw_go_ak47",
    baseClass = "arccw_base",
    domains = {
        hud = "arccw",
        inspect = "arccw",
        attachments = "arccw",
        presentation = "arccw"
    },
    default = "arccw",
    hud = "arccw",
    inspect = "arccw",
    attachments = "arccw",
    presentation = "arccw"
}

SWEP.FTSource = [[
using "ArcCW"

FT.Visual.Default = "ArcCW"

ArcCW.PrintName = "AKM"
ArcCW.Category = "ArcCW - GSO (ARs)"
ArcCW.UseHands = true
ArcCW.ViewModel = "models/weapons/arccw_go/v_rif_ak47.mdl"
ArcCW.WorldModel = "models/weapons/arccw_go/v_rif_ak47.mdl"
ArcCW.ViewModelFOV = 60
ArcCW.DefaultBodygroups = "000000000000"

ArcCW.Damage = 36
ArcCW.DamageMin = 24
ArcCW.Range = 100
ArcCW.Penetration = 14
ArcCW.ChamberSize = 1
ArcCW.Primary.ClipSize = 30
ArcCW.Primary.Ammo = "ar2"
ArcCW.Recoil = 0.7
ArcCW.RecoilSide = 0.65
ArcCW.Delay = 0.1
ArcCW.Automatic = true
ArcCW.Firemodes = {
    {Mode = 2},
    {Mode = 1},
    {Mode = 0}
}
ArcCW.HipDispersion = 750
ArcCW.MoveDispersion = 200
ArcCW.SightedSpeedMult = 0.75
ArcCW.Sway = 0.1
ArcCW.FreeAimAngle = 0.3
ArcCW.Scope = {
    Pos = Vector(-5.03, -10, 1.1),
    Ang = Angle(0.16, 0.125, -2.412),
    Magnification = 1.1,
    CrosshairInSights = false
}
ArcCW.CustomizePos = Vector(8, 0, 1)
ArcCW.CustomizeAng = Angle(5, 30, 30)
ArcCW.InspectPos = Vector(7, 0, 1.5)
ArcCW.InspectAng = Angle(8, 28, 28)
ArcCW.InspectAnimation = {sequence = "inspect"}
ArcCW.CustomizeAnimation = {sequence = "draw"}
ArcCW.DrawCrosshair = true
ArcCW.DrawAmmo = true
ArcCW.ShootSound = "arccw_go/ak47/ak47_01.wav"
ArcCW.ShootSoundSilenced = "arccw_go/m4a1/m4a1_silencer_01.wav"
ArcCW.DistantShootSound = "arccw_go/ak47/ak47-1-distant.wav"
ArcCW.MuzzleEffect = "muzzleflash_ak47"
ArcCW.ShellModel = "models/shells/shell_556.mdl"

ArcCW.Animations = {
    fire = {sound = "arccw_go/ak47/ak47_01.wav"},
    reload = {sequence = "reload"},
    deploy = {sequence = "draw"}
}

ArcCW.AttachmentElements = {
    sidemount = {VMBodygroups = {{ind = 1, bg = 1}}},
    ubrms = {VMBodygroups = {{ind = 7, bg = 1}}},
    no_fh = {VMBodygroups = {{ind = 6, bg = 0}}},
    go_ak_barrel_short = {
        VMBodygroups = {{ind = 3, bg = 1}, {ind = 6, bg = 1}},
        AttPosMods = {[5] = {vpos = Vector(0, -3.4, 15.5)}},
        Override_IronSightStruct = {
            Pos = Vector(-5.03, -10, 1.25),
            Ang = Angle(-0.9, 0.075, -2.412),
            Magnification = 1.1,
            CrosshairInSights = false
        }
    },
    go_ak_barrel_long = {
        VMBodygroups = {{ind = 3, bg = 2}},
        AttPosMods = {[5] = {vpos = Vector(0, -3.4, 32)}}
    },
    go_ak_barrel_tac = {
        VMBodygroups = {{ind = 3, bg = 3}, {ind = 7, bg = 0}},
        AttPosMods = {[2] = {vpos = Vector(0, -2.25, 13)}}
    },
    go_ak_grip_poly = {VMBodygroups = {{ind = 4, bg = 1}}},
    go_stock_none = {VMBodygroups = {{ind = 5, bg = 1}}},
    go_stock = {
        VMBodygroups = {{ind = 5, bg = 1}},
        VMElements = {
            {
                Model = "models/weapons/arccw_go/atts/stock_buftube.mdl",
                Bone = "v_weapon.ak47_Parent",
                Offset = {vpos = Vector(0, 0, 0), vang = Angle(0, 0, 0), vscale = Vector(1, 1, 1)}
            }
        }
    }
}

ArcCW.Attachments = {
    {id = "barrel", name = "Barrel", type = "barrel", default = "go_ak_barrel_long"},
    {id = "muzzle", name = "Muzzle", type = "muzzle"},
    {id = "optic", name = "Optic", type = {"optic", "optic_medium"}},
    {id = "underbarrel", name = "Underbarrel", type = "grip"},
    {id = "tactical", name = "Tactical", type = "tactical"},
    {id = "magazine", name = "Magazine", type = "mag"},
    {id = "stock", name = "Stock", type = "stock", default = "go_stock"}
}

ArcCW.AttachmentDefinitions = {
    go_ak_barrel_long = {
        name = "Long Barrel",
        type = "barrel",
        elements = {go_ak_barrel_long = true}
    },
    go_ak_barrel_short = {
        name = "Short Barrel",
        type = "barrel",
        elements = {go_ak_barrel_short = true}
    },
    go_stock = {
        name = "Buffer Tube Stock",
        type = "stock",
        elements = {go_stock = true},
        visuals = {
            view = {
                model = "models/weapons/arccw_go/atts/stock_buftube.mdl",
                bone = "v_weapon.ak47_Parent",
                pos = Vector(0, 0, 0),
                ang = Angle(0, 0, 0),
                skin = 0
            },
            world = {
                model = "models/weapons/arccw_go/atts/stock_buftube.mdl",
                attachment = "muzzle",
                pos = Vector(0, 0, 0),
                ang = Angle(0, 0, 0)
            }
        }
    }
}
]]


local nativeDependency = {
    id = "arccw",
    dialect = "ArcCW",
    templateClass = "ft_native_template_arccw",
    sampleClass = "arccw_go_ak47",
    baseClass = "arccw_base",
    required = true,
    clientOnly = true,
    uiOnly = true,
    scope = "client_ui",
    gameplayOwner = "ft",
    statsOwner = "ft",
    networkingOwner = "ft",
    externalProvides = {"hud", "inspect", "customization", "attachments", "presentation"},
    requiredOnServer = false,
    requiredClasses = {"arccw_base", "arccw_go_ak47"},
    clientRequiredClasses = {"arccw_base", "arccw_go_ak47"},
    serverRequiredClasses = {},
    workshop = {
        {id = "2131057232", role = "base"},
        {id = "2257255110", role = "sample"}
    },
    capabilities = {
        hud = true,
        ads = false,
        inspect = true,
        customization = true,
        attachments = true,
        presentation = true
    }
}

SWEP.FTNative = true
SWEP.FTNativeDialect = nativeDependency.dialect
SWEP.FTNativeDependency = nativeDependency

if type(FTBase) == "table"
    and type(FTBase.Compat) == "table"
    and type(FTBase.Compat.RegisterNativeTemplate) == "function" then
    FTBase.Compat.RegisterNativeTemplate(nativeDependency)
end
FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
