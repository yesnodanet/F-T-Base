FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}
FTBase.Runtime.UI = FTBase.Runtime.UI or {}

local Context = FTBase.Module.Define("RuntimeUIContext", {})
local Toolkit = FTBase.Runtime.UI.Toolkit

local function now()
    return CurTime and CurTime() or os.clock()
end

local function providerFor(runtime, domain)
    if FTBase.Runtime.ProviderHost and FTBase.Runtime.ProviderHost.GetProvider then
        return FTBase.Runtime.ProviderHost.GetProvider(runtime, domain)
    end

    return nil
end

function Context.New(swep, runtime, domain, root, inspectProvider, attachmentProvider)
    runtime = runtime or swep and swep.FTRuntime or nil
    local context = {
        swep = swep,
        runtime = runtime,
        ir = runtime and runtime.ir or {},
        effectiveIR = runtime and (FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir) or {},
        domain = domain or "inspect",
        root = root,
        inspectProvider = inspectProvider or providerFor(runtime, "inspect"),
        attachmentsProvider = attachmentProvider or providerFor(runtime, "attachments"),
        state = runtime and (runtime.ftUIState or {}) or {},
        createdAt = now()
    }

    if runtime then
        runtime.ftUIState = context.state
    end

    context.provider = context.inspectProvider
    context.Toolkit = Toolkit

    function context:RequestAttachment(slotId, attachmentId)
        self.state.pendingRequest = {
            slotId = tostring(slotId or ""),
            attachmentId = tostring(attachmentId or ""),
            time = now()
        }

        return Toolkit.Request(self, slotId, attachmentId)
    end

    function context:Refresh(reason)
        self.state.lastRefreshReason = reason

        if FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Refresh then
            return FTBase.Runtime.Inspect.Refresh(self.swep, reason)
        end

        return false
    end

    function context:Close()
        if FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Close then
            return FTBase.Runtime.Inspect.Close(self.swep)
        end

        return false
    end

    function context:GetEffectiveIR()
        return self.runtime and (FTBase.Runtime.Attachments.GetEffectiveIR(self.runtime) or self.runtime.ir) or self.effectiveIR
    end

    function context:GetSlot(slotId)
        return FTBase.Runtime.Attachments and FTBase.Runtime.Attachments.GetSlot
            and FTBase.Runtime.Attachments.GetSlot(self.runtime, slotId) or nil
    end

    function context:GetDefinition(attachmentId)
        return FTBase.Runtime.Attachments and FTBase.Runtime.Attachments.GetDefinition
            and FTBase.Runtime.Attachments.GetDefinition(self.runtime, attachmentId) or nil
    end

    function context:CanInstall(slotId, attachmentId)
        return FTBase.Runtime.Attachments and FTBase.Runtime.Attachments.CanInstall
            and FTBase.Runtime.Attachments.CanInstall(self.runtime, slotId, attachmentId) or false
    end

    return context
end

function Context.Sync(context)
    if not context then
        return nil
    end

    context.ir = context.runtime and context.runtime.ir or context.ir or {}
    context.effectiveIR = context.runtime
        and (FTBase.Runtime.Attachments.GetEffectiveIR(context.runtime) or context.runtime.ir)
        or context.effectiveIR or {}
    return context
end

FTBase.Runtime.UI.Context = Context
