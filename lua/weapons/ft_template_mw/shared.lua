if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - MW Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "MW"

MW.PrintName = "F&T Template - MW Dialect"
MW.Category = "F&T Base Templates"
MW.ViewModel = "models/weapons/c_irifle.mdl"
MW.WorldModel = "models/weapons/w_irifle.mdl"
MW.HoldType = "ar2"
MW.UseHands = true

MW.Damage = 34
MW.DamageMin = 22
MW.Range = 2400
MW.Penetration = 8
MW.RPM = 720
MW.Automatic = true
MW.ClipSize = 30
MW.DefaultClip = 120
MW.Ammo = "AR2"
MW.Spread = 0.012
MW.ADSSpread = 0.005
MW.MoveSpread = 0.01

MW.Recoil.Vertical = 0.9
MW.Recoil.Horizontal = 0.24
MW.Recoil.Roll = 0.05
MW.Recoil.Pattern = {
    {0.04, 0.82},
    {-0.15, 1.02},
    {0.18, 1.16},
    {-0.2, 1.28}
}

MW.Camera.Shake = 0.28
MW.Camera.Sway = 0.08
MW.Camera.Breathing = 0.04
MW.Aim.FOV = 58
MW.Aim.Speed = 1.3

MW.Sound.Fire = "Weapon_AR2.Single"
MW.Sound.Reload = "Weapon_AR2.Reload"
MW.Reload.Duration = 2.05
MW.Effects.Muzzle = "MuzzleEffect"
MW.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}

MW.Attachments = {
    slots = {
        { id = "optic", name = "Optic", type = "optic" },
        { id = "barrel", name = "Barrel", type = "barrel" }
    },
    definitions = {
        red_dot = {
            name = "Red Dot Sight",
            description = "Tighter aiming spread and a focused sight picture.",
            type = "optic",
            modifiers = {
                ["spread.ads"] = { multiply = 0.76 },
                ["ads.fov"] = { add = -3 }
            }
        },
        long_barrel = {
            name = "Long Barrel",
            description = "Better damage retention and less horizontal recoil.",
            type = "barrel",
            modifiers = {
                ["damage.minimum"] = { add = 4 },
                ["recoil.scalar"] = { multiply = 0.9 }
            }
        }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
