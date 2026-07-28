if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Template - TacRP Dialect"
SWEP.Category = "F&T Base Templates"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.FTSource = [[
using "TacRP"

TacRP.PrintName = "F&T Template - TacRP Dialect"
TacRP.Category = "F&T Base Templates"
TacRP.ViewModel = "models/weapons/c_irifle.mdl"
TacRP.WorldModel = "models/weapons/w_irifle.mdl"
TacRP.Damage_Max = 31
TacRP.Damage_Min = 20
TacRP.Range_Max = 2250
TacRP.RPM = 690
TacRP.Automatic = true
TacRP.ClipSize = 30
TacRP.DefaultClip = 120
TacRP.Ammo = "AR2"
TacRP.Spread = 0.013
TacRP.RecoilKick = 0.88
TacRP.Sound_Shoot = "Weapon_AR2.Single"
TacRP.Animations = {
    fire = ACT_VM_PRIMARYATTACK,
    reload = ACT_VM_RELOAD,
    deploy = ACT_VM_DRAW
}
TacRP.Attachments = {
    { id = "optic", name = "Optic", type = "optic" },
    { id = "muzzle", name = "Muzzle", type = "muzzle" }
}
TacRP.AttachmentDefinitions = {
    compact_optic = {
        name = "Compact Optic",
        type = "optic",
        icon = "ft_base/providers/tacrp/hud/news.png",
        visuals = {
            view = {model = "models/weapons/c_pistol.mdl", pos = Vector(2, 0, 1), scale = 0.22},
            world = {model = "models/weapons/w_pistol.mdl", pos = Vector(2, 0, 1), scale = 0.22}
        },
        modifiers = { ["spread.ads"] = { multiply = 0.75 } }
    },
    flash_hider = {
        name = "Flash Hider",
        type = "muzzle",
        visuals = {
            view = {model = "models/props_c17/TrapPropeller_Engine.mdl", scale = 0.05},
            world = {model = "models/props_c17/TrapPropeller_Engine.mdl", scale = 0.05}
        },
        modifiers = { ["camera.shake"] = { multiply = 0.84 } }
    }
}
]]

FTBase.Runtime.Lifecycle.PrepareDefinition(SWEP)
