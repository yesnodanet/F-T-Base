FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Inspect = FTBase.Module.Define("Inspect", {
    Active = nil,
    InputDebounce = 0.2
})

local function currentTime()
    return CurTime and CurTime() or os.clock()
end

local function validWeapon(swep)
    if not swep or not swep.FTRuntime then
        return false
    end

    return not IsValid or IsValid(swep)
end

local function validPanel(panel)
    return panel and (not IsValid or IsValid(panel))
end

local function providerForDomain(runtime, domain)
    if FTBase.Runtime.Visuals then
        return FTBase.Runtime.Visuals.GetProvider(runtime, domain)
    end

    return FTBase.Runtime.Customization.GetProvider(runtime)
end

local function providerShell(provider)
    return provider and provider.shell or {}
end

local function notifyProvidersClosed(frame)
    if not frame or frame.FTProvidersClosed then
        return
    end

    frame.FTProvidersClosed = true
    local swep = frame.FTWeapon
    local runtime = swep and swep.FTRuntime
    local context = frame.FTUIContext
    local inspectProvider = frame.FTInspectProvider
        or (runtime and providerForDomain(runtime, "inspect"))
    local attachmentProvider = frame.FTAttachmentProvider
        or (runtime and FTBase.Runtime.Customization.GetProvider(runtime, "attachments"))

    if inspectProvider and inspectProvider.Close then
        inspectProvider:Close(context or swep, frame)
    end

    if attachmentProvider and attachmentProvider ~= inspectProvider and attachmentProvider.Close then
        attachmentProvider:Close(context or swep, frame)
    end

    if runtime then
        runtime.customizationOpen = false
    end

    if runtime and FTBase.Runtime.Animation then
        FTBase.Runtime.Animation.Play(swep, runtime, "idle")
    end
end

local function createPopup()
    -- The host owns only popup/input lifecycle.  Every visible surface is
    -- mounted by the selected provider below, so there is no shared FT chrome.
    local panel = vgui.Create("DPanel")

    panel.Close = function(self)
        if self.FTClosing then
            return
        end

        self.FTClosing = true

        if self.OnClose then
            self:OnClose()
        end

        self:Remove()
    end

    panel.OnKeyCodePressed = function(self, code)
        if code == KEY_ESCAPE then
            self:Close()
        end
    end

    return panel
end

local function mountProviderUI(frame, context)
    if validPanel(frame.FTProviderUI) then
        frame.FTProviderUI:Remove()
    end

    local provider = frame.FTInspectProvider

    if not provider or not provider.CreateUI then
        return false
    end

    local created = provider:CreateUI(context, frame)
    frame.FTProviderUI = created
    return created ~= false and created ~= nil
end

