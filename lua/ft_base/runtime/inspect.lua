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
    local value

    if provider and key ~= nil then
        value = provider[key]
    end

    value = value or fallback or {225, 230, 236, 255}

    if Color then
        return Color(value.r or value[1] or 225, value.g or value[2] or 230,
            value.b or value[3] or 236, value.a or value[4] or 255)
    end

    return value
end

local function providerShell(provider)
    return provider and provider.shell or {}
end

local InspectMaterials = {}

local function loadMaterial(path)
    if not CLIENT or not path or tostring(path) == "" or not Material then
        return nil
    end

    if InspectMaterials[path] then
        return InspectMaterials[path]
    end

    local ok, value = pcall(Material, path, "mips smooth")

    if ok then
        InspectMaterials[path] = value
        return value
    end

    return nil
end

local function paintMaterial(pathOrMaterial, x, y, width, height, tint)
    if not surface or not surface.SetMaterial or not surface.DrawTexturedRect then
        return false
    end

    local material = type(pathOrMaterial) == "string" and loadMaterial(pathOrMaterial) or pathOrMaterial

    if not material then
        return false
    end

    tint = tint or Color(255, 255, 255, 255)
    surface.SetDrawColor(tint.r or tint[1] or 255, tint.g or tint[2] or 255,
        tint.b or tint[3] or 255, tint.a or tint[4] or 255)
    surface.SetMaterial(material)
    surface.DrawTexturedRect(x, y, width, height)
    return true
end

local function styleButton(button, provider, frame, role)
    if not button then
        return
    end

    local shell = providerShell(provider)
    local accent = providerColor(provider, "accent")
    local muted = providerColor(provider, "muted", {20, 26, 32, 225})
    local buttonStyle = shell.button or {}
    local font = resolveFont(buttonStyle.font or provider and provider.font, "DermaDefaultBold")

    if button.SetFont then
        button:SetFont(font)
    end

    if button.SetTextColor then
        button:SetTextColor(accent)
    end

    button.Paint = function(panel, width, height)
        local enabled = not panel.IsEnabled or panel:IsEnabled()
        local hovered = panel.IsHovered and panel:IsHovered()
        local selected = panel.FTSlotId and frame and frame.FTSelectedSlot == panel.FTSlotId
        local backgroundValue = selected and (buttonStyle.selected or buttonStyle.hover)
            or (hovered and buttonStyle.hover or buttonStyle.background)
        local background = providerColor(provider, nil, backgroundValue or muted)
        local foreground

        if not enabled then
            foreground = Color(130, 130, 130, 200)
        elseif selected then
            foreground = providerColor(provider, nil, buttonStyle.selectedText
                or buttonStyle.hoverText or buttonStyle.text or accent)
        elseif hovered then
            foreground = providerColor(provider, nil, buttonStyle.hoverText or accent)
        else
            foreground = providerColor(provider, nil, buttonStyle.text or accent)
        end
        local corner = tonumber(buttonStyle.corner) or tonumber(shell.corner) or 0

        if draw and draw.RoundedBox then
            draw.RoundedBox(corner, 0, 0, width, height, background)
        elseif surface and surface.SetDrawColor and surface.DrawRect then
            surface.SetDrawColor(background.r, background.g, background.b, background.a)
            surface.DrawRect(0, 0, width, height)
        end

        local border = selected and buttonStyle.selectedBorder or buttonStyle.border

        if border and surface and surface.SetDrawColor and surface.DrawOutlinedRect then
            local borderColor = providerColor(provider, nil, border)
            surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
            surface.DrawOutlinedRect(0, 0, width, height, tonumber(buttonStyle.borderWidth) or 1)
        end

        if panel.SetTextColor then
            panel:SetTextColor(foreground)
        end

        if selected and buttonStyle.selectedMaterial then
            paintMaterial(buttonStyle.selectedMaterial, 0, 0, width, height,
                Color(255, 255, 255, buttonStyle.selectedMaterialAlpha or 80))
        end
    end

    button.FTProvider = provider
    button.FTInspectFrame = frame
    button.FTProviderRole = role or "button"
