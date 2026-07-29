-- Core/compiler regression checks. Run with:
-- lua_run include("ft_base/tests/core_regression.lua")

local function mergeCase(strategy, first, second, expected)
    local ir = FTBase.IR.New()
    local report = FTBase.Report.New("merge-test")

    FTBase.Merge.Apply(ir, {
        source = "test",
        externalPath = "Value",
        irPath = "damage.base",
        value = first,
        strategy = strategy
    }, report)

    FTBase.Merge.Apply(ir, {
        source = "test",
        externalPath = "Value",
        irPath = "damage.base",
        value = second,
        strategy = strategy
    }, report)

    assert(ir.damage.base == expected, strategy .. " merge semantics failed")
end

mergeCase("first", 30, 60, 30)
mergeCase("multiply", 30, 2, 60)
mergeCase("average", 30, 50, 40)
mergeCase("minimum", 30, 20, 20)
mergeCase("maximum", 30, 40, 40)

local malformed = FTBase.Compiler.CompileSource("FT.Damage.Base = 1e+", {name = "core-malformed-number"})
assert(malformed.report:HasErrors(), "malformed number did not reach report.errors")

local unknownCall = FTBase.Compiler.CompileSource("FT.Damage.Base = Dangerous()", {name = "core-unknown-call"})
assert(unknownCall.report:HasErrors(), "unknown call did not reach report.errors")

local function withCompilerLimit(name, value, callback)
    local previous = FTBase.Compiler.Limits[name]
    FTBase.Compiler.Limits[name] = value
    local succeeded, failure = pcall(callback)
    FTBase.Compiler.Limits[name] = previous

    if not succeeded then
        error(failure, 0)
    end
end

withCompilerLimit("maxSourceBytes", 32, function()
    local oversized = FTBase.Compiler.CompileSource(string.rep(" ", 33), {name = "core-source-limit"})
    assert(oversized.report:HasErrors(), "source byte limit was not enforced")
end)

withCompilerLimit("maxASTNodes", 6, function()
    local tooManyNodes = FTBase.Compiler.CompileSource([[
FT.Damage.Base = 1
FT.Damage.Minimum = 1
FT.Fire.RPM = 600
]], {name = "core-ast-limit"})
    assert(tooManyNodes.report:HasErrors(), "AST node limit was not enforced")
end)

withCompilerLimit("maxDepth", 2, function()
    local tooDeep = FTBase.Compiler.CompileSource([[
FT.Damage.Curve = {{{1}}}
]], {name = "core-depth-limit"})
    assert(tooDeep.report:HasErrors(), "nesting depth limit was not enforced")
end)

local invalidModifier = FTBase.Compiler.CompileSource([[
FT.Attachments.Slots = {
    {id = "magazine", type = "magazine"}
}
FT.Attachments.Definitions = {
    broken = {
        type = "magazine",
        modifiers = {
            ["ammo.clipSize"] = {set = "not-a-number"},
            ["physics.projectile.model"] = {set = 42}
        }
    }
}
]], {name = "core-invalid-modifier"})
assert(invalidModifier.report:HasErrors(), "invalid attachment modifier types were accepted")

local invalidNestedModifier = FTBase.Compiler.CompileSource([[
FT.Attachments.Slots = {
    {id = "barrel", type = "barrel"}
}
FT.Attachments.Definitions = {
    broken = {
        type = "barrel",
        modifiers = {
            ["physics.projectile"] = {set = {model = 42}}
        }
    }
}
]], {name = "core-invalid-nested-modifier"})
assert(invalidNestedModifier.report:HasErrors(), "invalid nested attachment modifier was accepted")

local invalidAttachmentVisual = FTBase.Compiler.CompileSource([[
FT.Attachments.Slots = {{id = "optic", type = "optic"}}
FT.Attachments.Definitions = {
    broken = {
        type = "optic",
        icon = 42,
        visuals = {view = {model = ""}}
    }
}
]], {name = "core-invalid-attachment-visual"})
assert(invalidAttachmentVisual.report:HasErrors(), "invalid attachment visual descriptor was accepted")

local visualSource = FTBase.Compiler.CompileSource([[
FT.Attachments.Slots = {{id = "optic", type = "optic"}}
FT.Attachments.Definitions = {
    sight = {
        type = "optic",
        icon = "ft_base/providers/tfa/inspectionhud/qmark",
        visuals = {
            view = {model = "models/weapons/c_pistol.mdl", pos = Vector(1, 2, 3), ang = Angle(0, 0, 0)}
        }
    }
}
]], {name = "core-attachment-visual-source"})
assert(not visualSource.report:HasErrors(), visualSource.report:ToString())