function Inspect.Open(swep, providerId)
    if not CLIENT or not vgui or not validWeapon(swep) then
        return false
    end

    if validPanel(Inspect.Active) and Inspect.Active.FTWeapon == swep then
        Inspect.Refresh(swep)
        return true
    end

    Inspect.Close()

    local runtime = swep.FTRuntime
    local attachmentProvider = FTBase.Runtime.Customization.GetProvider(runtime, "attachments")
    local inspectProvider = providerForDomain(runtime, "inspect")

    if providerId and FTBase.Runtime.ProviderHost and FTBase.Runtime.ProviderHost.Get then
        attachmentProvider = FTBase.Runtime.ProviderHost.Get(providerId) or attachmentProvider
    end

    local ir = FTBase.Runtime.Customization.GetEffectiveIR(runtime)
    local inspectAnimation = ir.ui and ir.ui.inspect and ir.ui.inspect.animation
        or ir.animations and ir.animations.inspect

    runtime.customizationOpen = true

    if inspectAnimation ~= nil and FTBase.Runtime.Animation.PlaySequence then
        FTBase.Runtime.Animation.PlaySequence(swep, runtime, "inspect", inspectAnimation)
    else
        FTBase.Runtime.Animation.Play(swep, runtime, "inspect")
    end

    local shell = providerShell(inspectProvider)
    local frameConfig = shell.frame or inspectProvider.frame or {width = 920, height = 600}
    local fullscreen = shell.mode == "fullscreen" or shell.fullscreen == true
    local width = fullscreen and (ScrW and ScrW() or frameConfig.width or 920)
        or frameConfig.width or 920
    local height = fullscreen and (ScrH and ScrH() or frameConfig.height or 600)
        or frameConfig.height or 600
    local frame = createPopup()

    frame:SetSize(width, height)

    if fullscreen then
        frame:SetPos(0, 0)
    else
        frame:Center()
    end

    frame.FTWeapon = swep
    frame.FTProvider = attachmentProvider
    frame.FTInspectProvider = inspectProvider
    frame.FTAttachmentProvider = attachmentProvider
    frame.FTAttachmentProviderId = attachmentProvider and attachmentProvider.id or "ft"
    frame.FTInspectProviderId = inspectProvider and inspectProvider.id or "ft"
    frame.OnClose = function()
        notifyProvidersClosed(frame)

        if Inspect.Active == frame then
            Inspect.Active = nil
        end
    end

    frame.Think = function(panel)
        if not validWeapon(swep) then
            panel:Close()
            return
        end

        local owner = swep.GetOwner and swep:GetOwner() or nil
        local active = owner and owner.GetActiveWeapon and owner:GetActiveWeapon() or swep

        if active and active ~= swep then
            panel:Close()
        end
    end

    if frame.SetMouseInputEnabled then
        frame:SetMouseInputEnabled(true)
    end

    if frame.SetKeyboardInputEnabled then
        frame:SetKeyboardInputEnabled(true)
    end

    local ui = FTBase.Runtime.UI
    local context = ui and ui.Context and ui.Context.New
        and ui.Context.New(swep, runtime, "inspect", frame,
            inspectProvider, attachmentProvider)
        or FTBase.Runtime.ProviderHost.BuildContext(swep, "inspect")
    context.root = frame
    context.inspectProvider = inspectProvider
    context.attachmentsProvider = attachmentProvider
    context.provider = inspectProvider
    frame.FTUIContext = context

    frame:MakePopup()
    Inspect.Active = frame

    if inspectProvider and inspectProvider.Open then
        inspectProvider:Open(context, frame)
    end

    if attachmentProvider and attachmentProvider ~= inspectProvider and attachmentProvider.Open then
        attachmentProvider:Open(context, frame)
    end

    if not mountProviderUI(frame, context) then
        frame:Close()
        return false
    end

    return true
end

function Inspect.Close(swep)
    local frame = Inspect.Active

    if not validPanel(frame) then
        Inspect.Active = nil
        return
    end

    if swep and frame.FTWeapon ~= swep then
        return
    end

    notifyProvidersClosed(frame)
    frame:Close()
end

function Inspect.IsOpen(swep)
    return validPanel(Inspect.Active) and (not swep or Inspect.Active.FTWeapon == swep)
end

function Inspect.Toggle(swep)
    if validPanel(Inspect.Active) and Inspect.Active.FTWeapon == swep then
        Inspect.Close(swep)
        return false
    end

    return Inspect.Open(swep)
end

function Inspect.ToggleFromInput(swep)
    if not validWeapon(swep) then
        return false
    end

    local runtime = swep.FTRuntime
    local time = currentTime()

    if time < (runtime.inspectNextToggle or 0) then
        return false
    end

    runtime.inspectNextToggle = time + Inspect.InputDebounce
    return Inspect.Toggle(swep)
end

