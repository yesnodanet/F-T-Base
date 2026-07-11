FTBase = FTBase or {}
FTBase.Adapters = FTBase.Adapters or {}

local Adapter = {}
Adapter.__index = Adapter

local Path = FTBase.Util.Path
local Table = FTBase.Util.Table

local function normalize(path)
    return string.lower(Path.Join(path))
end

local function ruleList(rules)
    local output = {}

    for externalPath, rule in pairs(rules or {}) do
        output[normalize(externalPath)] = rule
    end

    return output
end

function Adapter.New(definition)
    local adapter = setmetatable({}, Adapter)

    adapter.Name = definition.Name
    adapter.Aliases = definition.Aliases or {}
    adapter.Rules = ruleList(definition.Rules or {})
    adapter.Deprecated = definition.Deprecated or {}
    adapter.Emit = definition.Emit or {}

    return adapter
end

function Adapter:FindRule(path)
    return self.Rules[normalize(path)]
end

function Adapter:HasChildRule(path)
    local prefix = normalize(path)

    if prefix ~= "" then
        prefix = prefix .. "."
    end

    for rulePath in pairs(self.Rules) do
        if string.sub(rulePath, 1, #prefix) == prefix then
            return true
        end
    end

    return false
end

function Adapter:CanMap(path)
    if self:FindRule(path) then
        return true
    end

    return self:HasChildRule(path)
end

function Adapter:ApplyRule(path, value, context, node)
    local rule = self:FindRule(path)

    if not rule then
        return false
    end

    if rule.deprecated then
        context.report:AddDeprecated(self.Name, Path.Join(path), rule.deprecated, node)
    end

    if rule.ignore then
        context.report:AddIgnored(self.Name .. "." .. Path.Join(path) .. " ignored: " .. tostring(rule.ignore), node)
        return true
    end

    local mappedValue = value

    if rule.transform then
        mappedValue = rule.transform(value, context, node)
    end

    if rule.ir then
        context:Emit(self.Name, Path.Join(path), rule.ir, mappedValue, rule.merge, node)
    end

    if rule.emit then
        rule.emit(value, context, node, self)
    end

    return true
end

function Adapter:Map(path, value, context, node)
    if self:ApplyRule(path, value, context, node) then
        return true
    end

    if type(value) == "table" and not Table.IsArray(value) then
        local mappedAny = false
        local leaves = Table.FlattenLeaves(value, path)

        for _, leaf in ipairs(leaves) do
            if self:ApplyRule(leaf.path, leaf.value, context, node) then
                mappedAny = true
            else
                context.report:AddUnknown(self.Name, Path.Join(leaf.path), leaf.value, node)
            end
        end

        return mappedAny
    end

    return false
end

function FTBase.Adapters.Make(definition)
    return Adapter.New(definition)
end

FTBase.Adapters.Base = Adapter
