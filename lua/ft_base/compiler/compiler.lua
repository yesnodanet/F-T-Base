FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Compiler = FTBase.Compiler

local function tableToAssignments(root, prefix, output)
    output = output or {}

    for key, value in pairs(root or {}) do
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

    ast, report = Compiler.Parse(source or "", options.name or "<weapon>", report)

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
    local ast = {
        type = "weapon",
        body = tableToAssignments(spec or {}, { namespace }, {})
    }

    local report = options.report or FTBase.Report.New("compile")
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
