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
    mixed = true
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
        customizationProvider = nil
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

                if joined == "Priority" and type(node.value) == "table" then
                    config.priority = Table.DeepCopy(node.value)
                elseif joined == "Merge" and type(node.value) == "table" then
                    config.merge = Table.DeepCopy(node.value)
                elseif joined == "Customization.Provider" then
                    config.customizationProvider = node.value
                elseif Path.StartsWith(localPath, {"Merge"}) then
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

    return localPath[1] == "Priority"
        or localPath[1] == "Merge"
        or (localPath[1] == "Customization" and localPath[2] == "Provider")
end

local function importedAdapters(imports)
    local adapters = {}

    for _, namespace in ipairs(imports or {}) do
        local adapter = Resolver.GetAdapter(namespace)

        if adapter then
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

local function chooseCustomizationProvider(ir, config, operations, report)
    local explicit = normalizeProvider(config.customizationProvider)

    if config.customizationProvider ~= nil and not explicit then
        report:AddWarning(
            "Unknown customization provider '" .. tostring(config.customizationProvider) .. "'; using mixed provider"
        )
    end

    if explicit then
        ir.ui.customization.provider = explicit
        ir.ui.customization.source = "explicit"
        return
    end

    local prioritized = config.priority[1]
    local prioritizedAdapter = prioritized and Resolver.GetAdapter(prioritized)
    local prioritizedProvider = prioritizedAdapter and normalizeProvider(prioritizedAdapter.Provider)

    if prioritizedProvider then
        ir.ui.customization.provider = prioritizedProvider
        ir.ui.customization.source = prioritizedAdapter.Name
        return
    end

    local providers = {}
    local providerSources = {}

    for _, operation in ipairs(operations or {}) do
        local adapter = Resolver.GetAdapter(operation.source)
        local provider = adapter and normalizeProvider(adapter.Provider)

        if provider then
            providers[provider] = true
            providerSources[provider] = operation.source
        end
    end

    local selected = nil

    for provider in pairs(providers) do
        if selected then
            selected = "mixed"
            break
        end

        selected = provider
    end

    ir.ui.customization.provider = selected or "ft"
    ir.ui.customization.source = selected and providerSources[selected] or nil
end

function Resolver.Resolve(ast, options)
    options = options or {}

    local report = options.report or FTBase.Report.New("compile")
    local ir = FTBase.IR.New()
    local imports = Table.DeepCopy(options.imports or {})
    local config = readConfig(ast, report)
    local context = Context.New(report, config)

    for _, node in ipairs(ast.body or {}) do
        if node.type == "using" then
            local adapter = Resolver.GetAdapter(node.namespace)

            if adapter then
                imports[#imports + 1] = adapter.Name
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

    for _, operation in ipairs(context.operations) do
        FTBase.Merge.Apply(ir, operation, report)

        ir.meta.sourceStyles[operation.source] = true
    end

    ir.developer.priority = Table.DeepCopy(config.priority)
    ir.developer.merge = Table.DeepCopy(config.merge)
    ir.ui.customization.openCommand = ir.ui.customization.openCommand or "ft_customize"

    chooseCustomizationProvider(ir, config, context.operations, report)

    FTBase.Validator.Validate(ir, report)
    FTBase.Optimizer.Optimize(ir, report)

    return ir, report, context.operations
end

FTBase.Compiler.Resolver = Resolver