end

local function stylePanel(panel, provider, role)
    if not panel then
        return
    end

    role = role or "panel"
    local shell = providerShell(provider)
    local roleStyle = shell[role] or {}
    local muted = providerColor(provider, nil, roleStyle.background or shell.background
        or provider and provider.muted or {20, 26, 32, 225})
    local material = roleStyle.material or shell[role .. "Material"]
    local corner = tonumber(roleStyle.corner) or tonumber(shell.corner) or 0

    panel.Paint = function(_, width, height)
        if draw and draw.RoundedBox then
            draw.RoundedBox(corner, 0, 0, width, height, muted)
        end

        if material then
            paintMaterial(material, 0, 0, width, height,
                Color(255, 255, 255, roleStyle.materialAlpha or shell.materialAlpha or 255))
        end
    end

    if panel.GetVBar then
        local bar = panel:GetVBar()

        if bar then
            bar.Paint = function(_, width, height)
                if surface and surface.SetDrawColor and surface.DrawRect then
                    local track = providerColor(provider, nil, roleStyle.scrollTrack or {0, 0, 0, 90})
                    surface.SetDrawColor(track.r, track.g, track.b, track.a)
                    surface.DrawRect(0, 0, width, height)
                end
            end

            if bar.btnUp then
                bar.btnUp.Paint = function() end
            end

            if bar.btnDown then
                bar.btnDown.Paint = function() end
            end

            if bar.btnGrip then
                bar.btnGrip.Paint = function(_, width, height)
                    if surface and surface.SetDrawColor and surface.DrawRect then
                        local grip = providerColor(provider, nil, roleStyle.scrollGrip or provider and provider.accent)
                        surface.SetDrawColor(grip.r, grip.g, grip.b, grip.a)
                        surface.DrawRect(0, 0, width, height)
                    end
                end
            end
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

local function createLabel(parent, text, font, textColor, style)
    style = style or {}
    local label = parent:Add("DLabel")
    label:SetText(text)
    label:SetFont(resolveFont(font, "DermaDefault"))
    label:SetTextColor(textColor or Color(225, 230, 236))
    label:Dock(TOP)
    label:DockMargin(style.left or 12, style.top or 6, style.right or 12, style.bottom or 0)
    label:SizeToContentsY()
    return label
end

