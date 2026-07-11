FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Customization = FTBase.Module.Define("Customization", {})

local Table = FTBase.Util.Table

function Customization.GetSlots(runtime)
    return runtime.attachments and runtime.attachments.slots or {}
end

function Customization.Install(runtime, slotId, attachmentId)
    return FTBase.Runtime.Attachments.Install(runtime, slotId, attachmentId)
end

function Customization.Uninstall(runtime, slotId)
    return FTBase.Runtime.Attachments.Uninstall(runtime, slotId)
end

function Customization.CanInstall(runtime, slotId, attachmentId)
    return FTBase.Runtime.Attachments.CanInstall(runtime, slotId, attachmentId)
end

function Customization.GetOptions(runtime, slotId)
    local options = {}
    local definitions = runtime and runtime.ir.attachments.definitions or {}

    for _, attachmentId in ipairs(Table.Keys(definitions)) do
        local allowed = Customization.CanInstall(runtime, slotId, attachmentId)

        if allowed then
            local definition = definitions[attachmentId]
            options[#options + 1] = {
                id = attachmentId,
                name = definition.name or attachmentId,
                description = definition.description or "",
                definition = definition
            }
        end
    end

    return options
end

function Customization.GetEffectiveIR(runtime)
    return FTBase.Runtime.Attachments.GetEffectiveIR(runtime)
end

FTBase.Runtime.Customization = Customization
