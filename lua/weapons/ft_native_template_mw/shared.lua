if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Native UI Template - MW M4A1"
SWEP.Category = "F&T Native UI Templates / Modern Warfare"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTUIBridge = {
    provider = "mw",
    dialect = "MW",
    clientOnly = true,
    uiOnly = true,
    sampleClass = "mg_mike4",
    baseClass = "mg_base",
    domains = {
        inspect = "mw",
        attachments = "mw",
        hud = "mw",
        presentation = "mw"
    },
    inspect = "mw",
    attachments = "mw",
    hud = "mw",
    presentation = "mw"
}

SWEP.FTSource = [[
using "MW"

FT.Visual.Default = "MW"

MW.PrintName = "M4A1"
MW.Category = "Modern Warfare"
MW.SubCategory = "Assault Rifles"
MW.VModel = "models/viper/mw/weapons/v_mike4.mdl"
MW.WorldModel = "models/viper/mw/weapons/w_mike4.mdl"
MW.HoldType = "Rifle"
MW.ViewModelFOV = 60
MW.UseHands = true

MW.Description = "The M4A1 is a fully automatic, all-purpose assault rifle."
MW.Credits = "Model and animations: Modern Warfare 2019 Sweps"
MW.InspectTitle = "M4A1"
MW.InspectType = "ASSAULT RIFLE"
MW.InspectDescription = "A dependable 5.56 rifle with a complete Gunsmith workbench."
MW.InspectCredits = "Modern Warfare 2019 Sweps"
MW.InspectPreview = {
    model = "models/viper/mw/weapons/v_mike4.mdl",
    viewModel = "models/viper/mw/weapons/v_mike4.mdl",
    fov = 60
}
MW.InspectStats = {
    {label = "DAMAGE", path = "damage.base", value = 26},
    {label = "FIRE RATE", path = "fire.rpm", value = 809},
    {label = "RANGE", path = "ballistics.damageCurve.maxRange", value = 180},
    {label = "CONTROL", path = "recoil.procedural.vertical", value = 0.625}
}
MW.InspectFalloff = {
    {range = 0, multiplier = 1},
    {range = 20, multiplier = 1},
    {range = 43, multiplier = 0.5},
    {range = 180, multiplier = 0}
}
MW.InspectHints = {"FIRE SELECT toggles the fire mode", "USE opens Gunsmith"}
MW.InspectBlur = true
MW.HideHUD = true
MW.Customization.Title = "GUNSMITH"
MW.Customization.Presets = {"DEFAULT", "ASSAULT RIFLE"}
MW.Customization.Controls = {"MOUSE: SELECT", "LEFT CLICK: INSTALL", "RIGHT CLICK: REMOVE", "R: RESET"}
MW.Customization.Stats = {
    {label = "DAMAGE", path = "damage.base"},
    {label = "ACCURACY", path = "spread.ads"},
    {label = "RANGE", path = "ballistics.damageCurve.maxRange"},
    {label = "CONTROL", path = "recoil.procedural.vertical"}
}
MW.Customization.Hints = {"Inspect each attachment to preview its stat changes"}
MW.Customization.Preview = {
    model = "models/viper/mw/weapons/v_mike4.mdl",
    fov = 60,
    camera = "gunsmith"
}
MW.Customization.Animations = {
    open = {sequence = "draw"},
    inspect = {sequence = "inspect", duration = 5},
    install = {sequence = "ads_in"},
    remove = {sequence = "ads_out"}
}

MW.Damage = 26
MW.DamageMin = 13
MW.Range = 180
MW.Penetration = 3
MW.RPM = 809
MW.Automatic = true
MW.ClipSize = 30
MW.DefaultClip = 120
MW.Ammo = "Ar2"
MW.Spread = 0.45
MW.ADSSpread = 0
MW.MoveSpread = 0.2

MW.Recoil.Vertical = 0.625
MW.Recoil.Horizontal = 0.8
MW.Recoil.Roll = 0
MW.Camera.Shake = 1.1
MW.Camera.Sway = 0.1
MW.Zoom = {
    IdleSway = 0.1,
    FovMultiplier = 0.95,
    ViewModelFovMultiplier = 1,
    Blur = {EyeFocusDistance = 6.5}
}
MW.InspectPos = Vector(0, 3, 3)
MW.InspectAng = Angle(40, 0, -30)
MW.CustomizePos = Vector(19, 45, 4)
MW.CustomizeAng = Angle(90, 0, 0)
MW.InspectAnimation = {sequence = "inspect", duration = 5}
MW.CustomizeAnimation = {sequence = "draw"}
MW.Aim.Pos = Vector(0, 0, 0)
MW.Aim.Ang = Angle(0, 0, 0)

FT.Recoil.Procedural = {
    vertical = 0.625,
    horizontal = 0.8,
    recovery = 1
}
FT.Rendering.ModelOffsets = {
    world = {
        bone = "tag_sling",
        ang = Angle(0, 95, -90),
        pos = Vector(3, -5, -3.5)
    }
}

MW.Sound.Fire = "mw19.mike4.fire"
MW.Effects.Muzzle = "mwb_muzzle_ar_1"
MW.Animations = {
    fire = {sequence = "fire"},
    reload = {sequence = "reload"},
    reload_empty = {sequence = "reload_empty"},
    deploy = {sequence = "draw"},
    inspect = {sequence = "inspect"},
    ads_in = {sequence = "ads_in"},
    ads_out = {sequence = "ads_out"}
}

MW.Attachments = {
    slots = {
        {id = "perk", name = "Perk", type = "perk"},
        {id = "barrel", name = "Barrel", type = "barrel", default = "attachment_vm_ar_mike4_barrel"},
        {id = "stock", name = "Stock", type = "stock", default = "attachment_vm_ar_mike4_stock"},
        {id = "magazine", name = "Magazine", type = "magazine", default = "attachment_vm_ar_mike4_mag"},
        {id = "receiver", name = "Receiver", type = "receiver", default = "attachment_vm_ar_mike4_receiver"},
        {id = "muzzle", name = "Muzzle", type = "muzzle", default = "attachment_vm_ar_mike4_barsil"},
        {id = "sight", name = "Sight", type = "optic", default = "attachment_vm_ar_mike4_carryhandle"},
        {id = "laser", name = "Laser", type = "laser"},
        {id = "grip", name = "Grip", type = "grip"}
    },
    definitions = {
        attachment_vm_ar_mike4_barrel = {
            name = "M4A1 Barrel",
            description = "The standard M4A1 barrel used by the source weapon.",
            folder = "Barrel",
            pros = {"Balanced range"},
            cons = {},
            stats = {length = 1, damage = 26},
            type = "barrel",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_barrel.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0),
                    skin = 0
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_barrel.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["ballistics.damageCurve.maxRange"] = {set = 180}
            }
        },
        attachment_vm_ar_mike4_shortbarrel = {
            name = "M4A1 Short Barrel",
            description = "A compact barrel for faster handling.",
            folder = "Barrel",
            pros = {"Handling"},
            cons = {"Range"},
            stats = {range = -20, ads = 0.05},
            type = "barrel",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_shortbarrel.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0),
                    skin = 0
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_shortbarrel.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0),
                    skin = 0
                }
            },
            modifiers = {
                ["ballistics.damageCurve.maxRange"] = {add = -20},
                ["ads.speed"] = {multiply = 1.05}
            }
        },
        attachment_vm_ar_mike4_custombarrel = {
            name = "Custom Barrel",
            description = "A tuned M4A1 barrel profile.",
            folder = "Barrel",
            type = "barrel",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_custombarrel.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_custombarrel.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            }
        },
        attachment_vm_ar_mike4_carryhandle = {
            name = "M4A1 Carry Handle",
            description = "The original iron sight carry handle.",
            folder = "Optic",
            trivia = "The carry handle is the default M4A1 sight picture.",
            type = "optic",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_carryhandle.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_carryhandle.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["ads.fov"] = {set = 70}
            }
        },
        attachment_vm_ar_mike4_stock = {
            name = "M4A1 Stock",
            description = "Standard adjustable stock.",
            folder = "Stock",
            pros = {"Control"},
            type = "stock",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_stock.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_stock.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["recoil.procedural.vertical"] = {multiply = 0.98}
            }
        },
        attachment_vm_ar_mike4_stockno = {
            name = "No Stock",
            description = "Removes the shoulder stock.",
            folder = "Stock",
            cons = {"Control"},
            type = "stock",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_stockno.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_stockno.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["recoil.procedural.vertical"] = {multiply = 1.12},
                ["ads.speed"] = {multiply = 1.1}
            }
        },
        attachment_vm_ar_mike4_mag = {
            name = "M4A1 Magazine",
            description = "Standard 30-round 5.56 magazine.",
            folder = "Magazine",
            stats = {capacity = 30},
            type = "magazine",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_mag.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_mag.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            }
        },
        attachment_vm_ar_mike4_calsmg = {
            name = "9mm Conversion Magazine",
            description = "A compact magazine for the 9mm conversion.",
            folder = "Magazine",
            pros = {"Handling"},
            cons = {"Damage"},
            type = "magazine",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_calsmg.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_calsmg.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["ammo.type"] = {set = "SMG1"},
                ["damage.base"] = {add = -3}
            }
        },
        attachment_vm_ar_mike4_barsil = {
            name = "M4A1 Suppressed Barrel",
            description = "An integral suppressor barrel from the source Gunsmith list.",
            folder = "Muzzle",
            pros = {"Sound suppression"},
            cons = {"Damage range"},
            type = "muzzle",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_barsil.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_barsil.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["sounds.fire.suppressed"] = {set = "mw19.mike4.fire.s"},
                ["damage.base"] = {add = -2}
            }
        },
        attachment_vm_ar_mike4_xmags = {
            name = "Extended Magazine",
            description = "A larger magazine for sustained fire.",
            folder = "Magazine",
            pros = {"Capacity"},
            cons = {"Reload speed"},
            type = "magazine",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_xmags.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_xmags.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            },
            modifiers = {
                ["ammo.clipSize"] = {add = 15},
                ["movement.reloadSpeed"] = {multiply = 0.9}
            }
        },
        attachment_vm_ar_mike4_receiver = {
            name = "M4A1 Receiver",
            description = "Standard M4A1 receiver assembly.",
            folder = "Receiver",
            type = "receiver",
            icon = "vgui/entities/mg_mike4",
            visuals = {
                view = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_receiver.mdl",
                    bone = "tag_sling",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                },
                world = {
                    model = "models/viper/mw/attachments/mike4/attachment_vm_ar_mike4_receiver.mdl",
                    attachment = "muzzle",
                    pos = Vector(0, 0, 0),
                    ang = Angle(0, 0, 0)
                }
            }
        }
    }
}
]]

local nativeDependency = {
    id = "mw",
    dialect = "MW",
    templateClass = "ft_native_template_mw",
    sampleClass = "mg_mike4",
    baseClass = "mg_base",
    required = true,
    requiredOnServer = false,
    clientOnly = true,
    uiOnly = true,
    scope = "client_ui",
    gameplayOwner = "ft",
    statsOwner = "ft",
    networkingOwner = "ft",
    requiredClasses = {"mg_base", "mg_mike4"},
    clientRequiredClasses = {"mg_base", "mg_mike4"},
    serverRequiredClasses = {},
    externalProvides = {"hud", "inspect", "customization", "attachments", "presentation"},
    workshop = {
        {id = "2459720887", role = "base"},
        {id = "2528829149", role = "sample"}
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
