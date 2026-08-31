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
assert(tfa.ir.ui.customization.provider == "tfa", "TFA customization provider failed")
assert(tfa.ir.ui.visual.providers.inspect == "tfa", "TFA inspect provider failed")
assert(tfa.ir.ui.visual.providers.attachments == "tfa", "TFA attachment visual provider failed")
assert(tfa.ir.ui.visual.providers.hud == "tfa", "TFA HUD provider failed")
assert(tfa.ir.ui.visual.providers.presentation == "tfa", "TFA presentation provider failed")

local pose = compile("ft_vector_literal", [[
using "TFA"
TFA.IronSightsPos = Vector(1, 2, 3)
TFA.IronSightsAng = Angle(4, 5, 6)
]])

if Vector and Angle then
    assert(type(pose.ir.ads.pos) ~= "table", "Vector literal was not normalized")
    assert(type(pose.ir.ads.ang) ~= "table", "Angle literal was not normalized")

    local position, angle = FTBase.Runtime.Rendering.GetAimPose(pose.ir)
    assert(isvector(position), "ADS position is not a GMod Vector")
    assert(isangle(angle), "ADS angle is not a GMod Angle")
else
    assert(pose.ir.ads.pos.__type == "Vector", "Vector literal AST was lost")
    assert(pose.ir.ads.ang.__type == "Angle", "Angle literal AST was lost")
end

local invalidPosePosition, invalidPoseAngle = FTBase.Runtime.Rendering.GetAimPose({
    ads = {
        pos = {0, 0, 0},
        ang = {0, 0, 0}
    }
})

assert(invalidPosePosition == nil, "Invalid ADS position table was passed through")
assert(invalidPoseAngle == nil, "Invalid ADS angle table was passed through")

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
assert(swb.ir.ui.customization.provider == "swb", "SWB customization provider failed")
assert(swb.ir.ui.visual.providers.inspect == "swb", "SWB visual provider failed")

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
assert(#mw.ir.attachments.slots == 1, "MW nested attachment slots failed")
assert(mw.ir.attachments.definitions.long_barrel ~= nil, "MW nested attachment definitions failed")
assert(mw.ir.ui.customization.provider == "mw", "MW customization provider failed")
assert(mw.ir.ui.visual.providers.attachments == "mw", "MW attachment visual provider failed")

local arc9 = compile("ft_arc9_template", [[
using "ARC9"
ARC9.DamageMax = 33
ARC9.RPM = 700
ARC9.ClipSize = 30
ARC9.DefaultClip = 120
ARC9.Ammo = "AR2"
ARC9.Attachments = {
    { id = "optic", type = "optic" }
}
ARC9.AttachmentDefinitions = {
    red_dot = { type = "optic" }
}
]])

assert(arc9.ir.damage.base == 33, "ARC9 damage mapping failed")
assert(arc9.ir.ui.visual.providers.attachments == "arc9", "ARC9 provider failed")
assert(#arc9.ir.attachments.slots == 1, "ARC9 attachment mapping failed")

local arccw = compile("ft_arccw_template", [[
using "ArcCW"
ArcCW.Damage = 29
ArcCW.RPM = 660
ArcCW.Primary.ClipSize = 30
ArcCW.Primary.DefaultClip = 120
ArcCW.Primary.Ammo = "AR2"
ArcCW.Attachments = {
    { id = "barrel", type = "barrel" }
}
ArcCW.AttachmentDefinitions = {
    short_barrel = { type = "barrel" }
}
]])

assert(arccw.ir.ammo.defaultClip == 120, "ArcCW default clip mapping failed")
assert(arccw.ir.ui.visual.providers.hud == "arccw", "ArcCW provider failed")

local tacrp = compile("ft_tacrp_template", [[
using "TacRP"
TacRP.Damage_Max = 30
TacRP.RPM = 680
TacRP.ClipSize = 30
TacRP.DefaultClip = 120
TacRP.Ammo = "AR2"
TacRP.Attachments = {
    { id = "muzzle", type = "muzzle" }
}
TacRP.AttachmentDefinitions = {
    flash_hider = { type = "muzzle" }
}
]])

assert(tacrp.ir.damage.base == 30, "TacRP damage mapping failed")
assert(tacrp.ir.ammo.defaultClip == 120, "TacRP default clip mapping failed")
assert(tacrp.ir.ui.visual.providers.presentation == "tacrp", "TacRP provider failed")

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

FT.Priority = { "TFA", "MW", "SWB" }
FT.Customization.Provider = "mixed"
FT.Merge = {
    ["spread.ads"] = "minimum"
}

TFA.Primary.Damage = 30
TFA.Primary.ClipSize = 30
TFA.Primary.Sound = "Weapon_AR2.Single"
TFA.ViewModel = "models/weapons/c_irifle.mdl"
TFA.Animations = { reload = ACT_VM_RELOAD }
SWB.FireDelay = 0.082
SWB.AimSpread = 0.006
MW.Aim.FOV = 60
MW.Camera.Shake = 0.22
MW.Attachments = {
    slots = {
        { id = "barrel", type = "barrel" }
    },
    definitions = {
        long_barrel = { type = "barrel" }
    }
}
]])

