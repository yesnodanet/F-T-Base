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

local function buildEffectiveIR(runtime)
    local effective = FTBase.IR.Clone(runtime.ir)

    for _, slot in ipairs(runtime.attachments.slots or {}) do
        local modifiers = runtime.attachmentModifiers[slot.id]

        for irPath, modifier in pairs(modifiers or {}) do
            local value = Path.Get(effective, irPath)

            if value ~= nil then
                Path.Set(effective, irPath, applyModifier(value, modifier))
            end
        end
    end

    return effective
end

function Attachments.NewState(ir)
    local state = {
        installed = {},
        slots = FTBase.Util.Table.DeepCopy(ir.attachments.slots or {})
    }

    for _, slot in ipairs(state.slots) do
        local attachmentId = slot.default or slot.defaultAttachment
        local definition = attachmentId and (ir.attachments.definitions or {})[attachmentId]

        if definition and acceptsType(slot, definition) then
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

    runtime.attachments.installed[slotId] = attachmentId
    Attachments.RebuildModifiers(runtime)
    return true
end

function Attachments.Uninstall(runtime, slotId)
    if not slotById(runtime.attachments.slots, slotId) then
        return false, "Unknown attachment slot"
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

function Attachments.RebuildModifiers(runtime)
    runtime.attachmentModifiers = {}

    local definitions = runtime.ir.attachments.definitions or {}

    for slotId, attachmentId in pairs(runtime.attachments.installed or {}) do
        local definition = definitions[attachmentId]

        if definition and definition.modifiers then
            runtime.attachmentModifiers[slotId] = definition.modifiers
        end
    end

    runtime.effectiveIR = buildEffectiveIR(runtime)
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