function Inspect.UpdateInput(swep)
    if not CLIENT or not validWeapon(swep) then
        return false
    end

    local runtime = swep.FTRuntime
    local frame = validPanel(Inspect.Active) and Inspect.Active.FTWeapon == swep
        and Inspect.Active or nil
    local context = frame and frame.FTUIContext
    local inspectProvider = frame and frame.FTInspectProvider
        or providerForDomain(runtime, "inspect")
    local attachmentProvider = frame and frame.FTAttachmentProvider
        or FTBase.Runtime.Customization.GetProvider(runtime, "attachments")
    local handled = false

    if inspectProvider and inspectProvider.HandleInput then
        handled = inspectProvider:HandleInput(context or swep, frame or runtime) or handled
    end

    if attachmentProvider and attachmentProvider ~= inspectProvider
        and attachmentProvider.HandleInput then
        handled = attachmentProvider:HandleInput(context or swep, frame or runtime) or handled
    end

    if handled then
        return true
    end
    local owner = swep.GetOwner and swep:GetOwner()

    if not owner or owner ~= LocalPlayer() or not owner.KeyDown then
        runtime.inspectComboDown = false
        runtime.inspectUseDown = false
        return false
    end

    local useDown = IN_USE and owner:KeyDown(IN_USE) or false
    local reloadDown = IN_RELOAD and owner:KeyDown(IN_RELOAD) or false
    local comboDown = useDown and reloadDown

    if not useDown then
        runtime.inspectUseDown = false
    end

    if not comboDown then
        runtime.inspectComboDown = false
        return false
    end

    if runtime.inspectComboDown then
        return false
    end

    runtime.inspectComboDown = true
    runtime.inspectUseDown = true
    return Inspect.ToggleFromInput(swep)
end

function Inspect.Refresh(swep)
    local frame = Inspect.Active

    if not validPanel(frame) or frame.FTWeapon ~= swep then
        return
    end

    local runtime = swep and swep.FTRuntime
    local context = frame.FTUIContext

    if context and FTBase.Runtime.UI and FTBase.Runtime.UI.Context
        and FTBase.Runtime.UI.Context.Sync then
        FTBase.Runtime.UI.Context.Sync(context)
    end

    local inspectProvider = frame.FTInspectProvider
        or (runtime and providerForDomain(runtime, "inspect"))
    local attachmentProvider = frame.FTAttachmentProvider
        or (runtime and FTBase.Runtime.Customization.GetProvider(runtime, "attachments"))
    local handled = false

    if inspectProvider and inspectProvider.Refresh then
        handled = inspectProvider:Refresh(context or swep, frame) or handled
    end

    if attachmentProvider and attachmentProvider ~= inspectProvider
        and attachmentProvider.Refresh then
        handled = attachmentProvider:Refresh(context or swep, frame) or handled
    end

    -- Default providers are declarative renderers. Re-mount their owned tree
    -- after an authoritative attachment update so labels/options use the
    -- effective IR, while custom providers may update in place by returning
    -- true from Refresh.
    if not handled and context then
        if not mountProviderUI(frame, context) then
            frame:Close()
        end
    end
end

local function activeWeapon()
    local player = LocalPlayer and LocalPlayer()

    if not player or not player.GetActiveWeapon then
        return nil
    end

    return player:GetActiveWeapon()
end

function Inspect.ToggleActiveWeapon()
    local swep = activeWeapon()

    if validWeapon(swep) then
        return Inspect.ToggleFromInput(swep)
    end

    return false
end

if CLIENT and concommand then
    concommand.Add("ft_customize", function()
        Inspect.ToggleActiveWeapon()
    end)

    concommand.Add("ft_customice", function()
        Inspect.ToggleActiveWeapon()
    end)
end

if CLIENT and hook then
    hook.Add("PlayerBindPress", "FTBaseInspectContextMenu", function(player, bind, pressed)
        if not string.find(bind or "", "+menu_context", 1, true) then
            return
        end

        if not player or not player.GetActiveWeapon then
            return
        end

        local swep = player:GetActiveWeapon()

        if not validWeapon(swep) then
            return
        end

        if not pressed then
            swep.FTRuntime.inspectContextDown = false
            return
        end

        if swep.FTRuntime.inspectContextDown then
            return true
        end

        swep.FTRuntime.inspectContextDown = true
        Inspect.ToggleFromInput(swep)
        return true
    end)
end

FTBase.Runtime.Inspect = Inspect
