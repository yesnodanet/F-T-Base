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

TFA.PrintName = "F&T Template - TFA Dialect"
TFA.Category = "F&T Base Templates"
TFA.ViewModel = "models/weapons/c_irifle.mdl"
TFA.WorldModel = "models/weapons/w_irifle.mdl"
TFA.HoldType = "ar2"

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

TFA.Attachments = {
    { id = "optic", name = "Optic", type = "optic" },
    { id = "muzzle", name = "Muzzle", type = "muzzle" }
}

TFA.AttachmentDefinitions = {
    reflex = {
        name = "Reflex Sight",
        description = "Tighter aiming spread with a slightly narrower view.",
        type = "optic",
        modifiers = {
            ["spread.ads"] = { multiply = 0.78 },
            ["ads.fov"] = { add = -4 }
        }
    },
    compensator = {
        name = "Compensator",
        description = "Reduces vertical recoil at the cost of hip-fire spread.",
        type = "muzzle",
        modifiers = {
            ["recoil.scalar"] = { multiply = 0.8 },
            ["spread.hip"] = { add = 0.002 }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
