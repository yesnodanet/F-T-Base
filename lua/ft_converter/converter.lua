FTConverter = FTConverter or {}

local function copyImports(imports, fromStyle)
    local output = {}
    local seen = {}

    local function add(value)
        if value == nil then
            return
        end

        local adapter = FTBase.Compiler.Resolver and FTBase.Compiler.Resolver.GetAdapter(value)
        local canonical = adapter and adapter.Name or tostring(value)
        local key = string.lower(canonical)

        if seen[key] then
            return
        end

        seen[key] = true
        output[#output + 1] = canonical
    end

    if type(imports) == "table" then
        for _, value in ipairs(imports) do
            add(value)
        end
    end

    add(fromStyle)
    return output
end

function FTConverter.Convert(sourceText, fromStyle, toStyle, options)
    options = options or {}

    local imports = copyImports(options.imports, fromStyle)

    local result = FTBase.Compiler.CompileSource(sourceText or "", {
        name = options.name or "<converter>",
        imports = imports
    })

    local output = ""
    local warnings = {}

    if not result.report:HasErrors() then
        output, warnings = FTConverter.Generator.Generate(result.ir, toStyle or "FT", result.report)
    end

    return {
        ir = result.ir,
        ast = result.ast,
        operations = result.operations,
        output = output,
        report = result.report,
        warnings = warnings
    }
end
