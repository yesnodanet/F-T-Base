FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Customization = FTBase.Module.Define("Customization", {})
local Host = FTBase.Runtime.ProviderHost

function Customization.RegisterProvider(id, provider)
    return Host and Host.Register and Host.Register(id, provider) or false
end

function Customization.GetProvider(runtime, domain)
    if Host and Host.GetProvider then
        return Host.GetProvider(runtime, domain or "attachments")
    end

    return nil, "ft"
end

function Customization.GetInspectProvider(runtime)
    return Customization.GetProvider(runtime, "inspect")
end

function Customization.Open(swep)
    if not CLIENT or not swep or not swep.FTRuntime then
        return false
    end

    local provider = Customization.GetProvider(swep.FTRuntime, "attachments")

    if FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Open then
        return FTBase.Runtime.Inspect.Open(swep, provider and provider.id)
    end

    return false
end

function Customization.Close(swep)
    local provider = swep and swep.FTRuntime and Customization.GetProvider(swep.FTRuntime, "attachments")

    if provider and provider.Close then
        provider:Close(swep)
    end

    if FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Close then
        return FTBase.Runtime.Inspect.Close(swep)
    end

    return false
end

function Customization.Refresh(swep)
    local provider = swep and swep.FTRuntime and Customization.GetProvider(swep.FTRuntime, "attachments")

    if provider and provider.Refresh then
        provider:Refresh(swep, FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Active)
    end

    if FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Refresh then
        return FTBase.Runtime.Inspect.Refresh(swep)
    end

    return false
end

function Customization.GetSlots(runtime)
    local provider = Customization.GetProvider(runtime, "attachments")
    return provider and provider.GetSlots and provider:GetSlots(runtime) or {}
end

function Customization.GetOptions(runtime, slotId)
    local provider = Customization.GetProvider(runtime, "attachments")
    return provider and provider.GetOptions and provider:GetOptions(runtime, slotId) or {}
end

function Customization.GetInspectData(runtime, slotId)
    local provider = Customization.GetProvider(runtime, "inspect")
    return provider and provider.GetInspectData and provider:GetInspectData(runtime, slotId) or {}
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

function Customization.BuildAttachmentRequest(runtime, slotId, attachmentId)
    local provider = Customization.GetProvider(runtime, "attachments")

    if provider and provider.BuildAttachmentRequest then
        return provider:BuildAttachmentRequest(slotId, attachmentId)
    end

    return {slotId = tostring(slotId or ""), attachmentId = tostring(attachmentId or "")}
end

function Customization.GetEffectiveIR(runtime)
    return FTBase.Runtime.Attachments.GetEffectiveIR(runtime)
end

-- Keep the public registry aliases used by older F&T templates. Definitions
-- are registered by runtime/visuals.lua after the host has been loaded.
Customization.Providers = Host and Host.GetAll and Host.GetAll() or {}

FTBase.Runtime.Customization = Customization
