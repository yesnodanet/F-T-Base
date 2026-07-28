FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Resolver = {}

local Path = FTBase.Util.Path
local Table = FTBase.Util.Table

local function clonePath(path)
    return Table.DeepCopy(path or {})
end

local function normalizeNamespace(namespace)
    return string.lower(tostring(namespace or ""))
end

local function makeRank(priority)
    local rank = {}
    local count = #priority

    for index, name in ipairs(priority) do
        rank[normalizeNamespace(name)] = count - index + 1
    end

    return rank
end

local validProviders = {
    ft = true,
    tfa = true,
    swb = true,
    mw = true,
    arc9 = true,
    arccw = true,
    tacrp = true
}

local function normalizeProvider(provider)
    provider = string.lower(tostring(provider or ""))

    if validProviders[provider] then
        return provider
    end

    return nil
end

local Context = {}
Context.__index = Context

function Context.New(report, config)
    return setmetatable({
        report = report,
        config = config,
        operations = {}
    }, Context)
end

function Context:GetMergeStrategy(source, externalPath, irPath, fallback)
    local merge = self.config.merge or {}

    return merge[irPath] or merge[source .. "." .. externalPath] or fallback or "override"
end

function Context:Emit(source, externalPath, irPath, value, strategy, node)
    self.operations[#self.operations + 1] = {
        source = source,
        externalPath = externalPath,
        irPath = irPath,
        value = Table.DeepCopy(value),
        strategy = self:GetMergeStrategy(source, externalPath, irPath, strategy),
        node = node,
        order = #self.operations + 1
    }
end

function Resolver.RegisterAdapter(adapter)
    FTBase.Compiler.Adapters = FTBase.Compiler.Adapters or {}
    FTBase.Compiler.AdapterAliases = FTBase.Compiler.AdapterAliases or {}

    FTBase.Compiler.Adapters[adapter.Name] = adapter
    FTBase.Compiler.AdapterAliases[normalizeNamespace(adapter.Name)] = adapter

    for _, alias in ipairs(adapter.Aliases or {}) do
        FTBase.Compiler.AdapterAliases[normalizeNamespace(alias)] = adapter
    end
end

function Resolver.GetAdapter(name)
    FTBase.Compiler.AdapterAliases = FTBase.Compiler.AdapterAliases or {}
    return FTBase.Compiler.AdapterAliases[normalizeNamespace(name)]
end