local function buildDetail(frame, slot)
    local detail = frame.FTDetail
    detail:Clear()

    local runtime = frame.FTWeapon.FTRuntime
    local provider = frame.FTProvider
    local inspectStyle = frame.FTInspectProvider or {}
    local shell = providerShell(inspectStyle)
    local detailStyle = shell.detail or {}
    local preview = inspectStyle.preview or {}
    local accentValue = shell.accent or inspectStyle.accent
    local accent = accentValue and Color(
        accentValue.r or accentValue[1],
        accentValue.g or accentValue[2],
        accentValue.b or accentValue[3],
        accentValue.a or accentValue[4] or 255
    ) or Color(225, 230, 236)
    local inspectData = FTBase.Runtime.Customization.GetInspectData(runtime, slot.id)
    local ir = inspectData.ir or FTBase.Runtime.Customization.GetEffectiveIR(runtime)
    local installed = runtime.attachments.installed[slot.id]
    local definition = installed and runtime.ir.attachments.definitions[installed]

    if inspectStyle.showPreview ~= false then
        local model = detail:Add("DModelPanel")
        model:Dock(TOP)
        model:DockMargin(detailStyle.previewMargin or 0, detailStyle.previewTop or 0,
            detailStyle.previewMargin or 0, detailStyle.previewBottom or 8)
        model:SetTall(preview.height or detailStyle.previewHeight or 220)
        model:SetModel(ir.rendering.viewModel or "models/weapons/c_pistol.mdl")
        model:SetFOV(preview.fov or 45)

        local camera = preview.camera or {45, 45, 32}
        local lookAt = preview.lookAt or {0, 0, 0}

        model:SetCamPos(Vector(camera[1] or 45, camera[2] or 45, camera[3] or 32))
        model:SetLookAt(Vector(lookAt[1] or 0, lookAt[2] or 0, lookAt[3] or 0))

        if detailStyle.previewPaint then
            model.Paint = detailStyle.previewPaint
        end
    end

    createLabel(detail, provider:GetSlotLabel(slot), detailStyle.titleFont or inspectStyle.font or "DermaLarge", accent, {
        left = detailStyle.padding or 12,
        right = detailStyle.padding or 12,
        top = detailStyle.titleTop or 6
    })
    createLabel(detail, definition and (shell.installedPrefix or "Installed: ") .. provider:GetInstalledLabel(definition, installed)
        or provider:GetInstalledLabel(nil), detailStyle.valueFont or inspectStyle.font or "DermaDefaultBold", accent, {
        left = detailStyle.padding or 12,
        right = detailStyle.padding or 12,
        top = detailStyle.valueTop or 4
    })

    if provider.id == "mixed" then
        createLabel(detail, "Source: " .. tostring(ir.ui.customization.source or "mixed"))
    end

    local clear = detail:Add("DButton")
    clear:Dock(TOP)
    clear:DockMargin(detailStyle.padding or 12, detailStyle.actionTop or 10, detailStyle.padding or 12, 0)
    clear:SetTall(detailStyle.actionHeight or 28)
    clear:SetText(shell.removeLabel or (provider.id == "mw" and "Remove from gunsmith" or "Remove attachment"))
    clear:SetEnabled(installed ~= nil)
    styleButton(clear, provider, frame, "remove")
    clear.DoClick = function()
        local request = provider.BuildAttachmentRequest
            and provider:BuildAttachmentRequest(slot.id, "")
            or provider:BuildRequest(slot.id, "")
        FTBase.Runtime.Networking.RequestAttachment(frame.FTWeapon, request.slotId, request.attachmentId)
    end

    for _, option in ipairs(provider:GetOptions(runtime, slot.id)) do
        local button = detail:Add("DButton")
        button:Dock(TOP)
        button:DockMargin(detailStyle.padding or 12, detailStyle.optionTop or 6, detailStyle.padding or 12, 0)
        button:SetTall(detailStyle.optionHeight or 32)
        button:SetText(provider:GetOptionLabel(option))
        button:SetTooltip(provider:GetOptionDescription(option))
        if option.icon and button.SetImage then
            button:SetImage(option.icon)
        end
        styleButton(button, provider, frame, "option")
        button.DoClick = function()
            local request = provider.BuildAttachmentRequest
                and provider:BuildAttachmentRequest(slot.id, option.id)
                or provider:BuildRequest(slot.id, option.id)
            FTBase.Runtime.Networking.RequestAttachment(frame.FTWeapon, request.slotId, request.attachmentId)
        end
    end

    if inspectStyle.showStats ~= false then
        createLabel(detail, shell.statsTitle or "Weapon statistics", detailStyle.statsTitleFont or inspectStyle.font or "DermaLarge", accent, {
            left = detailStyle.padding or 12,
            right = detailStyle.padding or 12,
            top = detailStyle.statsTop or 14
        })

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
                    createLabel(detail, formatStat(nonEmpty(statLabel, statPath), value),
                        detailStyle.statsFont or inspectStyle.hintFont or "DermaDefault", detailStyle.statsColor and providerColor(provider, nil, detailStyle.statsColor) or nil, {
                            left = detailStyle.padding or 12,
                            right = detailStyle.padding or 12,
                            top = detailStyle.statsRowTop or 3
                        })
                end
            end
        end
    end

    if provider.id == "mw" then
        createLabel(detail, shell.previewHint or "Gunsmith preview uses the selected attachment modifier before installation.", inspectStyle.hintFont or inspectStyle.font or "DermaDefaultBold", nil, {
            left = detailStyle.padding or 12,
            right = detailStyle.padding or 12,
            top = 10
        })
    end
