-- Dedicated-server checks for the temporary native template mode.

local Compat = assert(FTBase.Compat, "FTBase.Compat was not loaded")
local manifest = Compat.GetManifest()

assert(type(manifest) == "table" and #manifest == 6,
    "native server test requires all six native template entries")
assert(type(weapons) == "table" and type(weapons.GetStored) == "function",
    "the Garry's Mod weapon registry is unavailable")
assert(type(ents) == "table" and type(ents.Create) == "function",
    "the Garry's Mod entity factory is unavailable")

local function stored(className)
    local ok, value = pcall(weapons.GetStored, className)

    if ok and value ~= nil then
        return value
    end

    ok, value = pcall(weapons.GetStored, weapons, className)
    return ok and value or nil
end

local dependencyCheck = Compat.Check(nil, "server")
assert(dependencyCheck.ok, Compat.FormatDiagnostics(dependencyCheck))

for _, entry in ipairs(manifest) do
    assert(type(entry.templateClass) == "string", "native manifest entry has no template class")
    assert(entry.requiredOnServer == false and entry.clientOnly == true and entry.uiOnly == true,
        "native template must keep vendor UI dependencies client-only: " .. entry.templateClass)
    assert(type(entry.serverRequiredClasses) == "table" and #entry.serverRequiredClasses == 0,
        "native template unexpectedly requires a vendor class on the server: " .. entry.templateClass)
    assert(type(entry.clientRequiredClasses) == "table" and #entry.clientRequiredClasses > 0,
        "native template is missing client UI dependency metadata: " .. entry.templateClass)

    local definition = stored(entry.templateClass)
    assert(definition ~= nil,
        "native template class was not registered: " .. entry.templateClass)
    assert(definition.Base == "ft_base",
        "native template must inherit the F&T base: " .. entry.templateClass)
    assert(type(definition.FTSource) == "string" and definition.FTSource ~= "",
        "native template is missing its F&T source: " .. entry.templateClass)

    for _, requiredClass in ipairs(entry.serverRequiredClasses or {}) do
        assert(stored(requiredClass) ~= nil,
            "required server class was not registered: " .. requiredClass)
    end

    local weapon = ents.Create(entry.templateClass)
    assert(IsValid(weapon), "native template could not be created: " .. entry.templateClass)

    local spawned, spawnError = pcall(function()
        weapon:Spawn()
        weapon:Activate()
    end)

    local stillValid = IsValid(weapon)
    local runtime = stillValid and weapon.FTRuntime or nil
    if stillValid then
        weapon:Remove()
    end

    assert(spawned and stillValid,
        "native template could not be spawned: " .. entry.templateClass .. " (" .. tostring(spawnError) .. ")")
    assert(runtime ~= nil,
        "native template did not initialize the F&T runtime: " .. entry.templateClass)
end

print("F&T native dependency server test passed")

return true
