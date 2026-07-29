local Compat = assert(FTBase.Compat, "FTBase.Compat was not loaded")

local manifest = Compat.GetManifest()
assert(type(manifest) == "table" and #manifest >= 6, "native dependency manifest must contain six dialects")
local manifestById = Compat.GetManifestById()
assert(type(manifestById) == "table" and type(manifestById.tfa) == "table",
    "native dependency manifest must also be addressable by dialect id")

local expected = {
    tfa = {base = "tfa_gun_base", sample = "tfa_ins2_cw_ar15", workshop = "2840031720"},
    arc9 = {base = "arc9_base", sample = "arc9_go_ak47", workshop = "2910505837"},
    arccw = {base = "arccw_base", sample = "arccw_go_ak47", workshop = "2131057232"},
    mw = {base = "mg_base", sample = "mg_mike4", workshop = "2459720887"},
    tacrp = {base = "tacrp_base", sample = "tacrp_eo_masada", workshop = "3734712166"},
    swb = {base = "swb_base", sample = nil, workshop = "1967187358"}
}

for id, values in pairs(expected) do
    local template = assert(Compat.GetNativeTemplate(id), "missing native template " .. id)
    assert(template.required == true, id .. " must require its external base")
    assert(template.baseClass == values.base, id .. " has the wrong base class")
    assert(template.sampleClass == values.sample, id .. " has the wrong sample class")
    assert(template.workshopIds[1] == values.workshop, id .. " has the wrong base Workshop ID")
    assert(Compat.GetNativeTemplate(template.templateClass) == template,
        id .. " must be addressable by template class")
end

local oldWeapons = rawget(_G, "weapons")
local available = {
    tfa_gun_base = {Class = "tfa_gun_base"},
    tfa_ins2_cw_ar15 = {Class = "tfa_ins2_cw_ar15"}
}

weapons = {
    GetStored = function(className)
        return available[className]
    end
}

local ready = Compat.CheckNativeTemplate("tfa")
assert(ready.ok and ready.status == "ready", "available native dependencies were rejected")
assert(#ready.missing == 0 and #ready.available == 2, "ready native check has the wrong dependency counts")

weapons = {
    GetStored = function()
        return nil
    end
}

local missing = Compat.CheckNativeTemplate("tfa")
assert(not missing.ok and missing.status == "missing_dependency", "missing native dependency was not reported")
assert(#missing.missing == 2 and #missing.diagnostics == 2,
    "missing native dependency diagnostics are incomplete")
assert(string.find(missing.diagnostic, "tfa_gun_base", 1, true),
    "missing dependency diagnostic did not name the base class")

weapons = oldWeapons

local unknown = Compat.CheckNativeTemplate("does_not_exist")
assert(not unknown.ok and unknown.status == "unknown_template", "unknown native template was accepted")
assert(string.find(unknown.diagnostic, "does_not_exist", 1, true),
    "unknown template diagnostic did not include the requested id")

local inline = Compat.CheckDependencies({
    id = "inline",
    baseClass = "inline_base"
})
assert(not inline.ok and inline.status == "missing_dependency"
    and inline.missing[1] == "inline_base",
    "inline native dependency checks were not supported")

local all = Compat.Check()
assert(type(all.results) == "table" and #all.results >= 6,
    "aggregate native dependency check returned fewer than six templates")
assert(type(all.byId.tfa) == "table" and type(all.diagnostics) == "table",
    "aggregate native dependency check omitted diagnostics")

print("F&T native compatibility registry tests passed")

return true
