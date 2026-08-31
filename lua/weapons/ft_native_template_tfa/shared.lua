if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Native UI Template - TFA AR-15"
SWEP.Category = "F&T Native UI Templates / TFA"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.AdminSpawnable = true

SWEP.FTUIBridge = {
    provider = "tfa",
    dialect = "TFA",
    clientOnly = true,
    uiOnly = true,
    sampleClass = "tfa_ins2_cw_ar15",
    baseClass = "tfa_gun_base",
    domains = {
        inspect = "tfa",
        attachments = "tfa",
        hud = "tfa",
        presentation = "tfa"
    },
    inspect = "tfa",
    attachments = "tfa",
    hud = "tfa",
    presentation = "tfa"
}

SWEP.FTSource = [[
using "TFA"

FT.Visual.Default = "TFA"

TFA.PrintName = "AR-15"
TFA.Category = "TFA Insurgency"
TFA.Spawnable = true
TFA.UseHands = true
TFA.ViewModel = "models/weapons/tfa_ins2/c_cw_ar15.mdl"
TFA.WorldModel = "models/weapons/tfa_ins2/w_cw_ar15.mdl"
TFA.ViewModelFOV = 70
TFA.HoldType = "ar2"

TFA.Primary.Damage = 33
TFA.Primary.NumShots = 1
TFA.Primary.Cone = 0.02
TFA.Primary.IronAccuracy = 0.005
TFA.Primary.RPM = 700
TFA.Primary.Automatic = false
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 120
TFA.Primary.Ammo = "ar2"
TFA.Primary.Sound = "TFA_INS2.CW_AR15.1"

TFA.Secondary.IronFOV = 80
TFA.IronSightsPos = Vector(-2.74, -1.293, 0.65)
TFA.IronSightsAng = Angle(1, 0.05, 0)
TFA.InspectPos = Vector(5, -5.619, -2.787)
TFA.InspectAng = Angle(22.386, 34.417, 5)
TFA.CustomizePos = Vector(4.5, -4.8, -2.2)
TFA.CustomizeAng = Angle(18, 30, 4)
TFA.InspectAnimation = {sequence = "inspect"}
TFA.CustomizeAnimation = {sequence = "draw"}

TFA.Primary.KickUp = 0.4
TFA.Primary.KickHorizontal = 0.2
TFA.Primary.SpreadMultiplierMax = 3
TFA.Primary.SpreadIncrement = 0.5
TFA.Primary.SpreadRecovery = 3
TFA.MoveSpeed = 0.875
TFA.IronSightsMoveSpeed = 0.7

TFA.AttachmentElements = {
    sights_folded = {model = "models/weapons/tfa_ins2/upgrades/f_ar15_carryhandle.mdl"},
    suppressor = {model = "models/weapons/tfa_ins2/upgrades/a_suppressor_ar15.mdl"},
    basebarrel = {model = "models/weapons/tfa_ins2/upgrades/f_ar15_m4barrel.mdl"},
    mag = {model = "models/weapons/tfa_ins2/upgrades/f_ar15_30rndmag.mdl"}
}

TFA.VElements = {
    basebarrel = {
        type = "Model",
        model = "models/weapons/tfa_ins2/upgrades/f_ar15_m4barrel.mdl",
        bone = "Weapon",
        pos = Vector(0, 0, 0.25),
        angle = Angle(0, 0, 0),
        size = Vector(1, 1, 1),
        active = true,
        bonemerge = false
    },
    suppressor = {
        type = "Model",
        model = "models/weapons/tfa_ins2/upgrades/a_suppressor_ar15.mdl",
        bone = "A_Suppressor",
        pos = Vector(0, 0, 0),
        angle = Angle(0, 0, 0),
        size = Vector(0.5, 0.5, 0.5),
        active = false,
        bonemerge = true
    }
}

TFA.WElements = {
    mag = {
        type = "Model",
        model = "models/weapons/tfa_ins2/upgrades/w_ar15_30mag.mdl",
        bone = "ATTACH_Standard",
        pos = Vector(0, 0, 0),
        angle = Angle(0, 0, 0),
        size = Vector(1, 1, 1),
        active = true,
        bonemerge = true
    },
    suppressor = {
        type = "Model",
        model = "models/weapons/tfa_ins2/upgrades/w_ar15_carry.mdl",
        bone = "ATTACH_Muzzle",
        pos = Vector(0, 0, 0),
        angle = Angle(0, 0, 0),
        size = Vector(1, 1, 1),
        active = false,
        bonemerge = true
    }
}

TFA.Attachments = {
    {id = "muzzle", name = "Muzzle", type = "muzzle", default = "ins2_br_supp"},
    {id = "ammo", name = "Ammo", type = "ammo", default = "am_match"},
    {id = "optic", name = "Optic", type = "optic", default = "ar15_si_folded"},
    {id = "foregrip", name = "Foregrip", type = "foregrip", default = "ins2_fg_grip"},
    {id = "stock", name = "Stock", type = "stock", default = "ar15_magpul_stock"},
    {id = "laser", name = "Laser", type = "tactical", default = "ins2_ub_laser"},
    {id = "magazine", name = "Magazine", type = "magazine", default = "ar15_ext_mag_60"},
    {id = "barrel", name = "Barrel", type = "barrel", default = "ar15_magpul_barrel"}
}

TFA.AttachmentDefinitions = {
    ins2_br_supp = {
        name = "Suppressor",
        type = "muzzle",
        icon = "vgui/hud/tfa_ins2_cw_ar15",
        visuals = {
            view = {model = "models/weapons/tfa_ins2/upgrades/a_suppressor_ar15.mdl", bone = "A_Suppressor", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0), skin = 0},
            world = {model = "models/weapons/tfa_ins2/upgrades/w_ar15_carry.mdl", bone = "ATTACH_Muzzle", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
        }
    },
    ar15_si_folded = {
        name = "Folding Sights",
        type = "optic",
        icon = "vgui/hud/tfa_ins2_cw_ar15",
        elements = {sights_folded = true},
        visuals = {
            view = {model = "models/weapons/tfa_ins2/upgrades/f_ar15_carryhandle.mdl", bone = "A_Optic", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
            world = {model = "models/weapons/tfa_ins2/upgrades/w_ar15_carry.mdl", bone = "ATTACH_Standard", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
        }
    },
    ins2_fg_grip = {
        name = "Foregrip",
        type = "foregrip",
        icon = "vgui/hud/tfa_ins2_cw_ar15"
    },
    ar15_magpul_stock = {
        name = "Magpul Stock",
        type = "stock",
        icon = "vgui/hud/tfa_ins2_cw_ar15",
         visuals = {view = {model = "models/weapons/tfa_ins2/upgrades/f_ar15_m4moestock.mdl", bone = "Weapon", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}}
    },
    ins2_ub_laser = {
        name = "Laser",
        type = "tactical",
        icon = "vgui/hud/tfa_ins2_cw_ar15"
    },
    ar15_ext_mag_60 = {
        name = "60 Round Magazine",
        type = "magazine",
        icon = "vgui/hud/tfa_ins2_cw_ar15",
        visuals = {
            view = {model = "models/weapons/tfa_ins2/upgrades/f_ar15_60rndmag.mdl", bone = "Magazine", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
            world = {model = "models/weapons/tfa_ins2/upgrades/w_ar15_60mag.mdl", bone = "ATTACH_Standard", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
        }
    },
    ar15_magpul_barrel = {
        name = "Magpul Barrel",
        type = "barrel",
        icon = "vgui/hud/tfa_ins2_cw_ar15",
        visuals = {
            view = {model = "models/weapons/tfa_ins2/upgrades/f_ar15_m4moe.mdl", bone = "Weapon", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)},
            world = {model = "models/weapons/tfa_ins2/upgrades/w_ar15_carry.mdl", bone = "ATTACH_Standard", pos = Vector(0, 0, 0), ang = Angle(0, 0, 0)}
        }
    }
}

TFA.AttachmentDependencies = {
    ins2_ub_laser = {"ar15_ris_barrel"},
    ins2_fg_m203 = {"ar15_ris_barrel"}
}

TFA.AttachmentExclusions = {
    ins2_ub_laser = {"ar15_magpul_barrel", "ar15_m16_barrel"},
    ins2_fg_m203 = {"ar15_magpul_barrel", "ar15_m16_barrel"}
}
]]

local nativeDependency = {
    id = "tfa",
    dialect = "TFA",
    templateClass = "ft_native_template_tfa",
    sampleClass = "tfa_ins2_cw_ar15",
    baseClass = "tfa_gun_base",
    required = true,
    requiredOnServer = false,
    clientOnly = true,
    uiOnly = true,
    scope = "client_ui",
    gameplayOwner = "ft",
    statsOwner = "ft",
    networkingOwner = "ft",
    requiredClasses = {"tfa_gun_base", "tfa_ins2_cw_ar15"},
    clientRequiredClasses = {"tfa_gun_base", "tfa_ins2_cw_ar15"},
    serverRequiredClasses = {},
    externalProvides = {"hud", "inspect", "customization", "attachments", "presentation"},
    workshop = {
        {id = "2840031720", role = "base"},
        {id = "1676032134", role = "sample"}
    },
    capabilities = {
        hud = true,
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
