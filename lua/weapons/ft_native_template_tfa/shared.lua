if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "tfa_ins2_cw_ar15"
SWEP.PrintName = "F&T Native Template - TFA AR-15"
SWEP.Category = "F&T Native Templates / TFA"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.AdminSpawnable = true

local nativeDependency = {
    id = "tfa",
    dialect = "TFA",
    templateClass = "ft_native_template_tfa",
    sampleClass = "tfa_ins2_cw_ar15",
    baseClass = "tfa_gun_base",
    required = true,
    requiredClasses = {"tfa_gun_base", "tfa_ins2_cw_ar15"},
    workshop = {
        {id = "2840031720", role = "base"},
        {id = "1676032134", role = "sample"}
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