end

local function buildSlots(frame)
    local list = frame.FTSlots
    list:Clear()

    local runtime = frame.FTWeapon.FTRuntime
    local provider = frame.FTProvider
    local inspectStyle = frame.FTInspectProvider or provider
    local shell = providerShell(provider)
    if not shell.layout then
        shell = providerShell(inspectStyle)
    end
    local slotStyle = shell.slot or {}
    local horizontal = shell.layout == "arc9" or shell.slotOrientation == "horizontal"
    local slotIcons = shell.slotIcons or {}

    for _, slot in ipairs(provider:GetSlots(runtime)) do
        local installed = runtime.attachments.installed[slot.id]
        local definition = installed and runtime.ir.attachments.definitions[installed]
        local button = list:Add("DButton")
        button:Dock(horizontal and LEFT or TOP)
        button:DockMargin(slotStyle.marginLeft or 8, slotStyle.marginTop or 6,
            slotStyle.marginRight or 8, slotStyle.marginBottom or 0)
        button:SetTall(slotStyle.height or (horizontal and 70 or 42))
        if horizontal then
            button:SetWide(slotStyle.width or 150)
        end
        button:SetText(provider:GetSlotLabel(slot) .. "\n" .. provider:GetInstalledLabel(definition, installed))
        button.FTSlotId = slot.id
        local icon = slotIcons[slot.type] or slotIcons[slot.id] or slotIcons.default
            or shell.iconMaterial or inspectStyle.iconMaterial or provider.iconMaterial

        if icon and button.SetImage then
            button:SetImage(icon)
        end

        styleButton(button, provider, frame, "slot")
        button.DoClick = function()
            frame.FTSelectedSlot = slot.id
            buildDetail(frame, slot)
        end
    end
end

