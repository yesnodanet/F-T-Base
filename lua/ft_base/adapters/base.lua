FTBase = FTBase or {}
FTBase.Adapters = FTBase.Adapters or {}

local Adapter = {}
Adapter.__index = Adapter

local Path = FTBase.Util.Path
local Table = FTBase.Util.Table

-- Attachment metadata is intentionally normalized without removing the
-- original dialect fields. Providers consume the canonical keys while
-- converters and diagnostics can still inspect the source-shaped table.
local attachmentMetadataAliases = {
    {"name", {"Name", "PrintName", "DisplayName", "Label", "SlotName"}},
    {"shortName", {"ShortName", "ShortPrintName", "Abbrev", "Abbreviation"}},
    {"category", {"Category", "CategoryName"}},
    {"folder", {"Folder", "FolderName", "Menu"}},
    {"description", {"Description", "Desc", "Tooltip"}},
    {"pros", {"Pros", "Positive", "Positives", "Benefits"}},
    {"cons", {"Cons", "Negative", "Negatives", "Drawbacks"}},
    {"trivia", {"Trivia", "Notes", "FlavorText"}},
    {"credits", {"Credits", "Credit", "Authors"}},
    {"stats", {"Stats", "Stat", "StatChanges", "StatModifiers"}},
    {"toggles", {"Toggles", "Toggle", "ToggleNames", "ToggleValues", "ToggleOptions", "ToggleStats"}},
    {"sliders", {"Sliders", "Slider", "SliderData", "SliderValues"}},
    {"icon", {"Icon", "IconMaterial", "IconPath"}}
}

local function normalizeAttachmentMetadata(value, seen)
    if type(value) ~= "table" then
        return value
    end

    if value.__type then
        return value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for _, key in ipairs(Table.Keys(value)) do
        copy[key] = normalizeAttachmentMetadata(value[key], seen)
    end

    for _, alias in ipairs(attachmentMetadataAliases) do
        local canonical = alias[1]

        if copy[canonical] == nil then
            for _, sourceKey in ipairs(alias[2]) do
                if copy[sourceKey] ~= nil then
                    copy[canonical] = copy[sourceKey]
                    break
                end
            end
        end
    end

    return copy
end

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
    adapter.Provider = definition.Provider or string.lower(definition.Name or "mixed")
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
    local exactRule = self:FindRule(path)
    local isTable = type(value) == "table"
    local shouldApplyExact = exactRule and (not isTable or Table.IsArray(value) or not self:HasChildRule(path))

    if shouldApplyExact and self:ApplyRule(path, value, context, node) then
        return true
    end

    if type(value) == "table" and not Table.IsArray(value) then
        local mappedChild = false
        local handled = {}

        for _, key in ipairs(Table.Keys(value)) do
            local childPath = Table.DeepCopy(path)
            childPath[#childPath + 1] = key

            if self:CanMap(childPath) then
                handled[key] = true
                mappedChild = self:Map(childPath, value[key], context, node) or mappedChild
            end
        end

        if mappedChild then
            for _, key in ipairs(Table.Keys(value)) do
                if not handled[key] then
                    local childPath = Table.DeepCopy(path)
                    childPath[#childPath + 1] = key
                    local leaves = Table.FlattenLeaves(value[key], childPath)

                    for _, leaf in ipairs(leaves) do
                        context.report:AddUnknown(self.Name, Path.Join(leaf.path), leaf.value, node)
                    end
                end
            end

            return true
        end

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

    if exactRule then
        return self:ApplyRule(path, value, context, node)
    end

    return false
end

function FTBase.Adapters.Make(definition)
    return Adapter.New(definition)
end

FTBase.Adapters.NormalizeAttachmentMetadata = normalizeAttachmentMetadata

FTBase.Adapters.Base = Adapter