local function canonicalNamespaces(values, report, label)
    local result = {}
    local seen = {}

    if values == nil then
        return result
    end

    if type(values) ~= "table" or not Table.IsArray(values) then
        report:AddError(tostring(label) .. " must be an array of namespace names")
        return result
    end

    for index, namespace in ipairs(values) do
        local adapter = type(namespace) == "string" and Resolver.GetAdapter(namespace) or nil

        if not adapter then
            report:AddError(
                "Unknown namespace '" .. tostring(namespace) .. "' in " .. tostring(label) .. " at index " .. tostring(index)
            )
        else
            local key = normalizeNamespace(adapter.Name)

            if not seen[key] then
                seen[key] = true
                result[#result + 1] = adapter.Name
            end
        end
    end

    return result
end

local function stripSWEP(path)
    if path[1] == "SWEP" then
        local stripped = {}

        for index = 2, #path do
            stripped[#stripped + 1] = path[index]
        end

        return stripped
    end

    return path
end

local function readConfig(ast, report)
    local config = {
        priority = {},
        merge = {},
        customizationProvider = nil,
        visual = {}
    }

    for _, node in ipairs(ast.body or {}) do
        if node.type == "assign" then
            local path = stripSWEP(node.path)
            local adapter = Resolver.GetAdapter(path[1])

            if adapter and adapter.Name == "FT" then
                local localPath = {}

                for index = 2, #path do
                    localPath[#localPath + 1] = path[index]
                end

                local joined = Path.Join(localPath)
                local normalized = Path.LowerJoin(localPath)

                if normalized == "priority" then
                    config.priority = canonicalNamespaces(node.value, report, "FT.Priority")
                elseif normalized == "merge" and type(node.value) == "table" then
                    config.merge = Table.DeepCopy(node.value)
                elseif normalized == "merge" then
                    report:AddError("FT.Merge must be a table", node)
                elseif normalized == "customization.provider" then
                    config.customizationProvider = node.value
                elseif string.sub(normalized, 1, 7) == "visual." then
                    local domain = string.sub(normalized, 8)

                    if domain == "default" or domain == "inspect" or domain == "attachments"
                        or domain == "hud" or domain == "presentation" then
                        config.visual[domain] = node.value
                    else
                        report:AddWarning("Unknown visual domain '" .. tostring(domain) .. "'")
                    end
                elseif string.sub(normalized, 1, 6) == "merge." then
                    local mergePath = {}

                    for index = 2, #localPath do
                        mergePath[#mergePath + 1] = localPath[index]
                    end

                    config.merge[Path.Join(mergePath)] = node.value
                end
            end
        end
    end

    report.config = config
    return config
end

local function isFTConfigPath(path)
    local adapter = Resolver.GetAdapter(path[1])

    if not adapter or adapter.Name ~= "FT" then
        return false
    end

    local localPath = {}

    for index = 2, #path do
        localPath[#localPath + 1] = path[index]
    end

    local joined = Path.LowerJoin(localPath)

    return joined == "priority"
        or joined == "merge"
        or string.sub(joined, 1, 6) == "merge."
        or joined == "customization.provider"
        or string.sub(joined, 1, 7) == "visual."
end

local function importedAdapters(imports)
    local adapters = {}
    local seen = {}

    for _, namespace in ipairs(imports or {}) do
        local adapter = Resolver.GetAdapter(namespace)

        if adapter and not seen[normalizeNamespace(adapter.Name)] then
            seen[normalizeNamespace(adapter.Name)] = true
            adapters[#adapters + 1] = adapter
        end
    end

    return adapters
end

local function suggestAmbiguous(path, candidates)
    local suggestions = {}
    local joined = Path.Join(path)

    for _, adapter in ipairs(candidates) do
        suggestions[#suggestions + 1] = adapter.Name .. "." .. joined
    end

    suggestions[#suggestions + 1] = "FT." .. joined
    return table.concat(suggestions, ", ")
end

local function visualDomainForPath(irPath)
    local path = Path.LowerJoin(irPath)

    local function isDomain(name)
        return path == name or string.sub(path, 1, #name + 1) == name .. "."
    end

    if isDomain("attachments") then
        return "attachments"
    end

    if isDomain("ui.inspect") or isDomain("animations.inspect") then
        return "inspect"
    end

    if isDomain("ammo") or path == "ui.drawammo" or path == "ui.crosshair" then
        return "hud"
    end

    if isDomain("rendering") or isDomain("ads") or isDomain("camera")
        or isDomain("animations") or isDomain("effects") then
        return "presentation"
    end

    return nil
end

local function providerForSource(source)
    local adapter = Resolver.GetAdapter(source)
    return adapter and normalizeProvider(adapter.Provider), adapter and adapter.Name
end

local function defaultVisualProvider(config, operations)
    local prioritizedProvider, prioritizedSource = providerForSource(config.priority[1])

    if prioritizedProvider then
        return prioritizedProvider, prioritizedSource
    end

    for _, operation in ipairs(operations or {}) do
        local provider, source = providerForSource(operation.source)

        if provider then
            return provider, source
        end
    end

    return "ft", "FT"
end

local function chooseVisualProviders(ir, config, operations, origins, report)
    local defaultProvider, defaultSource = defaultVisualProvider(config, operations)
    local explicitDefault = normalizeProvider(config.visual.default)

    if config.visual.default ~= nil and not explicitDefault then
        report:AddWarning("Unknown visual provider '" .. tostring(config.visual.default) .. "' for Visual.Default")
    end

    if explicitDefault then
        defaultProvider = explicitDefault
        defaultSource = "explicit"
    end

    local providers = {}
    local sources = {}

    for _, domain in ipairs({"inspect", "attachments", "hud", "presentation"}) do
        local provider = defaultProvider
        local source = defaultSource
        local explicit = normalizeProvider(config.visual[domain])

        if config.visual[domain] ~= nil and not explicit then
            report:AddWarning("Unknown visual provider '" .. tostring(config.visual[domain]) .. "' for Visual." .. domain)
        end

        if explicit then
            provider = explicit
            source = "explicit"
        else
            local origin = origins[domain]
            local originProvider, originSource = origin and providerForSource(origin)

            if originProvider then
                provider = originProvider
                source = originSource
            end
        end

        providers[domain] = provider
        sources[domain] = source
    end

    -- The old setting controls attachment presentation only. "mixed" now means auto-selection.
    if config.customizationProvider ~= nil and string.lower(tostring(config.customizationProvider)) ~= "mixed" then
        local legacy = normalizeProvider(config.customizationProvider)

        if legacy then
            providers.attachments = legacy
            sources.attachments = "legacy explicit"
        else
            report:AddWarning("Unknown customization provider '" .. tostring(config.customizationProvider) .. "'")
        end
    end

    ir.ui.visual.providers = providers
    ir.ui.visual.sources = sources
    ir.ui.customization.provider = providers.attachments
    ir.ui.customization.source = sources.attachments
end

function Resolver.Resolve(ast, options)
    options = options or {}

    local report = options.report or FTBase.Report.New("compile")
    local ir = FTBase.IR.New()
    local imports = canonicalNamespaces(options.imports, report, "imports")
    local imported = {}

    for _, namespace in ipairs(imports) do
        imported[normalizeNamespace(namespace)] = true
    end

    local config = readConfig(ast, report)
    local context = Context.New(report, config)

    for _, node in ipairs(ast.body or {}) do
        if node.type == "using" then
            local adapter = Resolver.GetAdapter(node.namespace)

            if adapter then
                local key = normalizeNamespace(adapter.Name)

                if not imported[key] then
                    imported[key] = true
                    imports[#imports + 1] = adapter.Name
                end

                ir.meta.sourceStyles[adapter.Name] = true
            else
                report:AddError("Unknown namespace '" .. tostring(node.namespace) .. "'", node)
            end
        end
    end

    for _, node in ipairs(ast.body or {}) do
        if node.type == "assign" then
            local path = stripSWEP(clonePath(node.path))

            if isFTConfigPath(path) then
                -- Configuration is consumed before mapping operations are applied.
            else
                local explicit = Resolver.GetAdapter(path[1])

                if explicit then
                    local localPath = {}

                    for index = 2, #path do
                        localPath[#localPath + 1] = path[index]
                    end

                    if #localPath == 0 then
                        report:AddUnknown(explicit.Name, "", node.value, node)
                    elseif not explicit:Map(localPath, node.value, context, node) then
                        report:AddUnknown(explicit.Name, Path.Join(localPath), node.value, node)
                    end
                else
                    local candidates = {}

                    for _, adapter in ipairs(importedAdapters(imports)) do
                        if adapter:CanMap(path) then
                            candidates[#candidates + 1] = adapter
                        end
                    end

                    if #candidates == 1 then
                        candidates[1]:Map(path, node.value, context, node)
                    elseif #candidates > 1 then
                        report:AddError(
                            Path.Join(path) .. " is ambiguous after using directives. Use one of: " .. suggestAmbiguous(path, candidates),
                            node
                        )
                    else
                        report:AddUnknown("unresolved", Path.Join(path), node.value, node)
                    end
                end
            end
        end
    end

    local rank = makeRank(config.priority)

    table.sort(context.operations, function(left, right)
        local leftRank = rank[normalizeNamespace(left.source)] or 0
        local rightRank = rank[normalizeNamespace(right.source)] or 0

        if leftRank == rightRank then
            return left.order < right.order
        end

        return leftRank < rightRank
    end)

    local visualOrigins = {}
    local visualContributors = {
        inspect = {},
        attachments = {},
        hud = {},
        presentation = {}
    }

    for _, operation in ipairs(context.operations) do
        local before = Table.DeepCopy(Path.Get(ir, operation.irPath))
        FTBase.Merge.Apply(ir, operation, report)

        local domain = visualDomainForPath(operation.irPath)

        if domain and not Table.DeepEqual(before, Path.Get(ir, operation.irPath)) then
            visualOrigins[domain] = operation.source
            visualContributors[domain][operation.source] = true
        end

        ir.meta.sourceStyles[operation.source] = true
    end

    ir.developer.priority = Table.DeepCopy(config.priority)
    ir.developer.merge = Table.DeepCopy(config.merge)
    ir.ui.customization.openCommand = ir.ui.customization.openCommand or "ft_customize"

    for _, domain in ipairs({"inspect", "attachments", "hud", "presentation"}) do
        local contributors = visualContributors[domain]
        local names = {}

        for _, source in ipairs(Table.Keys(contributors)) do
            names[#names + 1] = tostring(source)
        end

        if #names > 1 and config.visual[domain] == nil then
            report:AddWarning(
                "Visual domain '" .. domain .. "' receives values from multiple dialects: "
                    .. table.concat(names, ", ") .. "; selected provider follows FT.Priority and final IR origin"
            )
        end
    end

    chooseVisualProviders(ir, config, context.operations, visualOrigins, report)

    FTBase.Validator.Validate(ir, report)

    if not report:HasErrors() then
        FTBase.Optimizer.Optimize(ir, report)
    end

    return ir, report, context.operations
end

FTBase.Compiler.Resolver = Resolver
