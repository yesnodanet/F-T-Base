FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Attachments = FTBase.Module.Define("Attachments", {})

function Attachments.NewState(ir)
    local state = {
        installed = {},
        slots = FTBase.Util.Table.DeepCopy(ir.attachments.slots or {})
    }

    return state
end

function Attachments.Install(runtime, slotId, attachmentId)
    runtime.attachments.installed[slotId] = attachmentId
    Attachments.RebuildModifiers(runtime)
end

function Attachments.Uninstall(runtime, slotId)
    runtime.attachments.installed[slotId] = nil
    Attachments.RebuildModifiers(runtime)
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
end

function Attachments.ApplyNumber(runtime, irPath, baseValue)
    local value = baseValue

    for _, modifiers in pairs(runtime.attachmentModifiers or {}) do
        local modifier = modifiers[irPath]

        if type(modifier) == "number" then
            value = value + modifier
        elseif type(modifier) == "table" then
            if modifier.add then
                value = value + modifier.add
            end

            if modifier.multiply then
                value = value * modifier.multiply
            end
        end
    end

    return value
end

FTBase.Runtime.Attachments = Attachments
