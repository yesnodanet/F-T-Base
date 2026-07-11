-- GMod Lua smoke test. Run after F&T Base is loaded.

local function compile(name, source)
    local result = FTBase.Compiler.CompileSource(source, {
        name = name
    })

    if result.report:HasErrors() then
        error(result.report:ToString())
    end

    return result
end

local tfa = compile("ft_tfa_template", [[
using "TFA"
TFA.Primary.Damage = 31
TFA.Primary.RPM = 680
TFA.Primary.ClipSize = 30
TFA.Primary.DefaultClip = 120
TFA.Primary.Ammo = "AR2"
TFA.Primary.Automatic = true
TFA.Primary.IronAccuracy = 0.008
TFA.Primary.Sound = "Weapon_AR2.Single"
TFA.ReloadDuration = 2.1
TFA.Attachments = {
    { id = "optic", type = "optic" }
}
TFA.AttachmentDefinitions = {
    reflex = {
        type = "optic",
        modifiers = {
            ["spread.ads"] = { multiply = 0.75 }
        }
    }
}
]])

assert(tfa.ir.damage.base == 31, "TFA damage mapping failed")
assert(tfa.ir.ammo.clipSize == 30, "TFA ammo mapping failed")
assert(#tfa.ir.attachments.slots == 1, "TFA attachment mapping failed")

local swb = compile("ft_swb_template", [[
using "SWB"
SWB.Damage = 26
SWB.FireDelay = 0.075
SWB.ClipSize = 36
SWB.DefaultClip = 144
SWB.Ammo = "SMG1"
SWB.FireSound = "Weapon_SMG1.Single"
SWB.RecoilPattern = {
    {0, 0.7},
    {0.1, 0.9}
}
]])

assert(swb.ir.damage.base == 26, "SWB damage mapping failed")
assert(swb.ir.fire.delay == 0.075, "SWB fire delay mapping failed")
assert(#swb.ir.recoil.pattern == 2, "SWB recoil mapping failed")

local mw = compile("ft_mw_template", [[
using "MW"
MW.Damage = 34
MW.DamageMin = 22
MW.Range = 2400
MW.RPM = 720
MW.ClipSize = 30
MW.DefaultClip = 120
MW.Ammo = "AR2"
MW.Sound.Fire = "Weapon_AR2.Single"
MW.Reload.Duration = 2.05
MW.Attachments = {
    slots = {
        { id = "barrel", type = "barrel" }
    },
    definitions = {
        long_barrel = {
            type = "barrel",
            modifiers = {
                ["damage.minimum"] = { add = 4 }
            }
        }
    }
}
]])

assert(mw.ir.damage.minimum == 22, "MW minimum damage mapping failed")
assert(mw.ir.animations.reloadDuration == 2.05, "MW reload mapping failed")

local recordedDamage = nil
local bullet = FTBase.Runtime.Ballistics.BuildBullet({}, {
    GetShootPos = function()
        return {
            Distance = function()
                return 1200
            end
        }
    end,
    GetAimVector = function()
        return {}
    end
}, mw.ir)

bullet.Callback(nil, { HitPos = {}, HitGroup = 0 }, {
    SetDamage = function(_, value)
        recordedDamage = value
    end
})

assert(math.abs(recordedDamage - 28) < 0.0001, "MW damage falloff failed")

local mixed = compile("ft_mixed_template", [[
using "TFA"
using "SWB"
using "MW"

FT.Priority = { "MW", "SWB", "TFA" }
FT.Merge = {
    ["spread.ads"] = "minimum"
}

TFA.Primary.Damage = 30
TFA.Primary.ClipSize = 30
TFA.Primary.Sound = "Weapon_AR2.Single"
SWB.FireDelay = 0.082
SWB.AimSpread = 0.006
MW.Aim.FOV = 60
MW.Camera.Shake = 0.22
]])

assert(mixed.ir.damage.base == 30, "Mixed damage mapping failed")
assert(mixed.ir.fire.delay == 0.082, "Mixed fire delay mapping failed")
assert(mixed.ir.camera.shake == 0.22, "Mixed camera mapping failed")

local runtime = {
    ir = tfa.ir,
    attachments = FTBase.Runtime.Attachments.NewState(tfa.ir)
}

FTBase.Runtime.Attachments.RebuildModifiers(runtime)

assert(FTBase.Runtime.Customization.CanInstall(runtime, "optic", "reflex"), "Attachment compatibility failed")
assert(FTBase.Runtime.Customization.Install(runtime, "optic", "reflex"), "Attachment installation failed")
assert(math.abs(FTBase.Runtime.Customization.GetEffectiveIR(runtime).spread.ads - 0.006) < 0.0001, "Attachment modifier rebuild failed")
assert(FTBase.Runtime.Customization.Uninstall(runtime, "optic"), "Attachment removal failed")

local configuredSWEP = {
    Primary = {}
}

FTBase.Runtime.Lifecycle.ApplyConfig(configuredSWEP, tfa.ir)
assert(configuredSWEP.Primary.ClipSize == 30, "SWEP clip configuration failed")
assert(configuredSWEP.Primary.DefaultClip == 120, "SWEP default clip configuration failed")

SERVER = true

local clip = 10
local reserve = 30
local owner = {
    GetAmmoCount = function()
        return reserve
    end,
    RemoveAmmo = function(_, amount)
        reserve = reserve - amount
    end
}
local reloadSWEP = {
    FTRuntime = FTBase.Runtime.Engine.BuildRuntime({}, tfa.ir, tfa.report),
    GetOwner = function()
        return owner
    end,
    Clip1 = function()
        return clip
    end,
    SetClip1 = function(_, value)
        clip = value
    end,
    SetNextPrimaryFire = function() end
}

assert(FTBase.Runtime.Engine.Reload(reloadSWEP), "Reload lifecycle did not start")
assert(clip == 30 and reserve == 10, "Manual reload did not transfer ammunition")
SERVER = nil

print("F&T smoke test passed: TFA, SWB, MW, mixed dialects, and attachments")

return {
    tfa = tfa,
    swb = swb,
    mw = mw,
    mixed = mixed
}
