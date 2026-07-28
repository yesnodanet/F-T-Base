FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Inspect = FTBase.Module.Define("Inspect", {
    Active = nil,
    InputDebounce = 0.2
})

local Path = FTBase.Util.Path

local function currentTime()
    return CurTime and CurTime() or os.clock()
end

local function nonEmpty(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if type(value) == "string" and string.find(value, "%S") then
            return value
        end
    end

    return ""
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

local function resolveFont(font, fallback)
    if FTBase.Runtime.Visuals and FTBase.Runtime.Visuals.ResolveFont then
        return FTBase.Runtime.Visuals.ResolveFont(font, fallback)
    end

    return font or fallback or "DermaDefault"
end

local function providerColor(provider, key, fallback)
    local value = provider and provider[key] or fallback or {225, 230, 236, 255}

    if Color then
        return Color(value[1] or 225, value[2] or 230, value[3] or 236, value[4] or 255)
    end

    return value
end

local function styleButton(button, provider, frame)
    if not button then
        return
    end

    local accent = providerColor(provider, "accent")
    local muted = providerColor(provider, "muted", {20, 26, 32, 225})
    local font = resolveFont(provider and provider.font, "DermaDefaultBold")

    if button.SetFont then
        button:SetFont(font)
    end

    if button.SetTextColor then
        button:SetTextColor(accent)
    end

    button.Paint = function(panel, width, height)
        if not draw or not draw.RoundedBox then
            return
        end

        local enabled = not panel.IsEnabled or panel:IsEnabled()
        local hovered = panel.IsHovered and panel:IsHovered()
        local background = enabled and (hovered and accent or muted) or Color(35, 35, 35, 180)
        local foreground = enabled and (hovered and Color(10, 10, 10, 235) or accent) or Color(130, 130, 130, 200)

        draw.RoundedBox(0, 0, 0, width, height, background)

        if panel.SetTextColor then
            panel:SetTextColor(foreground)
        end
    end

    button.FTProvider = provider
    button.FTInspectFrame = frame
end

local function stylePanel(panel, provider)
    if not panel then
        return
    end

    local muted = providerColor(provider, "muted", {20, 26, 32, 225})

    panel.Paint = function(_, width, height)
        if draw and draw.RoundedBox then
            draw.RoundedBox(0, 0, 0, width, height, muted)
        end
    end
end

local function notifyProvidersClosed(frame)
    if not frame or frame.FTProvidersClosed then
        return
    end

    frame.FTProvidersClosed = true
    local swep = frame.FTWeapon
    local runtime = swep and swep.FTRuntime
    local inspectProvider = runtime and providerForDomain(runtime, "inspect")
    local attachmentProvider = runtime and FTBase.Runtime.Customization.GetProvider(runtime, "attachments")

    if inspectProvider and inspectProvider.Close then
        inspectProvider:Close(swep, frame)
    end

    if attachmentProvider and attachmentProvider ~= inspectProvider and attachmentProvider.Close then
        attachmentProvider:Close(swep, frame)
    end

    if runtime then
        runtime.customizationOpen = false
    end

    if runtime and FTBase.Runtime.Animation then
        FTBase.Runtime.Animation.Play(swep, runtime, "idle")
    end
end

local function formatStat(label, value)
    return label .. ": " .. tostring(FTBase.Util.Math.Round(value or 0, 3))
end

local function createLabel(parent, text, font, textColor)
    local label = parent:Add("DLabel")
    label:SetText(text)
    label:SetFont(resolveFont(font, "DermaDefault"))
    label:SetTextColor(textColor or Color(225, 230, 236))
    label:Dock(TOP)
    label:DockMargin(12, 6, 12, 0)
    label:SizeToContentsY()
    return label
end

local function buildDetail(frame, slot)
    local detail = frame.FTDetail
    detail:Clear()

    local runtime = frame.FTWeapon.FTRuntime
    local provider = frame.FTProvider
    local inspectStyle = frame.FTInspectProvider or {}
    local preview = inspectStyle.preview or {}
    local shell = inspectStyle.shell or {}
    local accentValue = shell.accent or inspectStyle.accent
    local accent = accentValue and Color(
        accentValue[1],
        accentValue[2],
        accentValue[3],
        accentValue[4] or 255
    ) or Color(225, 230, 236)
    local inspectData = FTBase.Runtime.Customization.GetInspectData(runtime, slot.id)
    local ir = inspectData.ir or FTBase.Runtime.Customization.GetEffectiveIR(runtime)
    local installed = runtime.attachments.installed[slot.id]
    local definition = installed and runtime.ir.attachments.definitions[installed]

    if inspectStyle.showPreview ~= false then
        local model = detail:Add("DModelPanel")
        model:Dock(TOP)
        model:SetTall(preview.height or 220)
        model:SetModel(ir.rendering.viewModel or "models/weapons/c_pistol.mdl")
        model:SetFOV(preview.fov or 45)

        local camera = preview.camera or {45, 45, 32}
        local lookAt = preview.lookAt or {0, 0, 0}

        model:SetCamPos(Vector(camera[1] or 45, camera[2] or 45, camera[3] or 32))
        model:SetLookAt(Vector(lookAt[1] or 0, lookAt[2] or 0, lookAt[3] or 0))
    end

    createLabel(detail, provider:GetSlotLabel(slot), inspectStyle.font or "DermaLarge", accent)
    createLabel(detail, definition and ("Installed: " .. provider:GetInstalledLabel(definition, installed)) or provider:GetInstalledLabel(nil), inspectStyle.font or "DermaDefaultBold", accent)

    if provider.id == "mixed" then
        createLabel(detail, "Source: " .. tostring(ir.ui.customization.source or "mixed"))
    end

    local clear = detail:Add("DButton")
    clear:Dock(TOP)
    clear:DockMargin(12, 10, 12, 0)
    clear:SetTall(28)
    clear:SetText(provider.id == "mw" and "Remove from gunsmith" or "Remove attachment")
    clear:SetEnabled(installed ~= nil)
    styleButton(clear, provider, frame)
    clear.DoClick = function()
        local request = provider.BuildAttachmentRequest
            and provider:BuildAttachmentRequest(slot.id, "")
            or provider:BuildRequest(slot.id, "")
        FTBase.Runtime.Networking.RequestAttachment(frame.FTWeapon, request.slotId, request.attachmentId)
    end

    for _, option in ipairs(provider:GetOptions(runtime, slot.id)) do
        local button = detail:Add("DButton")
        button:Dock(TOP)
        button:DockMargin(12, 6, 12, 0)
        button:SetTall(32)
        button:SetText(provider:GetOptionLabel(option))
        button:SetTooltip(provider:GetOptionDescription(option))
        styleButton(button, provider, frame)
        button.DoClick = function()
            local request = provider.BuildAttachmentRequest
                and provider:BuildAttachmentRequest(slot.id, option.id)
                or provider:BuildRequest(slot.id, option.id)
            FTBase.Runtime.Networking.RequestAttachment(frame.FTWeapon, request.slotId, request.attachmentId)
        end
    end

    if inspectStyle.showStats ~= false then
        createLabel(detail, "Weapon statistics", inspectStyle.font or "DermaLarge", accent)

        local stats = inspectData.stats or inspectStyle.stats

        if type(stats) ~= "table" or #stats == 0 then
            stats = {
                {label = "Damage", path = "damage.base"},
                {label = "RPM", path = "fire.rpm"},
                {label = "Hip spread", path = "spread.hip"},
                {label = "ADS spread", path = "spread.ads"}
            }
        end

        for _, stat in ipairs(stats) do
            local statPath = type(stat) == "table" and stat.path
            local statLabel = type(stat) == "table" and stat.label

            if type(statPath) == "string" and statPath ~= "" then
                local value = Path.Get(ir, statPath)

                if value ~= nil then
                    createLabel(detail, formatStat(nonEmpty(statLabel, statPath), value))
                end
            end
        end
    end

    if provider.id == "mw" then
        createLabel(detail, "Gunsmith preview uses the selected attachment modifier before installation.", inspectStyle.font or "DermaDefaultBold")
    end
end

local function buildSlots(frame)
    local list = frame.FTSlots
    list:Clear()

    local runtime = frame.FTWeapon.FTRuntime
    local provider = frame.FTProvider

    for _, slot in ipairs(provider:GetSlots(runtime)) do
        local installed = runtime.attachments.installed[slot.id]
        local definition = installed and runtime.ir.attachments.definitions[installed]
        local button = list:Add("DButton")
        button:Dock(TOP)
        button:DockMargin(8, 6, 8, 0)
        button:SetTall(42)
        button:SetText(provider:GetSlotLabel(slot) .. "\n" .. provider:GetInstalledLabel(definition, installed))
        button.FTSlotId = slot.id
        styleButton(button, provider, frame)
        button.DoClick = function()
            frame.FTSelectedSlot = slot.id
            buildDetail(frame, slot)
        end
    end
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
    local provider = FTBase.Runtime.Customization.GetProvider(runtime)
    local inspectProvider = providerForDomain(runtime, "inspect")

    if providerId and provider.id ~= providerId then
        provider = FTBase.Runtime.Customization.GetProvider({
            ir = {
                ui = {
                    visual = {
                        providers = {
                            attachments = providerId
                        }
                    }
                }
            }
        })
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

    local frame = vgui.Create("DFrame")
    local shell = inspectProvider.shell or {}
    local frameConfig = shell.frame or inspectProvider.frame or {width = 920, height = 600}
    frame:SetSize(frameConfig.width or 920, frameConfig.height or 600)
    frame:Center()
    local title = nonEmpty(shell.title, inspectProvider.title, "F&T Customization") .. " - "
        .. nonEmpty(ir.meta.printName, nonEmpty(swep.PrintName, "Weapon"))
    frame:SetTitle(title)

    if frame.lblTitle then
        frame.lblTitle:SetFont(resolveFont(nonEmpty(shell.titleFont, inspectProvider.font), "DermaDefaultBold"))

        if shell.accent and Color then
            frame.lblTitle:SetTextColor(Color(
                shell.accent[1],
                shell.accent[2],
                shell.accent[3],
                shell.accent[4] or 255
            ))
        end
    end

    if shell.background and draw and draw.RoundedBox and Color then
        local background = Color(
            shell.background[1],
            shell.background[2],
            shell.background[3],
            shell.background[4] or 255
        )

        frame.Paint = function(panel, width, height)
            draw.RoundedBox(0, 0, 0, width, height, background)
        end
    end
    frame:MakePopup()
    frame.FTWeapon = swep
    frame.FTProvider = provider
    frame.FTInspectProvider = inspectProvider
    frame.FTAttachmentProviderId = provider and provider.id or "ft"
    frame.FTInspectProviderId = inspectProvider and inspectProvider.id or "ft"
    frame.OnClose = function()
        notifyProvidersClosed(frame)

        if Inspect.Active == frame then
            Inspect.Active = nil
        end
    end

    local slots = vgui.Create("DScrollPanel", frame)
    slots:Dock(LEFT)
    slots:SetWide(inspectProvider.sidebarWidth or 270)
    frame.FTSlots = slots
    stylePanel(slots, inspectProvider)

    local detail = vgui.Create("DScrollPanel", frame)
    detail:Dock(FILL)
    frame.FTDetail = detail
    stylePanel(detail, inspectProvider)

    Inspect.Active = frame
    if inspectProvider.Open then
        inspectProvider:Open(swep, frame)
    end
    if provider ~= inspectProvider and provider.Open then
        provider:Open(swep, frame)
    end
    buildSlots(frame)

    local firstSlot = provider:GetSlots(runtime)[1]

    if firstSlot then
        frame.FTSelectedSlot = firstSlot.id
        buildDetail(frame, firstSlot)
    else
        createLabel(detail, "This weapon has no attachment slots.", "DermaLarge")
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
    local provider = providerForDomain(runtime, "inspect")
    if provider and provider.HandleInput and provider:HandleInput(swep, runtime) then
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
    local provider = runtime and providerForDomain(runtime, "inspect")
    if provider and provider.Refresh then
        provider:Refresh(swep, frame)
    end

    buildSlots(frame)

    local slot = FTBase.Runtime.Attachments.GetSlot(swep.FTRuntime, frame.FTSelectedSlot)

    if slot then
        buildDetail(frame, slot)
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
