if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - SWB Native HUD"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "SWB"

FT.Visual.Default = "SWB"

SWB.PrintName = "SWB Native HUD Fixture"
SWB.Category = "F&T Base Templates"
-- SWB snapshot has no sample weapon/model closure; stock SMG1 models keep this HUD-only fixture spawnable.
SWB.ViewModel = "models/weapons/c_smg1.mdl"
SWB.WorldModel = "models/weapons/w_smg1.mdl"
SWB.HoldType = "smg"
SWB.ViewModelFOV = 50

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
SWB.ZoomAmount = 15
SWB.AimFOV = 62
SWB.AimPos = Vector(-5, -4.5, 1.8)
SWB.AimAng = Angle(0, 0, 0)
SWB.SpeedDec = 0.82
SWB.DrawCrosshair = false
SWB.DrawAmmo = true
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