assert(mixed.ir.damage.base == 30, "Mixed damage mapping failed")
assert(mixed.ir.fire.delay == 0.082, "Mixed fire delay mapping failed")
assert(mixed.ir.camera.shake == 0.22, "Mixed camera mapping failed")
assert(mixed.ir.ui.customization.provider == "mw", "Mixed customization provider failed")
assert(mixed.ir.ui.visual.providers.inspect == "tfa", "Mixed inspect should use TFA")
assert(mixed.ir.ui.visual.providers.hud == "tfa", "Mixed HUD should use TFA")
assert(mixed.ir.ui.visual.providers.presentation == "tfa", "Mixed presentation should use TFA")
assert(mixed.ir.ui.visual.providers.attachments == "mw", "Mixed attachments should use MW")

local overridden = compile("ft_visual_override", [[
using "TFA"
FT.Visual.HUD = "TacRP"
TFA.Primary.ClipSize = 30
]])

assert(overridden.ir.ui.visual.providers.hud == "tacrp", "Visual HUD override failed")

local tfaProvider, tfaProviderId = FTBase.Runtime.Customization.GetProvider({ir = tfa.ir})
local mwProvider, mwProviderId = FTBase.Runtime.Customization.GetProvider({ir = mw.ir})
local mixedProvider, mixedProviderId = FTBase.Runtime.Customization.GetProvider({ir = mixed.ir})

assert(tfaProviderId == "tfa" and tfaProvider.id == "tfa", "TFA provider registry failed")
assert(mwProviderId == "mw" and mwProvider.id == "mw", "MW provider registry failed")
assert(mixedProviderId == "mw" and mixedProvider.id == "mw", "Mixed provider registry failed")
assert(mwProvider:BuildRequest("barrel", "long_barrel").attachmentId == "long_barrel", "Provider request API failed")
assert(FTBase.Runtime.Visuals.GetProvider({ir = arc9.ir}, "hud").id == "arc9", "Visual provider registry failed")

for _, providerId in ipairs({"ft", "tfa", "swb", "mw", "arc9", "arccw", "tacrp"}) do
    local provider = FTBase.Runtime.ProviderHost.Get(providerId)
    for _, method in ipairs({"Open", "Close", "Refresh", "HandleInput", "DrawHUD", "ApplyPresentation", "GetSlots", "GetOptions", "GetInspectData", "BuildAttachmentRequest"}) do
        assert(type(provider[method]) == "function", providerId .. " provider is missing " .. method)
    end

    assert(type(provider.shell) == "table" and type(provider.shell.layout) == "string",
        providerId .. " provider is missing inspect shell layout")

    if providerId ~= "ft" then
        assert(provider.shell.mode == "fullscreen",
            providerId .. " inspect shell is still using the generic framed UI")
    end
end

assert(string.find(tfaProvider.assetRoot or "", "ft_base/providers/tfa", 1, true), "TFA provider asset namespace missing")
assert(string.find(mwProvider.iconMaterial or "", "ft_base/providers/mw", 1, true), "MW provider icon namespace missing")

