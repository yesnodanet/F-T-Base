local Compat = assert(FTBase.Compat, "FTBase.Compat was not loaded")

local manifest = Compat.GetManifest()
assert(type(manifest) == "table" and #manifest >= 6,
    "native dependency manifest must contain six dialects")

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

local function assertArrayEquals(actual, expectedValues, message)
    assert(type(actual) == "table", message .. " must be an array")
    assert(#actual == #expectedValues, message .. " has the wrong number of entries")

    for index, expectedValue in ipairs(expectedValues) do
        assert(actual[index] == expectedValue,
            message .. " has the wrong entry at " .. index)
    end
end

for id, values in pairs(expected) do
    local template = assert(Compat.GetNativeTemplate(id), "missing native template " .. id)
    local clientRequiredClasses = {values.base}

    if id == "arc9" then
        clientRequiredClasses[#clientRequiredClasses + 1] = "arc9_go_base"
    end

    if values.sample then
        clientRequiredClasses[#clientRequiredClasses + 1] = values.sample
    end

    assert(template.required == true, id .. " must declare its client UI dependency")
    assert(template.clientOnly == true and template.uiOnly == true,
        id .. " must limit the external base to client UI")
    assert(template.requiredOnServer == false,
        id .. " must not require vendor classes on the dedicated server")
    assert(template.gameplayOwner == "ft" and template.statsOwner == "ft"
        and template.networkingOwner == "ft",
        id .. " must retain F&T gameplay, stats, and networking")
    assert(template.baseClass == values.base, id .. " has the wrong UI base class")
    assert(template.sampleClass == values.sample, id .. " has the wrong UI sample class")
    assertArrayEquals(template.clientRequiredClasses, clientRequiredClasses,
        id .. " has the wrong client UI class manifest")
    assertArrayEquals(template.serverRequiredClasses, {},
        id .. " must have no dedicated-server vendor class requirements")
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

local ready = Compat.CheckNativeTemplate("tfa", "client")
assert(ready.ok and ready.status == "ready", "available client UI dependencies were rejected")
assert(#ready.missing == 0 and #ready.available == 2,
    "ready client UI check has the wrong dependency counts")

weapons = {
    GetStored = function()
        return nil
    end
}

local serverReady = Compat.CheckNativeTemplate("tfa", "server")
assert(serverReady.ok and serverReady.status == "ready",
    "server mode must not require client-only vendor UI classes")
assert(#serverReady.missing == 0 and #serverReady.available == 0,
    "server mode unexpectedly inspected vendor UI classes")

local missing = Compat.CheckNativeTemplate("tfa", "client")
assert(not missing.ok and missing.status == "missing_dependency",
    "missing client UI dependency was not reported")
assert(#missing.missing == 2 and #missing.diagnostics == 2,
    "missing client UI dependency diagnostics are incomplete")
assert(string.find(missing.diagnostic, "tfa_gun_base", 1, true),
    "missing client UI dependency diagnostic did not name the base class")

weapons = oldWeapons

local unknown = Compat.CheckNativeTemplate("does_not_exist", "client")
assert(not unknown.ok and unknown.status == "unknown_template", "unknown native template was accepted")
assert(string.find(unknown.diagnostic, "does_not_exist", 1, true),
    "unknown template diagnostic did not include the requested id")

local inline = Compat.CheckDependencies({
    id = "inline",
    clientRequiredClasses = {"inline_client"},
    serverRequiredClasses = {}
}, "server")
assert(inline.ok and inline.status == "ready" and #inline.missing == 0,
    "inline server dependency checks must ignore client-only classes")

local all = Compat.Check("server")
assert(all.ok and type(all.results) == "table" and #all.results >= 6,
    "aggregate server dependency check rejected client-only vendor classes")
assert(type(all.byId.tfa) == "table" and type(all.diagnostics) == "table",
    "aggregate native dependency check omitted diagnostics")

print("F&T native compatibility registry tests passed")

return true
