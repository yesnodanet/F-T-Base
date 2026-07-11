-- Command-style converter entry point for environments that can load the addon.
-- Usage in GMod Lua:
-- lua_run print(include("tools/ft_converter.lua").ConvertText(source, "TFA", "ARC9"))

local App = {}

function App.ConvertText(source, fromStyle, toStyle)
    if not FTBase or not FTConverter then
        error("F&T Base must be loaded before using tools/ft_converter.lua")
    end

    local result = FTConverter.Convert(source, fromStyle, toStyle)
    return result.output, result.report
end

return App
