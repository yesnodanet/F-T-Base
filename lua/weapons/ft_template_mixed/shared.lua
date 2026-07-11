if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - Mixed TFA SWB MW"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "TFA"
using "SWB"
using "MW"

FT.Priority = { "MW", "SWB", "TFA" }
FT.Customization.Provider = "mixed"
FT.Merge = {
    ["recoil.procedural.vertical"] = "maximum",
    ["spread.ads"] = "minimum"
}

TFA.PrintName = "F&T Template - Mixed TFA SWB MW"
TFA.Category = "F&T Base Templates"
TFA.Primary.Damage = 30
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 120
TFA.Primary.Ammo = "AR2"
TFA.Primary.Automatic = true
TFA.Primary.Sound = "Weapon_AR2.Single"
TFA.KickUp = 0.78
TFA.KickHorizontal = 0.18

SWB.FireDelay = 0.082
SWB.HipSpread = 0.014
SWB.AimSpread = 0.006
SWB.RecoilPattern = {
    {0, 0.75},
    {-0.12, 0.92},
    {0.14, 1.08},
    {-0.16, 1.18}
}

MW.DamageMin = 21
MW.Range = 2200
MW.Penetration = 6
MW.Camera.Shake = 0.22
MW.Camera.Sway = 0.1
MW.Aim.FOV = 60
MW.Aim.Speed = 1.2
MW.ViewModel = "models/weapons/c_irifle.mdl"
MW.WorldModel = "models/weapons/w_irifle.mdl"
MW.HoldType = "ar2"
MW.Sound.Reload = "Weapon_AR2.Reload"
MW.Reload.Duration = 2.1
MW.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}

TFA.Attachments = {
    { id = "optic", name = "Optic", type = "optic" },
    { id = "muzzle", name = "Muzzle", type = "muzzle" }
}

TFA.AttachmentDefinitions = {
    hybrid_optic = {
        name = "Hybrid Optic",
        description = "Combines the precise sight picture of the mixed platform.",
        type = "optic",
        modifiers = {
            ["spread.ads"] = { multiply = 0.7 },
            ["ads.fov"] = { add = -5 }
        }
    },
    brake = {
        name = "Muzzle Brake",
        description = "Limits camera shake and vertical recoil.",
        type = "muzzle",
        modifiers = {
            ["camera.shake"] = { multiply = 0.72 },
            ["recoil.scalar"] = { multiply = 0.84 }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
