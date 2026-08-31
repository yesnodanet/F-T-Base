FTBase = FTBase or {}

local Validator = {}

local Path = FTBase.Util.Path
local Table = FTBase.Util.Table

local function isFinite(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function addError(report, message, node)
    report:AddError(message, node)
end

local function validateType(ir, report, path, expected, optional)
    local value = Path.Get(ir, path)

    if value == nil and optional then
        return true
    end

    if type(value) ~= expected then
        addError(report, path .. " must be a " .. expected)
        return false
    end

    return true
end

local function validateNumber(ir, report, spec)
    local value = Path.Get(ir, spec.path)

    if value == nil and spec.optional then
        return
    end

    if not isFinite(value) then
        addError(report, spec.path .. " must be a finite number")
        return
    end

    if spec.integer and value ~= math.floor(value) then
        addError(report, spec.path .. " must be an integer")
    end

    if spec.exclusiveMinimum ~= nil and value <= spec.exclusiveMinimum then
        addError(report, spec.path .. " must be greater than " .. tostring(spec.exclusiveMinimum))
    elseif spec.minimum ~= nil and value < spec.minimum then
        addError(report, spec.path .. " must be at least " .. tostring(spec.minimum))
    end

    if spec.maximum ~= nil and value > spec.maximum then
        addError(report, spec.path .. " must be at most " .. tostring(spec.maximum))
    end
end

local function validateEnum(ir, report, path, values)
    local value = Path.Get(ir, path)

    if type(value) ~= "string" or not values[string.lower(value)] then
        addError(report, path .. " has unsupported value '" .. tostring(value) .. "'")
    end
end

local function validateFiniteTree(value, report, path, depth, seen, maximumDepth)
    if type(isvector) == "function" and isvector(value) then
        validateFiniteTree(value.x, report, path .. ".x", depth + 1, seen, maximumDepth)
        validateFiniteTree(value.y, report, path .. ".y", depth + 1, seen, maximumDepth)
        validateFiniteTree(value.z, report, path .. ".z", depth + 1, seen, maximumDepth)
        return
    end

    if type(isangle) == "function" and isangle(value) then
        validateFiniteTree(value.p, report, path .. ".p", depth + 1, seen, maximumDepth)
        validateFiniteTree(value.y, report, path .. ".y", depth + 1, seen, maximumDepth)
        validateFiniteTree(value.r, report, path .. ".r", depth + 1, seen, maximumDepth)
        return
    end

    if type(value) == "number" then
        if not isFinite(value) then
            addError(report, path .. " must contain only finite numbers")
        end

        return
    end

    local valueType = type(value)

    if valueType == "function" or valueType == "thread" or valueType == "userdata" then
        addError(report, path .. " contains unsupported value type " .. valueType)
        return
    end

    if valueType ~= "table" then
        return
    end

    if seen[value] then
        return
    end

    seen[value] = true

    if depth > maximumDepth then
        addError(report, path .. " exceeds maximum nesting depth of " .. tostring(maximumDepth))
        return
    end

    for key, item in pairs(value) do
        local keyType = type(key)

        if keyType ~= "string" and keyType ~= "number" and keyType ~= "boolean" then
            addError(report, path .. " contains unsupported " .. keyType .. " key")
        end

        validateFiniteTree(item, report, path .. "." .. tostring(key), depth + 1, seen, maximumDepth)
    end
end

local function invalidAttachment(report, message, attachment)
    report:AddInvalidAttachment(message, attachment)
    addError(report, message, attachment)
end

local function validateMetadataValue(report, path, value, allowString)
    if value == nil then
        return
    end

    if allowString and type(value) == "string" then
        return
    end

    if type(value) ~= "table" then
        addError(report, path .. " must be a " .. (allowString and "string or table" or "table"))
        return
    end

    validateFiniteTree(value, report, path, 1, {}, 64)
end

local attachmentStringMetadata = {
    "name", "shortName", "category", "folder"
}

local attachmentRichMetadata = {
    "description", "pros", "cons", "trivia", "credits", "stats", "toggles", "sliders"
}

local function validateAttachmentMetadata(report, prefix, value)
    if type(value) ~= "table" then
        return
    end

    for _, field in ipairs(attachmentStringMetadata) do
        local item = value[field]

        if item ~= nil and (type(item) ~= "string" or item == "") then
            invalidAttachment(report, prefix .. "." .. field .. " must be a non-empty string", value)
        end
    end

    for _, field in ipairs(attachmentRichMetadata) do
        local item = value[field]

        if item ~= nil then
            if field == "description" or field == "pros" or field == "cons"
                or field == "trivia" or field == "credits" then
                if type(item) ~= "string" and type(item) ~= "table" then
                    invalidAttachment(report, prefix .. "." .. field .. " must be a string or table", value)
                elseif type(item) == "table" then
                    validateFiniteTree(item, report, prefix .. "." .. field, 1, {}, 64)
                end
            elseif type(item) ~= "table" then
                invalidAttachment(report, prefix .. "." .. field .. " must be a table", value)
            else
                validateFiniteTree(item, report, prefix .. "." .. field, 1, {}, 64)
            end
        end
    end
end

local optionalIRPaths = {
    ["fire.delay"] = true,
    ["camera.sprint.pos"] = true,
    ["camera.sprint.ang"] = true,
    ["ads.pos"] = true,
    ["ads.ang"] = true,
    ["animations.reloadDuration"] = true,
    ["animations.inspect"] = true,
    ["sounds.fire.indoorTail"] = true,
    ["sounds.fire.outdoorTail"] = true,
    ["sounds.fire.distant"] = true,
    ["sounds.fire.suppressed"] = true,
    ["effects.muzzle"] = true,
    ["effects.shell"] = true,
    ["effects.tracer"] = true,
    ["physics.projectile.model"] = true,
    ["rendering.viewModel"] = true,
    ["rendering.worldModel"] = true,
    ["ui.customization.source"] = true
}

local optionalModifierTypes = {
    ["fire.delay"] = "number",
    ["animations.reloadDuration"] = "number",
    ["physics.projectile.model"] = "string",
    ["rendering.viewModel"] = "string",
    ["rendering.worldModel"] = "string",
    ["effects.muzzle"] = "string",
    ["effects.shell"] = "string",
    ["effects.tracer"] = "string",
    ["sounds.fire.indoorTail"] = "string",
    ["sounds.fire.outdoorTail"] = "string",
    ["sounds.fire.distant"] = "string",
    ["sounds.fire.suppressed"] = "string"
}

local modifierNumberRules = {
    ["damage.base"] = {minimum = 0},
    ["damage.minimum"] = {minimum = 0},
    ["fire.rpm"] = {minimum = 0, exclusiveMinimum = true, maximum = 60000},
    ["fire.delay"] = {minimum = 0, exclusiveMinimum = true},
    ["ammo.clipSize"] = {minimum = 0, maximum = 1000000, integer = true},
    ["ammo.defaultClip"] = {minimum = 0, maximum = 1000000, integer = true},
    ["ammo.chamberSize"] = {minimum = 0, maximum = 1000, integer = true},
    ["spread.hip"] = {minimum = 0},
    ["spread.ads"] = {minimum = 0},
    ["spread.movement"] = {minimum = 0},
    ["spread.perShot"] = {minimum = 0},
    ["spread.recovery"] = {minimum = 0},
    ["ballistics.pellets"] = {minimum = 1, maximum = 256, integer = true},
    ["ballistics.muzzleVelocity"] = {minimum = 0},
    ["ballistics.drag"] = {minimum = 0},
    ["ballistics.gravity"] = {},
    ["recoil.scalar"] = {minimum = 0},
    ["camera.shake"] = {minimum = 0},
    ["camera.sway"] = {minimum = 0},
    ["camera.freeAim.radius"] = {minimum = 0},
    ["camera.breathing"] = {minimum = 0},
    ["camera.landing"] = {minimum = 0},
    ["camera.microJitter"] = {},
    ["camera.deadzone"] = {minimum = 0},
    ["animations.reloadDuration"] = {minimum = 0},
    ["ads.fov"] = {minimum = 1, maximum = 179},
    ["ads.speed"] = {minimum = 0},
    ["movement.speed"] = {minimum = 0},
    ["movement.sightedSpeed"] = {minimum = 0},
    ["movement.reloadSpeed"] = {minimum = 0},
    ["movement.sprintToFire"] = {minimum = 0},
    ["movement.aimWalk"] = {minimum = 0}
}

local openModifierPrefixes = {
    "animations.base",
    "animations.layers",
    "animations.events",
    "rendering.bodygroups",
    "rendering.skins",
    "sounds.mechanical",
    "sounds.reload",
    "effects.impact"
}

local function validateModifierNumber(report, path, value, rule)
    if not rule or value == nil then
        return
    end

    if not isFinite(value) then
        invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must be a finite number", value)
        return
    end

    if rule.integer and value ~= math.floor(value) then
        invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must be an integer", value)
    end

    if rule.exclusiveMinimum and value <= rule.minimum then
        invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must be greater than " .. tostring(rule.minimum), value)
    elseif rule.minimum ~= nil and value < rule.minimum then
        invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must be at least " .. tostring(rule.minimum), value)
    end

    if rule.maximum ~= nil and value > rule.maximum then
        invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must be at most " .. tostring(rule.maximum), value)
    end
end

local function knownIRPath(ir, path)
    if Path.Has(ir, path) or optionalIRPaths[path] == true then
        return true
    end

    for _, prefix in ipairs(openModifierPrefixes) do
        if string.sub(path, 1, #prefix + 1) == prefix .. "." then
            return true
        end
    end

    return false
end

local function validateModifier(ir, report, path, modifier)
    if not knownIRPath(ir, path) then
        invalidAttachment(report, "attachment modifier targets unknown IR path '" .. tostring(path) .. "'", modifier)
        return
    end

    local base = Path.Get(ir, path)
    local baseType = type(base)
    local expectedType = base ~= nil and baseType or optionalModifierTypes[path]

    if type(modifier) == "number" then
        if not isFinite(modifier) then
            invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must be finite", modifier)
        elseif expectedType and expectedType ~= "number" then
            invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must match " .. expectedType, modifier)
        end

        validateModifierNumber(report, path, modifier, modifierNumberRules[path])

        return
    end

    if type(modifier) ~= "table" then
        invalidAttachment(report, "attachment modifier '" .. tostring(path) .. "' must be a number or table", modifier)
        return
    end

    local operations = {
        set = true,
        add = true,
        multiply = true,
        minimum = true,
        maximum = true,
        append = true
    }

    for operation, value in pairs(modifier) do
        if not operations[operation] then
            invalidAttachment(
                report,
                "attachment modifier '" .. tostring(path) .. "' has unknown operation '" .. tostring(operation) .. "'",
                modifier
            )
        elseif operation == "set" then
            if expectedType and type(value) ~= expectedType then
                invalidAttachment(
                    report,
                    "attachment modifier '" .. tostring(path) .. ".set' must be a " .. expectedType,
                    modifier
                )
            end

            if expectedType == "string" and type(value) == "string" and value == "" then
                invalidAttachment(
                    report,
                    "attachment modifier '" .. tostring(path) .. ".set' must not be empty",
                    modifier
                )
            end

            validateFiniteTree(value, report, "attachment modifier " .. tostring(path) .. ".set", 1, {}, 64)
        elseif operation == "append" then
            if baseType ~= "table" then
                invalidAttachment(
                    report,
                    "attachment modifier '" .. tostring(path) .. ".append' requires a table IR field",
                    modifier
                )
            elseif type(value) ~= "table" or not Table.IsArray(value) then
                invalidAttachment(
                    report,
                    "attachment modifier '" .. tostring(path) .. ".append' must be an array",
                    modifier
                )
            else
                validateFiniteTree(value, report, "attachment modifier " .. tostring(path) .. ".append", 1, {}, 64)
            end
        else
            if expectedType ~= "number" then
                invalidAttachment(
                    report,
                    "attachment modifier '" .. tostring(path) .. "." .. tostring(operation)
                        .. "' requires a numeric IR field",
                    modifier
                )
            end

            if not isFinite(value) then
                invalidAttachment(
                    report,
                    "attachment modifier '" .. tostring(path) .. "." .. tostring(operation)
                        .. "' must be a finite number",
                    modifier
                )
            end
        end
    end

    local result = base

    if modifier.set ~= nil then
        result = modifier.set
    elseif type(base) == "number" then
        if type(modifier.add) == "number" then
            result = result + modifier.add
        end

        if type(modifier.multiply) == "number" then
            result = result * modifier.multiply
        end

        if type(modifier.minimum) == "number" then
            result = math.max(result, modifier.minimum)
        end

        if type(modifier.maximum) == "number" then
            result = math.min(result, modifier.maximum)
        end
    end

    validateModifierNumber(report, path, result, modifierNumberRules[path])
end

local function validateAttachments(ir, report, limits)
    local attachments = ir.attachments

    if type(attachments) ~= "table" then
        return
    end

    local slots = attachments.slots

    if type(slots) ~= "table" or not Table.IsArray(slots) then
        invalidAttachment(report, "attachments.slots must be an array", slots)
    else
        if #slots > limits.maxAttachmentSlots then
            invalidAttachment(
                report,
                "attachments.slots exceeds maximum count of " .. tostring(limits.maxAttachmentSlots),
                slots
            )
        end

        local slotIds = {}

        for index, slot in ipairs(slots) do
            local prefix = "attachments.slots[" .. tostring(index) .. "]"

            if type(slot) ~= "table" then
                invalidAttachment(report, prefix .. " must be a table", slot)
            elseif type(slot.id) ~= "string" or slot.id == "" then
                invalidAttachment(report, prefix .. ".id must be a non-empty string", slot)
            elseif slotIds[slot.id] then
                invalidAttachment(report, prefix .. ".id duplicates slot '" .. slot.id .. "'", slot)
            else
                slotIds[slot.id] = true
            end

            if type(slot) == "table" then
                local accepted = slot.accepts or slot.types or slot.type

                if accepted ~= nil and type(accepted) ~= "string" and type(accepted) ~= "table" then
                    invalidAttachment(report, prefix .. " attachment type must be a string or array", slot)
                elseif type(accepted) == "table" and not Table.IsArray(accepted) then
                    invalidAttachment(report, prefix .. " attachment types must be an array", slot)
                end

                validateAttachmentMetadata(report, prefix, slot)
            end
        end
    end

    local definitions = attachments.definitions

    if type(definitions) ~= "table" then
        invalidAttachment(report, "attachments.definitions must be a table", definitions)
        return
    end

    local definitionCount = 0

    for attachmentId, definition in pairs(definitions) do
        definitionCount = definitionCount + 1

        if type(attachmentId) ~= "string" or attachmentId == "" then
            invalidAttachment(report, "attachment definition ids must be non-empty strings", definition)
        end

        if type(definition) ~= "table" then
            invalidAttachment(
                report,
                "attachments.definitions." .. tostring(attachmentId) .. " must be a table",
                definition
            )
        elseif definition.modifiers ~= nil and type(definition.modifiers) ~= "table" then
            invalidAttachment(
                report,
                "attachments.definitions." .. tostring(attachmentId) .. ".modifiers must be a table",
                definition
            )
        elseif type(definition) == "table" then
            validateAttachmentMetadata(
                report,
                "attachments.definitions." .. tostring(attachmentId),
                definition
            )

            if definition.icon ~= nil and (type(definition.icon) ~= "string" or definition.icon == "") then
                invalidAttachment(report, "attachment icon must be a non-empty material path", definition)
            end

            local visuals = definition.visuals or definition.visual

            if visuals ~= nil and type(visuals) ~= "table" then
                invalidAttachment(report, "attachment visuals must be a table", definition)
            elseif type(visuals) == "table" then
                for _, realm in ipairs({"view", "world", "viewModel", "worldModel"}) do
                    local visual = visuals[realm]

                    if visual ~= nil and type(visual) ~= "table" then
                        invalidAttachment(report, "attachment visuals." .. realm .. " must be a table", definition)
                    elseif type(visual) == "table" then
                        if visual.model ~= nil and (type(visual.model) ~= "string" or visual.model == "") then
                            invalidAttachment(report, "attachment visuals." .. realm .. ".model must be a non-empty path", definition)
                        end

                        for _, field in ipairs({"bone", "attachment", "material"}) do
                            if visual[field] ~= nil and (type(visual[field]) ~= "string" or visual[field] == "") then
                                invalidAttachment(report, "attachment visuals." .. realm .. "." .. field .. " must be a non-empty string", definition)
                            end
                        end

                        for _, field in ipairs({"pos", "position", "ang", "angle"}) do
                            if visual[field] ~= nil then
                                local value = visual[field]
                                local validVector = (field == "pos" or field == "position")
                                    and type(isvector) == "function" and isvector(value)
                                local validAngle = (field == "ang" or field == "angle")
                                    and type(isangle) == "function" and isangle(value)

                                if type(value) ~= "table" and not validVector and not validAngle then
                                    invalidAttachment(report, "attachment visuals." .. realm .. "." .. field .. " must be a vector/table", definition)
                                end
                            end
                        end

                        if visual.bodygroups ~= nil and type(visual.bodygroups) ~= "table" then
                            invalidAttachment(report, "attachment visuals." .. realm .. ".bodygroups must be a table", definition)
                        end
                    end
                end
            end

            if type(definition.modifiers) == "table" then
                for path, modifier in pairs(definition.modifiers) do
                    if type(path) ~= "string" or path == "" then
                        invalidAttachment(report, "attachment modifier paths must be non-empty strings", definition)
                    else
                        validateModifier(ir, report, path, modifier)
                    end
                end
            end
        end
    end

    if definitionCount > limits.maxAttachmentDefinitions then
        invalidAttachment(
            report,
            "attachments.definitions exceeds maximum count of " .. tostring(limits.maxAttachmentDefinitions),
            definitions
        )
    end
end

local function applyModifierForValidation(value, modifier)
    if type(modifier) ~= "table" then
        return Table.DeepCopy(modifier)
    end

    if modifier.set ~= nil then
        return Table.DeepCopy(modifier.set)
    end

    if type(value) == "number" then
        if type(modifier.add) == "number" then
            value = value + modifier.add
        end

        if type(modifier.multiply) == "number" then
            value = value * modifier.multiply
        end

        if type(modifier.minimum) == "number" then
            value = math.max(value, modifier.minimum)
        end

        if type(modifier.maximum) == "number" then
            value = math.min(value, modifier.maximum)
        end
    elseif type(value) == "table" and modifier.append then
        value = Table.ArrayCopy(value)

        for _, item in ipairs(modifier.append) do
            value[#value + 1] = Table.DeepCopy(item)
        end
    end

    return value
end

local function validateAttachmentEffectiveValues(ir, report)
    local definitions = ir.attachments and ir.attachments.definitions or {}

    for attachmentId, definition in pairs(definitions) do
        if type(definition) == "table" and type(definition.modifiers) == "table" then
            local effective = FTBase.IR.Clone(ir)

            for path, modifier in pairs(definition.modifiers) do
                local current = Path.Get(effective, path)
                Path.Set(effective, path, applyModifierForValidation(current, modifier))
            end

            -- The attachment schema itself has already been checked above;
            -- clear it for the effective-value pass to avoid recursive checks.
            effective.attachments.slots = {}
            effective.attachments.definitions = {}

            local effectiveReport = FTBase.Report.New("attachment-validation")
            Validator.Validate(effective, effectiveReport)

            for _, item in ipairs(effectiveReport.errors or {}) do
                report:AddError(
                    "attachment '" .. tostring(attachmentId) .. "' produces invalid " .. tostring(item.message),
                    definition
                )
            end
        end
    end
end

local function validateUIMetadata(ir, report)
    local ui = ir.ui

    if type(ui) ~= "table" then
        return
    end

    local inspect = ui.inspect
    local customization = ui.customization

    if type(inspect) == "table" then
        validateMetadataValue(report, "ui.inspect.description", inspect.description, true)
        validateMetadataValue(report, "ui.inspect.credits", inspect.credits, true)
        validateMetadataValue(report, "ui.inspect.preview", inspect.preview, false)
        validateMetadataValue(report, "ui.inspect.stats", inspect.stats, false)
        validateMetadataValue(report, "ui.inspect.falloff", inspect.falloff, false)
        validateMetadataValue(report, "ui.inspect.hints", inspect.hints, true)
    end

    if type(customization) == "table" then
        if customization.source ~= nil and type(customization.source) ~= "string" then
            addError(report, "ui.customization.source must be a string")
        end

        validateMetadataValue(report, "ui.customization.presets", customization.presets, false)
        validateMetadataValue(report, "ui.customization.controls", customization.controls, false)
        validateMetadataValue(report, "ui.customization.stats", customization.stats, false)
        validateMetadataValue(report, "ui.customization.hints", customization.hints, true)
        validateMetadataValue(report, "ui.customization.preview", customization.preview, false)
        validateMetadataValue(report, "ui.customization.animations", customization.animations, false)
    end
end

function Validator.Validate(ir, report)
    report = report or FTBase.Report.New("validation")

    if type(ir) ~= "table" then
        addError(report, "IR must be a table")
        return report
    end

    local limits = FTBase.Compiler and FTBase.Compiler.Limits or {
        maxDepth = 64,
        maxAttachmentSlots = 64,
        maxAttachmentDefinitions = 256
    }

    for _, domain in ipairs(FTBase.Schema and FTBase.Schema.domains or {}) do
        validateType(ir, report, domain, "table", false)
    end

    local tablePaths = {
        "damage.curve", "damage.hitgroups", "damage.armor",
        "fire.modes",
        "ballistics.penetration", "ballistics.armor", "ballistics.ricochet",
        "ballistics.fragments", "ballistics.materialResponses", "ballistics.damageCurve",
        "recoil.pattern", "recoil.procedural", "recoil.styles",
        "camera.freeAim", "camera.spring", "camera.sprint",
        "animations.base", "animations.layers", "animations.ik", "animations.procedural",
        "animations.events", "animations.curves", "animations.reloadStages", "animations.partialBody",
        "sounds.fire", "sounds.fire.layers", "sounds.mechanical", "sounds.reload",
        "networking.variables", "networking.events",
        "npc.burst", "npc.rest",
        "vehicles.constraints", "physics.projectile", "physics.springs",
        "rendering.bodygroups", "rendering.skins",
        "ui.inspect", "ui.customization", "ui.visual", "ui.visual.providers"
    }

    for _, path in ipairs(tablePaths) do
        validateType(ir, report, path, "table", false)
    end

    local wind = Path.Get(ir, "ballistics.wind")
    local windIsVector = type(isvector) == "function" and isvector(wind)

    if type(wind) ~= "table" and not windIsVector then
        addError(report, "ballistics.wind must be a vector or table")
    end

    local numberSpecs = {
        {path = "damage.base", minimum = 0},
        {path = "damage.minimum", minimum = 0},
        {path = "damage.armor.scale", minimum = 0},
        {path = "fire.rpm", exclusiveMinimum = 0, maximum = 60000},
        {path = "fire.delay", exclusiveMinimum = 0, optional = true},
        {path = "fire.burst", minimum = 0, maximum = 1000, integer = true},
        {path = "ammo.clipSize", minimum = 0, maximum = 1000000, integer = true},
        {path = "ammo.defaultClip", minimum = 0, maximum = 1000000, integer = true},
        {path = "ammo.chamberSize", minimum = 0, maximum = 1000, integer = true},
        {path = "spread.hip", minimum = 0},
        {path = "spread.ads", minimum = 0},
        {path = "spread.movement", minimum = 0},
        {path = "spread.perShot", minimum = 0},
        {path = "spread.recovery", minimum = 0},
        {path = "ballistics.pellets", minimum = 1, maximum = 256, integer = true},
        {path = "ballistics.muzzleVelocity", minimum = 0},
        {path = "ballistics.drag", minimum = 0},
        {path = "ballistics.gravity"},
        {path = "ballistics.penetration.power", minimum = 0},
        {path = "ballistics.armor.scale", minimum = 0},
        {path = "ballistics.ricochet.chance", minimum = 0, maximum = 1},
        {path = "ballistics.ricochet.angle", minimum = 0, maximum = 180},
        {path = "recoil.scalar", minimum = 0},
        {path = "camera.shake", minimum = 0},
        {path = "camera.sway", minimum = 0},
        {path = "camera.freeAim.radius", minimum = 0},
        {path = "camera.spring.stiffness", minimum = 0},
        {path = "camera.spring.damping", minimum = 0},
        {path = "camera.breathing", minimum = 0},
        {path = "camera.landing", minimum = 0},
        {path = "camera.microJitter"},
        {path = "camera.deadzone", minimum = 0},
        {path = "camera.aimTransition", minimum = 0},
        {path = "ads.fov", minimum = 1, maximum = 179},
        {path = "ads.speed", minimum = 0},
        {path = "ads.magnification", minimum = 0},
        {path = "rendering.viewModelFOV", minimum = 1, maximum = 179, optional = true},
        {path = "animations.reloadDuration", minimum = 0, optional = true},
        {path = "sounds.occlusion.scale", minimum = 0},
        {path = "movement.speed", minimum = 0},
        {path = "movement.sightedSpeed", minimum = 0},
        {path = "movement.reloadSpeed", minimum = 0},
        {path = "movement.sprintToFire", minimum = 0},
        {path = "movement.aimWalk", minimum = 0},
        {path = "npc.burst.minimum", minimum = 0, integer = true},
        {path = "npc.burst.maximum", minimum = 0, integer = true},
        {path = "npc.rest.minimum", minimum = 0},
        {path = "npc.rest.maximum", minimum = 0},
        {path = "npc.proficiency", minimum = 0}
    }

    for _, spec in ipairs(numberSpecs) do
        validateNumber(ir, report, spec)
    end

    local booleanPaths = {
        "meta.spawnable", "fire.automatic", "ballistics.travelTime", "ballistics.armor.enabled",
        "ballistics.ricochet.enabled", "camera.freeAim.enabled", "sounds.occlusion.enabled",
        "sounds.suppression.enabled", "prediction.rollback", "movement.blindFire", "npc.enabled",
        "vehicles.enabled", "rendering.useHands", "rendering.viewModelFlip", "ui.drawAmmo", "ui.crosshair",
        "ui.inspect.enabled", "ui.inspect.blur", "ui.inspect.hideHud"
    }

    for _, path in ipairs(booleanPaths) do
        validateType(ir, report, path, "boolean", false)
    end

    validateUIMetadata(ir, report)

    local stringPaths = {
        "meta.id", "meta.printName", "meta.category", "meta.author", "ammo.type",
        "damage.armor.mode", "recoil.mode", "recoil.interpolation", "networking.compression",
        "prediction.seedMode", "rendering.holdType", "ui.inspect.command", "ui.inspect.title",
        "ui.inspect.type", "ui.customization.provider", "ui.customization.title",
        "ui.customization.openCommand"
    }

    for _, path in ipairs(stringPaths) do
        validateType(ir, report, path, "string", false)
    end

    for _, path in ipairs({"rendering.viewModel", "rendering.worldModel"}) do
        local model = Path.Get(ir, path)

        if model ~= nil and (type(model) ~= "string" or model == "") then
            addError(report, path .. " must be a non-empty string when provided")
        end
    end

    validateEnum(ir, report, "ballistics.mode", {hitscan = true, projectile = true, hybrid = true})

    if Path.Get(ir, "ballistics.mode") == "projectile"
        and (not isFinite(Path.Get(ir, "ballistics.muzzleVelocity")) or Path.Get(ir, "ballistics.muzzleVelocity") <= 0) then
        addError(report, "ballistics.muzzleVelocity must be greater than 0 in projectile mode")
    end

    local projectile = Path.Get(ir, "physics.projectile")

    if type(projectile) == "table" then
        if projectile.model ~= nil
            and (type(projectile.model) ~= "string" or projectile.model == "") then
            addError(report, "physics.projectile.model must be a non-empty string")
        end

        for _, field in ipairs({"gravity", "drag", "muzzleVelocity"}) do
            if projectile[field] ~= nil and not isFinite(projectile[field]) then
                addError(report, "physics.projectile." .. field .. " must be a finite number")
            end
        end
    end

    validateAttachments(ir, report, limits)
    validateFiniteTree(ir, report, "ir", 1, {}, limits.maxDepth)

    if not report:HasErrors() then
        validateAttachmentEffectiveValues(ir, report)
    end

    if type(ir.sounds) == "table" and type(ir.sounds.fire) == "table"
        and (type(ir.sounds.fire.layers) ~= "table" or #ir.sounds.fire.layers == 0) then
        report:AddMissingSound("sounds.fire.layers")
    end

    if type(ir.animations) == "table" and type(ir.animations.base) == "table"
        and not ir.animations.base.reload then
        report:AddMissingAnimation("animations.base.reload")
    end

    if not report:HasErrors() then
        for _, plugin in ipairs(FTBase.Plugin and FTBase.Plugin.GetAll() or {}) do
            if plugin.Validate then
                plugin.Validate(ir, report)
            end
        end
    end

    return report
end

FTBase.Validator = Validator
