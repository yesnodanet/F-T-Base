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

TFA.Primary.Damage = 35
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 90
TFA.Primary.Ammo = "SMG1"
TFA.Primary.Sound = "Weapon_AR2.Single"
TFA.Primary.RPM = 650

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

FT.Attachments.Slots = {
    {
        id = "optic",
        type = "optic",
        name = "Optic"
    },
    {
        id = "muzzle",
        type = "muzzle",
        name = "Muzzle"
    }
}
]]
