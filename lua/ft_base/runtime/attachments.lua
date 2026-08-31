FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Attachments = FTBase.Module.Define("Attachments", {})

local Path = FTBase.Util.Path
local Table = FTBase.Util.Table

local function slotById(slots, slotId)
    for _, slot in ipairs(slots or {}) do
        if slot.id == slotId then
            return slot
        end
    end

    return nil
end

local function acceptsType(slot, attachment)
    local accepted = slot.accepts or slot.types or slot.type
    local attachmentType = attachment.type or attachment.slotType

    if accepted == nil or accepted == "any" then
        return true
    end

    if type(accepted) == "string" then
        return accepted == attachmentType
    end

    for _, value in ipairs(accepted) do
        if value == attachmentType then
            return true
        end
    end

    return false
end

local function applyModifier(value, modifier)
    if type(modifier) ~= "table" then
        return modifier
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

local function buildEffectiveIR(runtime, previewSlotId, previewAttachmentId)
    local effective = FTBase.IR.Clone(runtime.ir)

    for _, slot in ipairs(runtime.attachments.slots or {}) do
        local attachmentId = runtime.attachments.installed[slot.id]

        if slot.id == previewSlotId then
            attachmentId = previewAttachmentId
        end

        local definition = attachmentId
            and runtime.ir.attachments
            and runtime.ir.attachments.definitions
            and runtime.ir.attachments.definitions[attachmentId]
        local modifiers = definition and definition.modifiers

        if slot.id ~= previewSlotId and not attachmentId and runtime.attachmentModifiers then
            modifiers = runtime.attachmentModifiers[slot.id]
        end

        for irPath, modifier in pairs(modifiers or {}) do
            local value = Path.Get(effective, irPath)

            if value ~= nil or type(modifier) ~= "table" or modifier.set ~= nil then
                Path.Set(effective, irPath, applyModifier(value, modifier))
            end
        end
    end

    return effective
end

function Attachments.NewState(ir)
    ir = ir or {}
    local attachments = ir.attachments or {}
    local state = {
        installed = {},
        slots = FTBase.Util.Table.DeepCopy(attachments.slots or {})
    }

    for _, slot in ipairs(state.slots) do
        local attachmentId = slot.default or slot.defaultAttachment
        local definition = attachmentId and (attachments.definitions or {})[attachmentId]

        if definition and not definition.hidden and not definition.disabled and acceptsType(slot, definition) then
            state.installed[slot.id] = attachmentId
        end
    end

    return state
end

function Attachments.Install(runtime, slotId, attachmentId)
    local allowed, reason = Attachments.CanInstall(runtime, slotId, attachmentId)

    if not allowed then
        return false, reason
    end

    if runtime.attachments.installed[slotId] == attachmentId then
        return false, "Attachment is already installed"
    end

    runtime.attachments.installed[slotId] = attachmentId
    Attachments.RebuildModifiers(runtime)
    return true
end

function Attachments.Uninstall(runtime, slotId)
    if not slotById(runtime.attachments.slots, slotId) then
        return false, "Unknown attachment slot"
    end

    if runtime.attachments.installed[slotId] == nil then
        return false, "Attachment slot is already empty"
    end

    runtime.attachments.installed[slotId] = nil
    Attachments.RebuildModifiers(runtime)
    return true
end

function Attachments.CanInstall(runtime, slotId, attachmentId)
    if not runtime or not runtime.attachments then
        return false, "Weapon runtime is unavailable"
    end

    local slot = slotById(runtime.attachments.slots, slotId)

    if not slot then
        return false, "Unknown attachment slot"
    end

    local attachment = (runtime.ir.attachments.definitions or {})[attachmentId]

    if not attachment then
        return false, "Unknown attachment"
    end

    if attachment.hidden or attachment.disabled then
        return false, "Attachment is unavailable"
    end

    if not acceptsType(slot, attachment) then
        return false, "Attachment does not fit this slot"
    end

    return true
end

function Attachments.GetSlot(runtime, slotId)
    return runtime and runtime.attachments and slotById(runtime.attachments.slots, slotId) or nil
end

function Attachments.GetDefinition(runtime, attachmentId)
    return runtime and runtime.ir and runtime.ir.attachments.definitions[attachmentId] or nil
end

function Attachments.GetEffectiveIR(runtime)
    return runtime and (runtime.effectiveIR or runtime.ir) or nil
end

-- Build a temporary effective IR for UI preview without changing installed
-- attachments, cooldowns, or server-owned state.  The candidate is validated
-- against the same slot rules as an install request.
function Attachments.PreviewIR(runtime, slotId, attachmentId)
    if not runtime or not runtime.attachments then
        return nil, "Weapon runtime is unavailable"
    end

    if attachmentId ~= nil and attachmentId ~= "" then
        local allowed, reason = Attachments.CanInstall(runtime, slotId, attachmentId)

        if not allowed then
            return nil, reason
        end
    end

    return buildEffectiveIR(runtime, slotId, attachmentId)
end

local function readPath(value, path)
    if FTBase.Util and FTBase.Util.Path and FTBase.Util.Path.Get then
        return FTBase.Util.Path.Get(value, path)
    end

    return nil
end

local function formatComparable(value)
    if type(value) == "number" then
        return value
    end

    if type(value) == "table" then
        return FTBase.Util.Table.DeepCopy(value)
    end

    return value
end

function Attachments.GetStatDiff(baseIR, previewIR, paths)
    local output = {}

    for _, entry in ipairs(paths or {}) do
        local path = type(entry) == "table" and entry.path or entry
        local label = type(entry) == "table" and (entry.label or entry.name) or path

        if type(path) == "string" and path ~= "" then
            local before = formatComparable(readPath(baseIR, path))
            local after = formatComparable(readPath(previewIR, path))

            output[#output + 1] = {
                path = path,
                label = label or path,
                before = before,
                after = after,
                changed = before ~= after
            }
        end
    end

    return output
end

function Attachments.RebuildModifiers(runtime)
    if not runtime or not runtime.attachments then
        return nil
    end

    runtime.attachmentModifiers = {}

    local attachments = runtime.ir.attachments or {}
    local definitions = attachments.definitions or {}
    local installed = {}

    for slotId, attachmentId in pairs(runtime.attachments.installed or {}) do
        local definition = definitions[attachmentId]
        local slot = slotById(runtime.attachments.slots, slotId)

        if slot and definition and not definition.hidden and not definition.disabled and acceptsType(slot, definition) then
            installed[slotId] = attachmentId

            if definition.modifiers then
                runtime.attachmentModifiers[slotId] = definition.modifiers
            end
        end
    end

    runtime.attachments.installed = installed
    runtime.effectiveIR = buildEffectiveIR(runtime)

    if CLIENT and FTBase.Runtime.AttachmentVisuals then
        FTBase.Runtime.AttachmentVisuals.Refresh(runtime)
    end

    if runtime.onEffectiveIRChanged then
        runtime.onEffectiveIRChanged(runtime.effectiveIR)
    end

    return runtime.effectiveIR
end

function Attachments.ApplyNumber(runtime, irPath, baseValue)
    local value = baseValue

    for _, slot in ipairs(runtime.attachments.slots or {}) do
        local modifiers = runtime.attachmentModifiers[slot.id]
        local modifier = modifiers and modifiers[irPath]

        if type(modifier) == "number" then
            value = modifier
        elseif type(modifier) == "table" then
            value = applyModifier(value, modifier)
        end
    end

    return value
end

FTBase.Runtime.Attachments = Attachments
