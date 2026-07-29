if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "tacrp_eo_masada"
SWEP.PrintName = "F&T Native Template - TacRP Masada"
SWEP.Category = "F&T Native Templates / TacRP"
SWEP.Spawnable = true
SWEP.AdminOnly = false

local nativeDependency = {
    id = "tacrp",
    dialect = "TacRP",
    templateClass = "ft_native_template_tacrp",
    sampleClass = "tacrp_eo_masada",
    baseClass = "tacrp_base",
    required = true,
    requiredClasses = {"tacrp_base", "tacrp_eo_masada"},
    workshop = {
        {id = "3734712166", role = "base"},
        {id = "3271554982", role = "sample"}
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
