FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Compiler = FTBase.Compiler

Compiler.Limits = Compiler.Limits or {
    maxSourceBytes = 256 * 1024,
    maxTokens = 20000,
    maxASTNodes = 10000,
    maxDepth = 64,
    maxAttachmentSlots = 64,
    maxAttachmentDefinitions = 256
}

local function validateSpecTree(value, report, state, depth, path)
    state.nodes = state.nodes + 1

    if state.nodes > Compiler.Limits.maxASTNodes then
        if not state.nodeLimitReported then
            state.nodeLimitReported = true
            report:AddError("AST node limit exceeded (maximum " .. tostring(Compiler.Limits.maxASTNodes) .. ")")
        end

        return false
    end

    if type(value) ~= "table" then
        return true
    end

    if depth > Compiler.Limits.maxDepth then
        report:AddError(
            tostring(path) .. " exceeds maximum nesting depth of " .. tostring(Compiler.Limits.maxDepth)
        )
        return false
    end

    if state.active[value] then
        report:AddError(tostring(path) .. " contains a cyclic table")
        return false
    end

    state.active[value] = true
    local valid = true

    for _, key in ipairs(FTBase.Util.Table.Keys(value)) do
        if type(key) ~= "string" and type(key) ~= "number" then
            report:AddError(tostring(path) .. " contains an unsupported " .. type(key) .. " key")
            valid = false
        end

        if not validateSpecTree(value[key], report, state, depth + 1, tostring(path) .. "." .. tostring(key)) then
            valid = false
        end

        if state.nodeLimitReported then
            break
        end
    end

    state.active[value] = nil
    return valid
end

local function tableToAssignments(root, prefix, output)
    output = output or {}

    -- Pairs() order is intentionally unspecified in Lua.  Stable assignment
    -- ordering is important because merge strategies such as `first` and
    -- `last` are order-sensitive.
    for _, key in ipairs(FTBase.Util.Table.Keys(root or {})) do
        local value = root[key]
        local path = FTBase.Util.Table.DeepCopy(prefix)
        path[#path + 1] = key

        if type(value) == "table" and not FTBase.Util.Table.IsArray(value) and not value.__type then
            tableToAssignments(value, path, output)
        else
            output[#output + 1] = {
                type = "assign",
                path = path,
                value = value
            }
        end
    end

    return output
end

function Compiler.RegisterAdapter(adapter)
    return Compiler.Resolver.RegisterAdapter(adapter)
end

function Compiler.RegisterDefaultAdapters()
    Compiler.Adapters = {}
    Compiler.AdapterAliases = {}

    local adapters = FTBase.Adapters or {}
    local ordered = {
        adapters.FT,
        adapters.TFA,
        adapters.ARC9,
        adapters.ArcCW,
        adapters.MW,
        adapters.TacRP,
        adapters.SWB
    }

    for _, adapter in ipairs(ordered) do
        if adapter then
            Compiler.RegisterAdapter(adapter)
        end
    end
end

function Compiler.CompileSource(source, options)
    options = options or {}

    local report = options.report or FTBase.Report.New("compile")
    local ast = nil

    if source == nil then
        source = ""
    elseif type(source) ~= "string" then
        report:AddError("CompileSource expects source to be a string")
        return {
            ir = FTBase.IR.New(),
            ast = {type = "weapon", body = {}},
            report = report,
            operations = {}
        }
    end

    ast, report = Compiler.Parse(source, options.name or "<weapon>", report)

    if report:HasErrors() then
        return {
            ir = FTBase.IR.New(),
            ast = ast,
            report = report,
            operations = {}
        }
    end

    local ir, resolveReport, operations = Compiler.Resolver.Resolve(ast, {
        report = report,
        imports = options.imports
    })

    return {
        ir = ir,
        ast = ast,
        report = resolveReport,
        operations = operations
    }
end

function Compiler.CompileTable(spec, options)
    options = options or {}

    local namespace = options.namespace or "FT"
    local report = options.report or FTBase.Report.New("compile")

    if type(spec) ~= "table" then
        report:AddError("CompileTable expects a table specification")
        return {
            ir = FTBase.IR.New(),
            ast = {type = "weapon", body = {}},
            report = report,
            operations = {}
        }
    end

    validateSpecTree(spec, report, {nodes = 0, active = {}}, 0, namespace)

    if report:HasErrors() then
        return {
            ir = FTBase.IR.New(),
            ast = {type = "weapon", body = {}},
            report = report,
            operations = {}
        }
    end

    local ast = {
        type = "weapon",
        body = tableToAssignments(spec or {}, { namespace }, {})
    }

    local ir, resolveReport, operations = Compiler.Resolver.Resolve(ast, {
        report = report,
        imports = options.imports
    })

    return {
        ir = ir,
        ast = ast,
        report = resolveReport,
        operations = operations
    }
end

function Compiler.CompileWeapon(swep)
    local result = nil

    if swep.FTSource then
        result = Compiler.CompileSource(swep.FTSource, {
            name = swep.GetClass and swep:GetClass() or "weapon",
            imports = swep.FTImports
        })
    else
        result = Compiler.CompileTable(swep.FT or {}, {
            namespace = "FT",
            imports = swep.FTImports
        })
    end

    if result.ir then
        result.ir.meta.id = swep.GetClass and swep:GetClass() or result.ir.meta.id
        result.ir.meta.printName = swep.PrintName or result.ir.meta.printName
        FTBase.WeaponRegistry.Register(result.ir.meta.id, result.ir, result.report)
    end

    return result
end
