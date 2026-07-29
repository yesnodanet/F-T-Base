if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "swb_base"
SWEP.PrintName = "F&T Native Template - SWB Rifle"
SWEP.Category = "F&T Native Templates / SWB"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/c_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.ViewModelFOV = 50
SWEP.HoldType = "smg"
SWEP.NormalHoldType = "smg"
SWEP.RunHoldType = "passive"

SWEP.FireModes = {"auto", "semi"}
SWEP.CaseLength = 45
SWEP.BulletDiameter = 5.56
SWEP.Damage = 26
SWEP.FireDelay = 0.075
SWEP.FireSound = "Weapon_SMG1.Single"
SWEP.FireSoundSuppressed = "Weapon_SMG1.Single"
SWEP.ReloadSound = "Weapon_SMG1.Reload"
SWEP.ReloadDuration = 2.35
SWEP.HipSpread = 0.019
SWEP.AimSpread = 0.008
SWEP.SpreadPerShot = 0.001
SWEP.MaxSpreadInc = 0.012
SWEP.SpreadCooldown = 0.25
SWEP.VelocitySensitivity = 1
SWEP.WaitForReloadAfterFiring = 0.075
SWEP.Recoil = 1
SWEP.KickUp = 0.7
SWEP.KickSide = 0.3
SWEP.ZoomAmount = 15
SWEP.AimFOV = 62
SWEP.AimPos = Vector(-5, -4.5, 1.8)
SWEP.AimAng = Angle(0, 0, 0)
SWEP.SpeedDec = 0.82
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = true

SWEP.Primary = {
    ClipSize = 36,
    DefaultClip = 144,
    Automatic = true,
    Ammo = "SMG1"
}

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = true,
    Ammo = "none"
}

local nativeDependency = {
    id = "swb",
    dialect = "SWB",
    templateClass = "ft_native_template_swb",
    baseClass = "swb_base",
    required = true,
    requiredClasses = {"swb_base"},
    workshop = {
        {id = "1967187358", role = "base"}
    },
    capabilities = {
        hud = true,
        ads = true,
        inspect = false,
        customization = false,
        attachments = false,
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