local metadataSource = FTBase.Compiler.CompileSource([[
using "TFA"
TFA.Description = "Inspect description"
TFA.InspectTitle = "Inspection"
TFA.InspectType = "Rifle"
TFA.InspectStats = {damage = {label = "Damage", value = 31}}
TFA.InspectFalloff = {min = 10, max = 100}
TFA.Customization.Title = "Customize"
TFA.Customization.Presets = {"default"}
TFA.Attachments = {
    {id = "optic", type = "optic", PrintName = "Optic", ShortName = "OPT", Folder = "Sights"}
}
TFA.AttachmentDefinitions = {
    reflex = {
        type = "optic",
        PrintName = "Reflex",
        ShortName = "RFX",
        Category = "Optics",
        Folder = "Sights",
        Description = {"Clear sight picture"},
        Pros = {"Faster ADS"},
        Cons = {"More sway"},
        Trivia = {"Test metadata"},
        Credits = {"F&T"},
        Stats = {ads = -0.1},
        ToggleStats = {enabled = true},
        SliderValues = {zoom = {minimum = 1, maximum = 4}}
    }
}
]], {name = "core-provider-metadata"})
assert(not metadataSource.report:HasErrors(), metadataSource.report:ToString())
assert(metadataSource.ir.ui.inspect.title == "Inspection", "inspect title metadata was not mapped")
assert(metadataSource.ir.ui.customization.title == "Customize", "customization title metadata was not mapped")
assert(metadataSource.ir.attachments.slots[1].name == "Optic", "slot PrintName was not normalized")
assert(metadataSource.ir.attachments.slots[1].shortName == "OPT", "slot ShortName was not normalized")
assert(metadataSource.ir.attachments.slots[1].folder == "Sights", "slot Folder was not normalized")
assert(metadataSource.ir.attachments.definitions.reflex.name == "Reflex", "definition PrintName was not normalized")
assert(metadataSource.ir.attachments.definitions.reflex.pros[1] == "Faster ADS", "definition Pros metadata was not normalized")
assert(metadataSource.ir.attachments.definitions.reflex.toggles.enabled == true,
    "definition ToggleStats metadata was not normalized")
assert(metadataSource.ir.attachments.definitions.reflex.sliders.zoom.maximum == 4,
    "definition SliderValues metadata was not normalized")

local invalidProviderMetadata = FTBase.Compiler.CompileSource([[
FT.UI.Inspect.Blur = "yes"
FT.Attachments.Slots = {
    {id = "optic", name = 42}
}
FT.Attachments.Definitions = {
    reflex = {type = "optic", stats = "not-a-table", toggles = 7}
}
]], {name = "core-invalid-provider-metadata"})
assert(invalidProviderMetadata.report:HasErrors(), "invalid provider metadata was accepted")

local invalidProjectile = FTBase.Compiler.CompileSource([[
FT.Ballistics.Mode = "projectile"
]], {name = "core-invalid-projectile"})
assert(invalidProjectile.report:HasErrors(), "projectile without a positive muzzle velocity was accepted")

local duplicateUsing = FTBase.Compiler.CompileSource([[
using "TFA"
using "tfa"
Primary.Damage = 31
]], {name = "core-duplicate-using"})
assert(not duplicateUsing.report:HasErrors(), duplicateUsing.report:ToString())
assert(duplicateUsing.ir.damage.base == 31, "duplicate using changed resolution")

local aliasPriority = FTBase.Compiler.CompileSource([[
using "TFA"
FT.Priority = {"TFA_BASE", "tfa"}
TFA.Primary.Damage = 32
]], {name = "core-alias-priority"})
assert(not aliasPriority.report:HasErrors(), aliasPriority.report:ToString())
assert(#aliasPriority.ir.developer.priority == 1, "priority aliases were not deduplicated")
assert(aliasPriority.ir.developer.priority[1] == "TFA", "priority alias was not canonicalized")

local visualOwnership = FTBase.Compiler.CompileSource([[
using "TFA"
using "MW"
TFA.Primary.ClipSize = 30
MW.Customization.Provider = "mw"
]], {name = "core-visual-ownership"})
assert(not visualOwnership.report:HasErrors(), visualOwnership.report:ToString())
assert(visualOwnership.ir.ui.visual.providers.hud == "tfa",
    "Customization provider incorrectly claimed HUD ownership")

local caseInsensitiveVisual = FTBase.Compiler.CompileSource([[
using "TFA"
ft.visual.hud = "TacRP"
TFA.Primary.ClipSize = 30
]], {name = "core-visual-case"})
assert(not caseInsensitiveVisual.report:HasErrors(), caseInsensitiveVisual.report:ToString())
assert(caseInsensitiveVisual.ir.ui.visual.providers.hud == "tacrp",
    "Case-insensitive FT visual config was ignored")

local duplicateSlots = FTBase.Compiler.CompileTable({
    Attachments = {
        Slots = {
            {id = "optic", type = "optic"},
            {id = "optic", type = "optic"}
        }
    }
}, {namespace = "FT", report = FTBase.Report.New("core-attachments")})
assert(duplicateSlots.report:HasErrors(), "duplicate attachment slots were accepted")

withCompilerLimit("maxAttachmentSlots", 1, function()
    local tooManySlots = FTBase.Compiler.CompileSource([[
FT.Attachments.Slots = {
    {id = "optic", type = "optic"},
    {id = "muzzle", type = "muzzle"}
}
]], {name = "core-slot-limit"})
    assert(tooManySlots.report:HasErrors(), "attachment slot limit was not enforced")
end)

withCompilerLimit("maxAttachmentDefinitions", 1, function()
    local tooManyDefinitions = FTBase.Compiler.CompileSource([[
FT.Attachments.Definitions = {
    first = {type = "optic"},
    second = {type = "optic"}
}
]], {name = "core-definition-limit"})
    assert(tooManyDefinitions.report:HasErrors(), "attachment definition limit was not enforced")
end)

print("F&T core regression tests passed")
return true