local runtime = {
    ir = tfa.ir,
    attachments = FTBase.Runtime.Attachments.NewState(tfa.ir)
}

local inspectData = FTBase.Runtime.Customization.GetInspectData(runtime, "optic")
assert(inspectData.slot and inspectData.slot.id == "optic", "Inspect provider data lookup failed")

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

local converterOptions = {
    imports = {"TFA", "tfa"}
}
local converted = FTConverter.Convert([[
Primary.Damage = 37
Primary.ClipSize = 30
Primary.DefaultClip = 120
Primary.Ammo = "AR2"
AttachmentDefinitions = {
    reflex = { type = "optic" }
}
]], "TFA", "ARC9", converterOptions)

assert(not converted.report:HasErrors(), converted.report:ToString())
assert(#converterOptions.imports == 2 and converterOptions.imports[1] == "TFA" and converterOptions.imports[2] == "tfa",
    "Converter mutated caller imports")
assert(type(converted.warnings) == "table", "Converter warnings field is missing")
assert(string.find(converted.output, "ARC9.DefaultClip = 120", 1, true), "Converter dropped default clip")
assert(string.find(converted.output, "ARC9.AttachmentDefinitions", 1, true), "Converter dropped attachment definitions")

local convertedAgain = FTConverter.Convert("Primary.Damage = 38", "TFA", "FT", converterOptions)
assert(not convertedAgain.report:HasErrors(), convertedAgain.report:ToString())
assert(#converterOptions.imports == 2 and converterOptions.imports[1] == "TFA" and converterOptions.imports[2] == "tfa",
    "Repeated converter use mutated caller imports")

local generatedFields = {
    FT = {"FT.Ammo.DefaultClip", "FT.Attachments.Definitions"},
    TFA = {"TFA.Primary.DefaultClip", "TFA.AttachmentDefinitions"},
    ARC9 = {"ARC9.DefaultClip", "ARC9.AttachmentDefinitions"},
    ArcCW = {"ArcCW.Primary.DefaultClip", "ArcCW.AttachmentDefinitions"},
    MW = {"MW.DefaultClip", "MW.Attachments.Definitions"},
    TacRP = {"TacRP.DefaultClip", "TacRP.AttachmentDefinitions"},
    SWB = {"SWB.DefaultClip", "SWB.AttachmentDefinitions"}
}

for target, fields in pairs(generatedFields) do
    local generatedReport = FTBase.Report.New("converter-test")
    local output = FTConverter.Generator.Generate(tfa.ir, target, generatedReport)

    assert(not generatedReport:HasErrors(), generatedReport:ToString())

    for _, field in ipairs(fields) do
        assert(string.find(output, field, 1, true), target .. " generator dropped " .. field)
    end
end

