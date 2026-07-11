FTBase = FTBase or {}

local Plugin = {
    items = {}
}

function Plugin.Register(id, plugin)
    plugin = plugin or {}
    plugin.id = id
    Plugin.items[id] = plugin
    return plugin
end

function Plugin.Get(id)
    return Plugin.items[id]
end

function Plugin.GetAll()
    local list = {}

    for _, plugin in pairs(Plugin.items) do
        list[#list + 1] = plugin
    end

    table.sort(list, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)

    return list
end

FTBase.Plugin = Plugin
