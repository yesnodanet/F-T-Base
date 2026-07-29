if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "arc9_go_ak47"
SWEP.PrintName = "F&T Native Template - ARC9 AK-47"
SWEP.Category = "F&T Native Templates / ARC9"
SWEP.Spawnable = true
SWEP.AdminOnly = false

local nativeDependency = {
    id = "arc9",
    dialect = "ARC9",
    templateClass = "ft_native_template_arc9",
    sampleClass = "arc9_go_ak47",
    baseClass = "arc9_base",
    required = true,
    requiredClasses = {"arc9_base", "arc9_go_ak47"},
    workshop = {
        {id = "2910505837", role = "base"},
        {id = "2910537020", role = "sample"}
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
