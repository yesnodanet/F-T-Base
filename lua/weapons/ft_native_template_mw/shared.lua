if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "mg_mike4"
SWEP.PrintName = "F&T Native Template - MW M4A1"
SWEP.Category = "F&T Native Templates / Modern Warfare"
SWEP.Spawnable = true
SWEP.AdminOnly = false

-- MW Base reads Zoom from the raw stored weapon table during Initialize.
-- GMod inheritance exposes it on the entity but not on that table, so retain
-- the sample weapon's values on this lightweight native fixture.
SWEP.Zoom = {
    IdleSway = 0.1,
    FovMultiplier = 0.95,
    ViewModelFovMultiplier = 1,
    Blur = {
        EyeFocusDistance = 6.5
    }
}

local function syncNativeSampleTables()
    if type(weapons) ~= "table" or type(weapons.GetStored) ~= "function"
        or type(table) ~= "table" or type(table.Copy) ~= "function" then
        return
    end

    local sample = weapons.GetStored("mg_mike4")
    local native = weapons.GetStored("ft_native_template_mw")

    if type(sample) ~= "table" or type(native) ~= "table" then
        return
    end

    -- MW Base reads these fields back from its raw stored weapon table while
    -- constructing the customized gun; normal GMod inheritance does not copy
    -- them to a derived stored table.
    if native.Customization == nil and type(sample.Customization) == "table" then
        native.Customization = table.Copy(sample.Customization)
    end

    if native.Animations == nil and type(sample.Animations) == "table" then
        native.Animations = table.Copy(sample.Animations)
    end
end

if type(hook) == "table" and type(hook.Add) == "function" then
    hook.Add("InitPostEntity", "FTNativeTemplateMWSampleTables", syncNativeSampleTables)
end

local nativeDependency = {
    id = "mw",
    dialect = "MW",
    templateClass = "ft_native_template_mw",
    sampleClass = "mg_mike4",
    baseClass = "mg_base",
    required = true,
    requiredClasses = {"mg_base", "mg_mike4"},
    workshop = {
        {id = "2459720887", role = "base"},
        {id = "2528829149", role = "sample"}
    },
    capabilities = {
        hud = true,
        inspect = true,
        customization = true,
        attachments = true,
        presentation = true
    }
}

SWEP.FTNative = true
SWEP.FTNativeDialect = nativeDependency.dialect
SWEP.FTNativeDependency = nativeDependency

if type(FTBase) == "table"
    and type(FTBase.Compat) == "table"
    and type(FTBase.Compat.RegisterNativeTemplate) == "function" then
    FTBase.Compat.RegisterNativeTemplate(nativeDependency)
end