local recoilIR = FTBase.IR.Clone(tfa.ir)
recoilIR.recoil.pattern = {{0.25, 0.5}}
local ftTargetReport = FTBase.Report.New("ft-target-warning-test")
local _, ftTargetWarnings = FTConverter.Generator.Generate(recoilIR, "F&T", ftTargetReport)
assert(#ftTargetWarnings == 0, "F&T target was reported as lossy")

local lossyIR = FTBase.IR.Clone(tfa.ir)
lossyIR.movement.speed = 0.8
local tfaTargetReport = FTBase.Report.New("tfa-loss-warning-test")
local _, tfaTargetWarnings = FTConverter.Generator.Generate(lossyIR, "TFA", tfaTargetReport)
local foundLossWarning = false

for _, warning in ipairs(tfaTargetWarnings) do
    if string.find(warning, "movement", 1, true) then
        foundLossWarning = true
        break
    end
end

assert(foundLossWarning, "Converter did not warn about an unsupported IR field")

local safeEmitterReport = FTBase.Report.New("emitter-test")
local safeEmitterOutput = FTBase.Compiler.Emitter.EmitAssignments({
    {
        path = "FT.Animations.Base",
        value = {
            reload = {__type = "Symbol", name = "ACT_VM_RELOAD"},
            pose = {__type = "Vector", x = 1, y = 2, z = 3}
        }
    }
}, safeEmitterReport)

assert(not safeEmitterReport:HasErrors(), safeEmitterReport:ToString())
assert(string.find(safeEmitterOutput, "ACT_VM_RELOAD", 1, true), "Whitelisted emitter symbol was rejected")
assert(string.find(safeEmitterOutput, "Vector(1, 2, 3)", 1, true), "Vector emitter value was rejected")

if type(Vector) == "function" and type(Angle) == "function" then
    local nativeEmitterReport = FTBase.Report.New("native-emitter-test")
    local nativeEmitterOutput = FTBase.Compiler.Emitter.EmitAssignments({
        {
            path = "FT.Ads.Pos",
            value = Vector(1, 2, 3)
        },
        {
            path = "FT.Ads.Ang",
            value = Angle(4, 5, 6)
        }
    }, nativeEmitterReport)

    assert(not nativeEmitterReport:HasErrors(), nativeEmitterReport:ToString())
    assert(string.find(nativeEmitterOutput, "Vector(1, 2, 3)", 1, true),
        "Native Vector emitter value was rejected")
    assert(string.find(nativeEmitterOutput, "Angle(4, 5, 6)", 1, true),
        "Native Angle emitter value was rejected")
end

local unsafeEmitterReport = FTBase.Report.New("emitter-test")
local unsafeEmitterOutput = FTBase.Compiler.Emitter.EmitAssignments({
    {
        path = "FT.Meta.Author",
        value = {__type = "Call", name = "RunString", args = {"return 1"}}
    },
    {
        path = "FT.Meta.Category",
        value = {__type = "Symbol", name = "UNTRUSTED_GLOBAL"}
    }
}, unsafeEmitterReport)

assert(unsafeEmitterReport:HasErrors(), "Unsafe emitter values were accepted")
assert(unsafeEmitterOutput == "", "Unsafe emitter values produced output")

local uppercaseVisualRuntime = {
    ir = {
        ui = {
            visual = {
                providers = {
                    HUD = "TacRP",
                    INSPECT = "TFA",
                    attachments = "MW"
                }
            },
            customization = {
                provider = "SWB"
            }
        }
    }
}

assert(FTBase.Runtime.Visuals.GetProvider(uppercaseVisualRuntime, "hud").id == "tacrp",
    "Visual provider keys were not normalized")
assert(FTBase.Runtime.Customization.GetProvider(uppercaseVisualRuntime, "attachments").id == "mw",
    "Attachment visual domain was not explicit")
assert(FTBase.Runtime.Customization.GetInspectProvider(uppercaseVisualRuntime).id == "tfa",
    "Inspect visual domain was not explicit")
assert(FTBase.Runtime.Visuals.GetDisplayName({meta = {printName = ""}}, {PrintName = ""}) == "Weapon",
    "Empty weapon name did not use fallback")
assert(FTBase.Runtime.Visuals.ResolveFont("Trebuchet48") == "DermaDefault",
    "Invalid compatibility font did not use the safe default")
assert(FTBase.Runtime.Visuals.ResolveFont("missing-font", "Trebuchet48") == "DermaDefault",
    "Invalid HUD font did not use a valid fallback")

local inspectStyle = FTBase.Runtime.Visuals.GetInspectStyle(uppercaseVisualRuntime)
assert(inspectStyle.shell and inspectStyle.preview and inspectStyle.stats,
    "Inspect provider does not expose shell, preview, and stat styling")

local previousSERVER = SERVER
SERVER = true

local reloadSucceeded, reloadError = pcall(function()
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
end)

SERVER = previousSERVER

if not reloadSucceeded then
    error(reloadError, 0)
end

print("F&T smoke test passed: six visual providers, provenance, mixed dialects, and attachments")

return {
    tfa = tfa,
    swb = swb,
    mw = mw,
    arc9 = arc9,
    arccw = arccw,
    tacrp = tacrp,
    mixed = mixed
}