local function createPopup(fullscreen)
    if not fullscreen then
        return vgui.Create("DFrame")
    end

    -- Vendor customization screens are borderless popups.  A DFrame keeps a
    -- native title bar even after SetTitle("") and therefore exposes the FT
    -- chrome above the provider layout.  DPanel gives us the same popup/input
    -- behavior without that implicit title-bar area.
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

    local shell = providerShell(inspectProvider)
    local frameConfig = shell.frame or inspectProvider.frame or {width = 920, height = 600}
    local fullscreen = shell.mode == "fullscreen" or shell.fullscreen == true
    local screenWidth = ScrW and ScrW() or frameConfig.width or 920
    local screenHeight = ScrH and ScrH() or frameConfig.height or 600
    local frame = createPopup(fullscreen)

    frame:SetSize(fullscreen and screenWidth or frameConfig.width or 920,
        fullscreen and screenHeight or frameConfig.height or 600)

    if fullscreen then
        frame:SetPos(0, 0)
    else
        frame:Center()
    end

    local title = nonEmpty(shell.title, inspectProvider.title, "F&T Customization") .. " - "
        .. nonEmpty(ir.meta.printName, nonEmpty(swep.PrintName, "Weapon"))
    if frame.SetTitle then
        frame:SetTitle(fullscreen and "" or title)
    end

    if fullscreen then
        if frame.ShowCloseButton then
            frame:ShowCloseButton(false)
        end

        if frame.SetDraggable then
            frame:SetDraggable(false)
        end
    end

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
            draw.RoundedBox(tonumber(shell.corner) or 0, 0, 0, width, height, background)

            if shell.backgroundMaterial then
                paintMaterial(shell.backgroundMaterial, 0, 0, width, height,
                    Color(255, 255, 255, shell.backgroundMaterialAlpha or 255))
            end

            if fullscreen and shell.overlay then
                local overlay = shell.overlay
                draw.RoundedBox(0, 0, 0, width, height,
                    Color(overlay[1] or 0, overlay[2] or 0, overlay[3] or 0, overlay[4] or 0))
            end
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

    if fullscreen then
        local header = vgui.Create("DPanel", frame)
        header:Dock(TOP)
        header:SetTall(shell.headerHeight or 52)
        header.FTProvider = inspectProvider
        header.Paint = function(panel, width, height)
            local headerColor = providerColor(inspectProvider, nil, shell.headerBackground or shell.background)
            local accent = providerColor(inspectProvider, "accent")

            if draw and draw.RoundedBox then
                draw.RoundedBox(tonumber(shell.headerCorner) or 0, 0, 0, width, height, headerColor)
            end

            if shell.headerMaterial then
                paintMaterial(shell.headerMaterial, 0, 0, width, height,
                    Color(255, 255, 255, shell.headerMaterialAlpha or 255))
            end

            if draw and draw.SimpleText then
                local titleAlign = shell.titleAlign or "left"
                local titleX = shell.titleX

                if not titleX then
                    titleX = titleAlign == "center" and width * 0.5
                        or titleAlign == "right" and width - (shell.titleRight or 16) or 16
                end

                draw.SimpleText(title, resolveFont(shell.titleFont or inspectProvider.font, "DermaDefaultBold"),
                    titleX,
                    shell.titleY or height * 0.5, accent,
                    titleAlign == "center" and TEXT_ALIGN_CENTER or titleAlign == "right" and TEXT_ALIGN_RIGHT or TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER)
            end
        end
        frame.FTHeader = header

        local close = vgui.Create("DButton", header)
        close:Dock(RIGHT)
        close:SetWide(shell.closeWidth or 44)
        close:SetText(shell.closeLabel or "X")
        close:SetTooltip(shell.closeTooltip or "Close")
        styleButton(close, inspectProvider, frame, "close")
        close.DoClick = function()
            frame:Close()
        end
        frame.FTCloseButton = close
    end

    local slots = vgui.Create("DScrollPanel", frame)
    local attachmentShell = providerShell(provider)
    -- The inspect domain owns the outer composition.  A mixed weapon may use
    -- another dialect for attachment data/buttons, but must retain the
    -- explicitly selected inspect layout (for example TFA shell + MW slots).
    local layout = shell.layout or attachmentShell.layout or "sidebar"

    if layout == "arc9" then
        slots:Dock(BOTTOM)
        slots:SetTall(shell.slotBarHeight or 120)
    elseif layout == "tfa" then
        -- TFA's inspection screen keeps weapon information on the left and
        -- attachment categories in a full-height panel on the right.
        slots:Dock(RIGHT)
        slots:SetWide(math.max(300, math.floor(screenWidth * 0.48)))
    elseif layout == "mw" then
        -- MW's gunsmith starts with the category rail on the left and leaves
        -- the large center/right area for the weapon and stat cards.
        slots:Dock(LEFT)
        slots:SetWide(math.max(300, math.floor(screenWidth * 0.30)))
    elseif layout == "arccw" then
        slots:Dock(LEFT)
        slots:SetWide(math.max(240, math.floor(screenWidth * 0.25)))
    elseif layout == "tacrp" then
        slots:Dock(LEFT)
        slots:SetWide(math.max(220, math.floor(screenWidth * 0.20)))
    else
        slots:Dock(LEFT)
        slots:SetWide(inspectProvider.sidebarWidth or 270)
    end

    slots:DockMargin(shell.contentMargin or 0, shell.contentTop or 0,
        shell.contentMargin or 0, shell.contentBottom or 0)
    frame.FTSlots = slots
    stylePanel(slots, provider, "sidebar")

    local detail = vgui.Create("DScrollPanel", frame)
    detail:Dock(FILL)
    detail:DockMargin(shell.detailMargin or 0, shell.contentTop or 0,
        shell.contentMargin or 0, shell.contentBottom or 0)
    frame.FTDetail = detail
    stylePanel(detail, inspectProvider, "detail")

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
