FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Customization = FTBase.Module.Define("Customization", {})

function Customization.GetSlots(runtime)
    return runtime.attachments and runtime.attachments.slots or {}
end

function Customization.Install(runtime, slotId, attachmentId)
    return FTBase.Runtime.Attachments.Install(runtime, slotId, attachmentId)
end

function Customization.Uninstall(runtime, slotId)
    return FTBase.Runtime.Attachments.Uninstall(runtime, slotId)
end

FTBase.Runtime.Customization = Customization
