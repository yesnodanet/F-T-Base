FTBase = FTBase or {}

local Report = {}
Report.__index = Report

local function add(bucket, item)
    bucket[#bucket + 1] = item
    return item
end

function Report.New(kind)
    return setmetatable({
        kind = kind or "compile",
        applied = {},
        ignored = {},
        conflicts = {},
        warnings = {},
        errors = {},
        unknown = {},
        deprecated = {},
        missingAnimations = {},
        missingSounds = {},
        invalidAttachments = {},
        optimizationNotes = {},
        performanceSuggestions = {},
        timings = {}
    }, Report)
end

function Report:AddApplied(source, externalPath, irPath, value, strategy)
    return add(self.applied, {
        source = source,
        externalPath = externalPath,
        irPath = irPath,
        value = value,
        strategy = strategy or "override"
    })
end

function Report:AddIgnored(message, node)
    return add(self.ignored, {
        message = message,
        node = node
    })
end

function Report:AddConflict(irPath, previous, incoming, strategy, source)
    return add(self.conflicts, {
        irPath = irPath,
        previous = previous,
        incoming = incoming,
        strategy = strategy,
        source = source
    })
end

function Report:AddWarning(message, node)
    return add(self.warnings, {
        message = message,
        node = node
    })
end

function Report:AddError(message, node)
    return add(self.errors, {
        message = message,
        node = node
    })
end

function Report:AddUnknown(source, path, value, node)
    return add(self.unknown, {
        source = source,
        path = path,
        value = value,
        node = node
    })
end

function Report:AddDeprecated(source, path, replacement, node)
    return add(self.deprecated, {
        source = source,
        path = path,
        replacement = replacement,
        node = node
    })
end

function Report:AddMissingAnimation(name, node)
    return add(self.missingAnimations, {
        name = name,
        node = node
    })
end

function Report:AddMissingSound(name, node)
    return add(self.missingSounds, {
        name = name,
        node = node
    })
end

function Report:AddInvalidAttachment(message, attachment)
    return add(self.invalidAttachments, {
        message = message,
        attachment = attachment
    })
end

function Report:AddOptimization(message)
    return add(self.optimizationNotes, {
        message = message
    })
end

function Report:AddPerformanceSuggestion(message)
    return add(self.performanceSuggestions, {
        message = message
    })
end

function Report:Merge(other)
    if not other then
        return self
    end

    local buckets = {
        "applied",
        "ignored",
        "conflicts",
        "warnings",
        "errors",
        "unknown",
        "deprecated",
        "missingAnimations",
        "missingSounds",
        "invalidAttachments",
        "optimizationNotes",
        "performanceSuggestions"
    }

    for _, bucket in ipairs(buckets) do
        for _, item in ipairs(other[bucket] or {}) do
            self[bucket][#self[bucket] + 1] = item
        end
    end

    return self
end

function Report:HasErrors()
    return #self.errors > 0
end

function Report:Summary()
    return {
        applied = #self.applied,
        ignored = #self.ignored,
        conflicts = #self.conflicts,
        warnings = #self.warnings,
        errors = #self.errors,
        unknown = #self.unknown,
        deprecated = #self.deprecated,
        missingAnimations = #self.missingAnimations,
        missingSounds = #self.missingSounds,
        invalidAttachments = #self.invalidAttachments,
        optimizationNotes = #self.optimizationNotes,
        performanceSuggestions = #self.performanceSuggestions
    }
end

local function appendSection(lines, title, items, formatter)
    lines[#lines + 1] = title .. ": " .. tostring(#items)

    for index, item in ipairs(items) do
        lines[#lines + 1] = "  " .. tostring(index) .. ". " .. formatter(item)
    end
end

function Report:ToString()
    local lines = {}
    local stringify = FTBase.Util and FTBase.Util.Table and FTBase.Util.Table.ValueToString or tostring

    lines[#lines + 1] = "F&T " .. self.kind .. " report"

    appendSection(lines, "Errors", self.errors, function(item)
        return item.message
    end)

    appendSection(lines, "Warnings", self.warnings, function(item)
        return item.message
    end)

    appendSection(lines, "Conflicts", self.conflicts, function(item)
        return item.irPath .. " via " .. tostring(item.strategy)
    end)

    appendSection(lines, "Applied properties", self.applied, function(item)
        return tostring(item.source) .. "." .. tostring(item.externalPath) .. " -> " .. tostring(item.irPath) .. " = " .. stringify(item.value)
    end)

    appendSection(lines, "Unknown fields", self.unknown, function(item)
        return tostring(item.source) .. "." .. tostring(item.path)
    end)

    appendSection(lines, "Ignored properties", self.ignored, function(item)
        return item.message
    end)

    appendSection(lines, "Deprecated syntax", self.deprecated, function(item)
        return tostring(item.source) .. "." .. tostring(item.path) .. " -> " .. tostring(item.replacement)
    end)

    appendSection(lines, "Missing animations", self.missingAnimations, function(item)
        return tostring(item.name)
    end)

    appendSection(lines, "Missing sounds", self.missingSounds, function(item)
        return tostring(item.name)
    end)

    appendSection(lines, "Invalid attachments", self.invalidAttachments, function(item)
        return item.message
    end)

    appendSection(lines, "Optimization notes", self.optimizationNotes, function(item)
        return item.message
    end)

    appendSection(lines, "Performance suggestions", self.performanceSuggestions, function(item)
        return item.message
    end)

    return table.concat(lines, "\n")
end

FTBase.Report = Report
