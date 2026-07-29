FTBase = FTBase or {}

FTBase.Compat = FTBase.Compat or {}

local Table = FTBase.Util and FTBase.Util.Table
local copy = Table and Table.DeepCopy or function(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}

    for key, item in pairs(value) do
        result[copy(key)] = copy(item)
    end

    return result
end

local Compat = FTBase.Compat

if FTBase.Module and FTBase.Module.Define then
    Compat = FTBase.Module.Define("Compat", Compat)
    FTBase.Compat = Compat
end

Compat.NativeTemplates = Compat.NativeTemplates or {}
Compat.NativeTemplateOrder = Compat.NativeTemplateOrder or {}

local byId = Compat.NativeTemplates
local order = Compat.NativeTemplateOrder

local function normalizeWorkshop(entry)
    if type(entry) == "string" or type(entry) == "number" then
        return {
            id = tostring(entry)
        }
    end

    if type(entry) ~= "table" then
        return nil
    end

    local result = copy(entry)

    if result.id ~= nil then
        result.id = tostring(result.id)
    end

    return result
end

local function normalize(spec, idHint)
    if type(spec) ~= "table" then
        spec = {}
    end

    local result = copy(spec)
    result.id = result.id or result.name or idHint or result.templateClass or result.class
    result.templateClass = result.templateClass or result.class
    result.class = result.class or result.templateClass
    result.sampleClass = result.sampleClass or result.sourceClass
    result.baseClass = result.baseClass or result.base

    if result.id ~= nil then
        result.id = tostring(result.id)
    end

    if result.templateClass ~= nil then
        result.templateClass = tostring(result.templateClass)
    end

    if result.sampleClass ~= nil then
        result.sampleClass = tostring(result.sampleClass)
    end

    if result.baseClass ~= nil then
        result.baseClass = tostring(result.baseClass)
    end

    local required = {}
    local seen = {}

    local function addRequired(className)
        if type(className) ~= "string" or className == "" or seen[className] then
            return
        end

        seen[className] = true
        required[#required + 1] = className
    end

    for _, className in ipairs(result.requiredClasses or {}) do
        addRequired(className)
    end

    for _, className in ipairs(result.baseClasses or result.baseChain or {}) do
        addRequired(className)
    end

    addRequired(result.baseClass)
    addRequired(result.sampleClass)
    result.requiredClasses = required

    local workshop = {}

    for _, entry in ipairs(result.workshop or result.workshopItems or {}) do
        local normalized = normalizeWorkshop(entry)

        if normalized then
            workshop[#workshop + 1] = normalized
        end
    end

    result.workshop = workshop
    result.workshopItems = copy(workshop)

    local workshopIds = {}

    for _, entry in ipairs(workshop) do
        if entry.id then
            workshopIds[#workshopIds + 1] = entry.id
        end
    end

    result.workshopIds = workshopIds

    return result
end

local function findId(idOrTemplate)
    if type(idOrTemplate) == "table" then
        return idOrTemplate.id or idOrTemplate.name or idOrTemplate.templateClass or idOrTemplate.class
    end

    if type(idOrTemplate) ~= "string" then
        return nil
    end

    if byId[idOrTemplate] then
        return idOrTemplate
    end

    for _, id in ipairs(order) do
        local template = byId[id]

        if template and (template.templateClass == idOrTemplate or template.class == idOrTemplate) then
            return id
        end
    end

    return idOrTemplate
end

local function mergeInto(target, source)
    for key, value in pairs(source or {}) do
        if key ~= "order" then
            target[key] = copy(value)
        end
    end

    if target.requiredClasses == nil then
        target.requiredClasses = {}
    end

    return normalize(target, target.id)
end

function Compat.RegisterNativeTemplate(specOrId, metadata)
    local idHint
    local spec

    if type(specOrId) == "string" then
        idHint = specOrId
        spec = metadata or {}
    elseif type(specOrId) == "table" then
        spec = specOrId
    else
        return nil, "native template specification must be a table or id string"
    end

    local normalized = normalize(spec, idHint)

    if type(normalized.id) ~= "string" or normalized.id == "" then
        return nil, "native template is missing id"
    end

    local id = byId[normalized.id] and normalized.id or findId(normalized.templateClass)
    local current = id and byId[id] or nil

    if current then
        normalized = mergeInto(current, normalized)
    end

    normalized.id = normalized.id or id
    byId[normalized.id] = normalized

    if not current then
        order[#order + 1] = normalized.id
    elseif normalized.id ~= id then
        byId[id] = nil

        for index, existingId in ipairs(order) do
            if existingId == id then
                order[index] = normalized.id
                break
            end
        end
    end

    if Compat.GetManifest then
        Compat.Manifest = Compat.GetManifest()

        if Compat.GetManifestById then
            Compat.ManifestById = Compat.GetManifestById()
        end
    end

    return normalized
end

function Compat.GetNativeTemplate(idOrTemplate)
    local id = findId(idOrTemplate)

    if not id then
        return nil
    end

    return byId[id]
end

function Compat.GetAllNativeTemplates()
    local result = {}

    for _, id in ipairs(order) do
        if byId[id] then
            result[#result + 1] = byId[id]
        end
    end

    return result
end

Compat.GetNativeTemplates = Compat.GetAllNativeTemplates

local function resolveWeaponClass(className)
    if type(className) ~= "string" or className == "" then
        return nil
    end

    local libraries = {
        rawget(_G, "weapons"),
        rawget(_G, "scripted_ents")
    }

    for _, library in ipairs(libraries) do
        if type(library) == "table" then
            for _, methodName in ipairs({"GetStored", "Get"}) do
                local method = library[methodName]

                if type(method) == "function" then
                    local ok, value = pcall(method, className)

                    if ok and value ~= nil and value ~= false then
                        return value
                    end

                    ok, value = pcall(method, library, className)

                    if ok and value ~= nil and value ~= false then
                        return value
                    end
                end
            end

            local listMethod = library.GetList

            if type(listMethod) == "function" then
                local ok, values = pcall(listMethod)

                if not ok then
                    ok, values = pcall(listMethod, library)
                end

                if ok and type(values) == "table" then
                    for _, value in ipairs(values) do
                        if type(value) == "table"
                            and (value.Class == className
                                or value.ClassName == className
                                or value.class == className) then
                            return value
                        end
                    end
                end
            end
        end
    end

    return nil
end

function Compat.IsWeaponClassAvailable(className)
    return resolveWeaponClass(className) ~= nil
end

Compat.HasBaseClass = Compat.IsWeaponClassAvailable
Compat.IsDependencyAvailable = Compat.IsWeaponClassAvailable

local function checkResult(template, id)
    local result = {
        ok = true,
        status = "ready",
        id = id,
        templateClass = template and template.templateClass or nil,
        baseClass = template and template.baseClass or nil,
        sampleClass = template and template.sampleClass or nil,
        requiredClasses = template and copy(template.requiredClasses or {}) or {},
        workshop = template and copy(template.workshop or {}) or {},
        workshopIds = template and copy(template.workshopIds or {}) or {},
        available = {},
        missing = {},
        missingBaseClasses = {},
        missingSampleClasses = {},
        missingDependencies = {},
        diagnostics = {},
        messages = {}
    }

    if not template then
        result.ok = false
        result.status = "unknown_template"
        result.diagnostic = "Unknown native template: " .. tostring(id)
        result.diagnostics[#result.diagnostics + 1] = result.diagnostic
        result.messages[#result.messages + 1] = result.diagnostic
        return result
    end

    for _, className in ipairs(template.requiredClasses or {}) do
        if Compat.IsWeaponClassAvailable(className) then
            result.available[#result.available + 1] = className
        else
            result.ok = false
            result.status = "missing_dependency"
            result.missing[#result.missing + 1] = className
            result.missingDependencies[#result.missingDependencies + 1] = className

            if className == template.baseClass then
                result.missingBaseClasses[#result.missingBaseClasses + 1] = className
            elseif className == template.sampleClass then
                result.missingSampleClasses[#result.missingSampleClasses + 1] = className
            else
                local isBaseClass = false

                for _, baseClass in ipairs(template.baseClasses or template.baseChain or {}) do
                    if className == baseClass then
                        isBaseClass = true
                        break
                    end
                end

                if isBaseClass then
                    result.missingBaseClasses[#result.missingBaseClasses + 1] = className
                end
            end

            local message = string.format(
                "Native template %s requires unavailable weapon class %s",
                tostring(template.id),
                className
            )
            result.diagnostics[#result.diagnostics + 1] = message
            result.messages[#result.messages + 1] = message
        end
    end

    if result.ok then
        result.diagnostic = "Native template " .. tostring(template.id) .. " dependencies are available"
        result.diagnostics[#result.diagnostics + 1] = result.diagnostic
        result.messages[#result.messages + 1] = result.diagnostic
    else
        result.diagnostic = table.concat(result.diagnostics, "; ")
    end

    return result
end

function Compat.CheckNativeTemplate(idOrTemplate)
    local id = findId(idOrTemplate)
    local template = Compat.GetNativeTemplate(id)

    if not template and type(idOrTemplate) == "table" then
        template = normalize(idOrTemplate, id)
        id = template.id
    end

    return checkResult(template, id)
end

Compat.CheckDependencies = Compat.CheckNativeTemplate

function Compat.CheckAll()
    local result = {
        ok = true,
        status = "ready",
        results = {},
        byId = {},
        missing = {},
        diagnostics = {}
    }

    for _, id in ipairs(order) do
        local check = Compat.CheckNativeTemplate(id)
        result.results[#result.results + 1] = check
        result.byId[id] = check

        if not check.ok then
            result.ok = false
            result.status = "missing_dependency"
            result.missing[#result.missing + 1] = id
        end

        for _, message in ipairs(check.diagnostics or {}) do
            result.diagnostics[#result.diagnostics + 1] = message
        end
    end

    result.diagnostic = table.concat(result.diagnostics, "; ")
    return result
end

Compat.CheckAllNativeTemplates = Compat.CheckAll

function Compat.Check(idOrTemplate)
    if idOrTemplate == nil then
        return Compat.CheckAll()
    end

    return Compat.CheckNativeTemplate(idOrTemplate)
end

function Compat.FormatDiagnostics(result)
    if type(result) ~= "table" then
        return tostring(result)
    end

    if type(result.diagnostic) == "string" and result.diagnostic ~= "" then
        return result.diagnostic
    end

    return table.concat(result.diagnostics or {}, "; ")
end

Compat.GetDiagnostics = Compat.CheckNativeTemplate

function Compat.GetManifest()
    local result = {}

    for _, id in ipairs(order) do
        if byId[id] then
            result[#result + 1] = copy(byId[id])
        end
    end

    return result
end

function Compat.GetManifestEntry(idOrTemplate)
    local template = Compat.GetNativeTemplate(idOrTemplate)
    return template and copy(template) or nil
end

function Compat.GetManifestById()
    local result = {}

    for _, id in ipairs(order) do
        if byId[id] then
            result[id] = copy(byId[id])
        end
    end

    return result
end

Compat.GetDependencyManifest = Compat.GetManifest
Compat.GetNativeManifest = Compat.GetManifest
Compat.Manifest = Compat.GetManifest()
Compat.ManifestById = Compat.GetManifestById()

local defaults = {
    {
        id = "tfa",
        dialect = "TFA",
        templateClass = "ft_native_template_tfa",
        sampleClass = "tfa_ins2_cw_ar15",
        baseClass = "tfa_gun_base",
        required = true,
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
    },
    {
        id = "arc9",
        dialect = "ARC9",
        templateClass = "ft_native_template_arc9",
        sampleClass = "arc9_go_ak47",
        baseClass = "arc9_base",
        required = true,
        baseClasses = {"arc9_go_base"},
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
    },
    {
        id = "arccw",
        dialect = "ArcCW",
        templateClass = "ft_native_template_arccw",
        sampleClass = "arccw_go_ak47",
        baseClass = "arccw_base",
        required = true,
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
    },
    {
        id = "mw",
        dialect = "MW",
        templateClass = "ft_native_template_mw",
        sampleClass = "mg_mike4",
        baseClass = "mg_base",
        required = true,
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
    },
    {
        id = "tacrp",
        dialect = "TacRP",
        templateClass = "ft_native_template_tacrp",
        sampleClass = "tacrp_eo_masada",
        baseClass = "tacrp_base",
        required = true,
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
    },
    {
        id = "swb",
        dialect = "SWB",
        templateClass = "ft_native_template_swb",
        baseClass = "swb_base",
        required = true,
        workshop = {
            {id = "1967187358", role = "base"}
        },
        capabilities = {
            hud = true,
            ads = true,
            inspect = false,
            customization = false,
            attachments = false,
            presentation = true
        }
    }
}

for _, spec in ipairs(defaults) do
    Compat.RegisterNativeTemplate(spec)
end

Compat.Manifest = Compat.GetManifest()
Compat.ManifestById = Compat.GetManifestById()
