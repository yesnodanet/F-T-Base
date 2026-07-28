-- Server-safe smoke test. Run with: lua_run include("ft_base/tests/smoke.lua")

local cases = {
    {
        name = "TFA",
        source = [[
using "TFA"
TFA.Primary.Damage = 31
TFA.Primary.ClipSize = 30
TFA.Primary.Ammo = "AR2"
TFA.Attachments = { { id = "optic", type = "optic" } }
]],
        provider = "tfa"
    },
    {
        name = "MW",
        source = [[
using "MW"
MW.Damage = 31
MW.ClipSize = 30
MW.Ammo = "AR2"
MW.Attachments = { slots = { { id = "optic", type = "optic" } } }
]],
        provider = "mw"
    },
    {
        name = "SWB",
        source = [[
using "SWB"
SWB.Damage = 31
SWB.ClipSize = 30
SWB.Ammo = "AR2"
]],
        provider = "swb"
    },
    {
        name = "ARC9",
        source = [[
using "ARC9"
ARC9.DamageMax = 31
ARC9.ClipSize = 30
ARC9.Ammo = "AR2"
]],
        provider = "arc9"
    },
    {
        name = "ArcCW",
        source = [[
using "ArcCW"
ArcCW.Damage = 31
ArcCW.Primary.ClipSize = 30
ArcCW.Primary.Ammo = "AR2"
]],
        provider = "arccw"
    },
    {
        name = "TacRP",
        source = [[
using "TacRP"
TacRP.Damage_Max = 31
TacRP.ClipSize = 30
TacRP.Ammo = "AR2"
]],
        provider = "tacrp"
    }
}

for _, case in ipairs(cases) do
    local result = FTBase.Compiler.CompileSource(case.source, {name = "ft_smoke_" .. case.name})

    assert(not result.report:HasErrors(), result.report:ToString())
    assert(result.ir.ui.visual.providers.inspect == case.provider, case.name .. " inspect provider failed")
    assert(result.ir.ui.visual.providers.attachments == case.provider, case.name .. " attachment provider failed")
    assert(result.ir.ui.visual.providers.hud == case.provider, case.name .. " HUD provider failed")
    assert(result.ir.ui.visual.providers.presentation == case.provider, case.name .. " presentation provider failed")
end

local mixed = FTBase.Compiler.CompileSource([[
using "TFA"
using "MW"
FT.Priority = { "TFA", "MW" }
TFA.Primary.ClipSize = 30
TFA.Primary.Ammo = "AR2"
TFA.ViewModel = "models/weapons/c_irifle.mdl"
MW.Attachments = {
    slots = { { id = "optic", type = "optic" } }
}
]], {name = "ft_smoke_mixed"})

assert(not mixed.report:HasErrors(), mixed.report:ToString())
assert(mixed.ir.ui.visual.providers.inspect == "tfa", "Mixed inspect provider failed")
assert(mixed.ir.ui.visual.providers.hud == "tfa", "Mixed HUD provider failed")
assert(mixed.ir.ui.visual.providers.presentation == "tfa", "Mixed presentation provider failed")
assert(mixed.ir.ui.visual.providers.attachments == "mw", "Mixed attachment provider failed")

local legacyIR = FTBase.IR.New()
legacyIR.meta.sourceStyles = {TFA = true}
legacyIR.ui.visual.providers.hud = "ft"
legacyIR.ui.visual.sources.hud = "TFA"
assert(FTBase.Runtime.ProviderHost.GetProviderId({ir = legacyIR}, "hud") == "tfa",
    "Runtime provenance fallback did not select TFA")

legacyIR.ui.visual.sources.hud = "explicit"
assert(FTBase.Runtime.ProviderHost.GetProviderId({ir = legacyIR}, "hud") == "ft",
    "Explicit FT HUD provider was not preserved")

print("F&T Base visual smoke test passed")

return true
