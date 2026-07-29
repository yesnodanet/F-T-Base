if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "arccw_go_ak47"
SWEP.PrintName = "F&T Native Template - ArcCW AKM"
SWEP.Category = "F&T Native Templates / ArcCW"
SWEP.Spawnable = true
SWEP.AdminOnly = false

local nativeDependency = {
    id = "arccw",
    dialect = "ArcCW",
    templateClass = "ft_native_template_arccw",
    sampleClass = "arccw_go_ak47",
    baseClass = "arccw_base",
    required = true,
    requiredClasses = {"arccw_base", "arccw_go_ak47"},
    workshop = {
        {id = "2131057232", role = "base"},
        {id = "2257255110", role = "sample"}
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
