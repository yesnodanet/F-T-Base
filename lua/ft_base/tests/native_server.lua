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

local dependencyCheck = Compat.Check()
assert(dependencyCheck.ok, Compat.FormatDiagnostics(dependencyCheck))

for _, entry in ipairs(manifest) do
    assert(type(entry.templateClass) == "string", "native manifest entry has no template class")
    assert(stored(entry.templateClass) ~= nil,
        "native template class was not registered: " .. entry.templateClass)

    for _, requiredClass in ipairs(entry.requiredClasses or {}) do
        assert(stored(requiredClass) ~= nil,
            "native dependency class was not registered: " .. requiredClass)
    end

    local weapon = ents.Create(entry.templateClass)
    assert(IsValid(weapon), "native template could not be created: " .. entry.templateClass)

    local spawned, spawnError = pcall(function()
        weapon:Spawn()
        weapon:Activate()
    end)

    local stillValid = IsValid(weapon)
    if stillValid then
        weapon:Remove()
    end

    assert(spawned and stillValid,
        "native template could not be spawned: " .. entry.templateClass .. " (" .. tostring(spawnError) .. ")")
end

print("F&T native dependency server test passed")

return true
