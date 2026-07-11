if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - SWB Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "SWB"

SWB.PrintName = "F&T Template - SWB Dialect"
SWB.Category = "F&T Base Templates"
SWB.ViewModel = "models/weapons/c_smg1.mdl"
SWB.WorldModel = "models/weapons/w_smg1.mdl"
SWB.HoldType = "smg"

SWB.Damage = 26
SWB.NumShots = 1
SWB.FireDelay = 0.075
SWB.Automatic = true
SWB.ClipSize = 36
SWB.DefaultClip = 144
SWB.Ammo = "SMG1"
SWB.HipSpread = 0.019
SWB.AimSpread = 0.008
SWB.SpreadPerShot = 0.001
SWB.MaxSpreadInc = 0.012
SWB.FireSound = "Weapon_SMG1.Single"
SWB.ReloadSound = "Weapon_SMG1.Reload"
SWB.ReloadDuration = 2.35

SWB.Recoil = 1
SWB.KickUp = 0.7
SWB.KickSide = 0.3
SWB.RecoilPattern = {
    {-0.08, 0.7},
    {0.1, 0.82},
    {-0.12, 0.94},
    {0.13, 1.05}
}

SWB.AimFOV = 62
SWB.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}

SWB.Attachments = {
    { id = "optic", name = "Optic", type = "optic" },
    { id = "stock", name = "Stock", type = "stock" }
}

SWB.AttachmentDefinitions = {
    holo = {
        name = "Holographic Sight",
        description = "Improves aimed precision.",
        type = "optic",
        modifiers = {
            ["spread.ads"] = { multiply = 0.72 }
        }
    },
    light_stock = {
        name = "Light Stock",
        description = "Faster aim transition with less recoil recovery.",
        type = "stock",
        modifiers = {
            ["ads.speed"] = { multiply = 1.2 },
            ["recoil.scalar"] = { multiply = 0.9 }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
