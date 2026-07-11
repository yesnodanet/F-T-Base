FTConverter = FTConverter or {}

function FTConverter.Convert(sourceText, fromStyle, toStyle, options)
    options = options or {}

    local imports = options.imports or {}

    if fromStyle then
        imports[#imports + 1] = fromStyle
    end

    local result = FTBase.Compiler.CompileSource(sourceText or "", {
        name = options.name or "<converter>",
        imports = imports
    })

    local output = ""

    if not result.report:HasErrors() then
        output = FTConverter.Generator.Generate(result.ir, toStyle or "FT", result.report)
    end

    return {
        ir = result.ir,
        ast = result.ast,
        operations = result.operations,
        output = output,
        report = result.report
    }
end
