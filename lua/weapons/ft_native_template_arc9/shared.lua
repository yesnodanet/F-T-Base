if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Native UI Template - ARC9 AK-47"
SWEP.Category = "F&T Native UI Templates / ARC9"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTUIBridge = {
    dialect = "ARC9",
    provider = "arc9",
    clientOnly = true,
    uiOnly = true,
    sampleClass = "arc9_go_ak47",
    baseClass = "arc9_base",
    domains = {
        hud = "arc9",
        inspect = "arc9",
        attachments = "arc9",
        presentation = "arc9"
    },
    default = "arc9",
    hud = "arc9",
    inspect = "arc9",
    attachments = "arc9",
    presentation = "arc9"
}

SWEP.FTSource = [[
using "ARC9"

FT.Visual.Default = "ARC9"

ARC9.PrintName = "AK-47"
ARC9.Category = "ARC9 - GS:R"
ARC9.ViewModel = "models/weapons/csgo/c_rif_ak47.mdl"
ARC9.WorldModel = "models/weapons/csgo/c_rif_ak47.mdl"
ARC9.WorldModelMirror = "models/weapons/csgo/c_rif_ak47.mdl"
ARC9.DefaultBodygroups = "000000"
ARC9.ViewModelFOVBase = 56

ARC9.DamageMax = 36
ARC9.DamageMin = 20
ARC9.RangeMin = 1000
ARC9.RangeMax = 4000
ARC9.Penetration = 25
ARC9.PhysBulletMuzzleVelocity = 28932
ARC9.RPM = 600
ARC9.Automatic = true
ARC9.Firemodes = {
    {Mode = 2},
    {Mode = 1},
    {Mode = 0}
}
ARC9.ClipSize = 30
ARC9.DefaultClip = 120
ARC9.Ammo = "ar2"

ARC9.Spread = 0
ARC9.SpreadAddRecoil = 0.06
ARC9.SpreadAddMove = 0.05
ARC9.SpreadSights = 0
ARC9.RecoilUp = 0.65
ARC9.RecoilSide = 0.6
ARC9.RecoilRandomUp = 0.3
ARC9.RecoilRandomSide = 0.45
ARC9.VisualRecoilUp = 2
ARC9.VisualRecoilSide = -0.05
ARC9.Sway = 0.2
ARC9.FreeAimRadius = 0.35
ARC9.Scope = {
    magnification = 1.1,
    viewModelFOV = 56
}
ARC9.CustomizePos = Vector(19, 45, 4)
ARC9.CustomizeAng = Angle(90, 0, 0)
ARC9.InspectPos = Vector(18, 42, 3)
ARC9.InspectAng = Angle(84, 4, 0)
ARC9.InspectAnimation = {sequence = "inspect"}
ARC9.CustomizeAnimation = {sequence = "draw"}
ARC9.CustomizeSnapshotPos = Vector(0, 30, 0)
ARC9.CustomizeSnapshotFOV = 60
ARC9.DrawCrosshair = true
ARC9.DrawAmmo = true
ARC9.ShootSound = "CSGO.AK47.Fire"
ARC9.DistantShootSound = "CSGO.AK47.Distance_Fire"
ARC9.MuzzleParticle = "weapon_muzzle_flash_assaultrifle"
ARC9.ShellModel = "models/models/weapons/shared/shell_762_hr.mdl"

ARC9.Animations = {
    fire = {Source = "shoot1"},
    fire_sights = {Source = "shoot1_ads"},
    reload = {Source = "reload"},
    deploy = {Source = "draw"}
}

ARC9.AttachmentElements = {
    csgo_ak47_stock_rpk = {Bodygroups = {{1, 1}}},
    stock_none = {Bodygroups = {{1, 3}}},
    csgo_ak47_stock_skeleton = {Bodygroups = {{1, 2}}},
    topcover = {Bodygroups = {{2, 1}}},
    csgo_ak47_barrel_long = {Bodygroups = {{3, 2}}},
    csgo_ak47_barrel_short = {Bodygroups = {{3, 3}}},
    csgo_ak47_barrel_tactical = {Bodygroups = {{3, 4}}},
    csgo_ak47_mag_50 = {Bodygroups = {{4, 1}}},
    csgo_ak47_mag_556 = {Bodygroups = {{4, 2}}},
    csgo_ak47_mag_556_ext = {Bodygroups = {{4, 3}}},
    csgo_ak47_mag_545 = {Bodygroups = {{4, 4}}},
    csgo_ak47_mag_545_ext = {Bodygroups = {{4, 5}}},
    mag_none = {Bodygroups = {{4, 6}}},
    csgo_ak47_grip_tactical = {Bodygroups = {{5, 1}}},
    csgo_rail_optic_2_alt = {AttPosMods = {[4] = {Pos = Vector(0.075, -4, 4.3)}}}
}

ARC9.Attachments = {
    {id = "barrel", name = "Barrel", type = "go_ak47_barrel", default = "csgo_ak47_barrel_long"},
    {id = "muzzle", name = "Muzzle", type = "muzzle"},
    {id = "optics", name = "Optics", type = "csgo_optic"},
    {id = "top", name = "Top Rail", type = "csgo_rail_optic_ak"},
    {id = "side", name = "Side Rail", type = "csgo_rail_tac"},
    {id = "underbarrel", name = "Underbarrel", type = "grip"},
    {id = "stock", name = "Stock", type = "go_ak47_stock"},
    {id = "mag", name = "Magazine", type = "go_mag_ak", default = "csgo_ak47_mag_50"},
    {id = "pistolgrip", name = "Pistol Grip", type = "go_ak47_grip"},
    {id = "ammo", name = "Ammo", type = "go_ammo"},
    {id = "perk", name = "Perk", type = "go_perk"},
    {id = "skins", name = "Skins", type = "go_skins_ak47"},
    {id = "camo", name = "Camo", type = "universal_camo"},
    {id = "charm", name = "Charm", type = "charm"}
}

ARC9.AttachmentDefinitions = {
    csgo_ak47_barrel_long = {
        name = "Long Barrel",
        type = "barrel",
        elements = {csgo_ak47_barrel_long = true}
    },
    csgo_ak47_barrel_short = {
        name = "Short Barrel",
        type = "barrel",
        elements = {csgo_ak47_barrel_short = true}
    },
    csgo_ak47_mag_50 = {
        name = "50 Round Magazine",
        type = "magazine",
        elements = {csgo_ak47_mag_50 = true},
        visuals = {
            view = {
                model = "models/weapons/csgo/mags/w_rif_ak47_mag.mdl",
                bone = "v_weapon.AK47_clip",
                pos = Vector(0, 0, 0),
                ang = Angle(0, 0, 0),
                skin = 0
            },
            world = {
                model = "models/weapons/csgo/mags/w_rif_ak47_mag.mdl",
                attachment = "muzzle",
                pos = Vector(0, 0, 0),
                ang = Angle(0, 0, 0)
            }
        }
    }
}
]]


local nativeDependency = {
    id = "arc9",
    dialect = "ARC9",
    templateClass = "ft_native_template_arc9",
    sampleClass = "arc9_go_ak47",
    baseClass = "arc9_base",
    required = true,
    clientOnly = true,
    uiOnly = true,
    scope = "client_ui",
    gameplayOwner = "ft",
    statsOwner = "ft",
    networkingOwner = "ft",
    externalProvides = {"hud", "inspect", "customization", "attachments", "presentation"},
    requiredOnServer = false,
    requiredClasses = {"arc9_base", "arc9_go_base", "arc9_go_ak47"},
    clientRequiredClasses = {"arc9_base", "arc9_go_base", "arc9_go_ak47"},
    serverRequiredClasses = {},
    workshop = {
        {id = "2910505837", role = "base"},
        {id = "2910537020", role = "sample"}
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
