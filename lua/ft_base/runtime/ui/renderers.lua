FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}
FTBase.Runtime.UI = FTBase.Runtime.UI or {}

local Renderers = FTBase.Module.Define("RuntimeUIRenderers", {})
local Toolkit = FTBase.Runtime.UI.Toolkit
local RendererMap = {}
local AttachmentRendererMap = {}

local function screenWidth()
    return ScrW and ScrW() or 1280
end

local function screenHeight()
    return ScrH and ScrH() or 720
end

local function effectiveIR(context)
    return context and context.GetEffectiveIR and context:GetEffectiveIR() or {}
end

local function displayName(context)
    local ir = effectiveIR(context)
    local meta = ir.meta or {}

    if meta.printName and tostring(meta.printName) ~= "" then
        return tostring(meta.printName)
    end

    if context and context.swep and context.swep.PrintName then
        return tostring(context.swep.PrintName)
    end

    return tostring(meta.category or "Weapon")
end

local function providerFor(context, domain)
    if not context then
        return nil
    end

    return context[domain .. "Provider"] or context.inspectProvider
end

local function shellFor(provider)
    return provider and provider.shell or {}
end

local function styleFor(provider, role)
    local shell = shellFor(provider)
    return shell[role or "panel"] or {}
end

local function slotsFor(provider, context)
    if provider and provider.GetSlots then
        return provider:GetSlots(context.runtime) or {}
    end

    local state = context and context.runtime and context.runtime.attachments
    return state and state.slots or {}
end

local function installed(context, slot)
    local state = context and context.runtime and context.runtime.attachments
    local values = state and state.installed or {}
    local id = values[slot and slot.id]
    local ir = effectiveIR(context)
    local definitions = ir.attachments and ir.attachments.definitions or {}
    return id, id and definitions[id] or nil
end

local function optionsFor(provider, context, slot)
    if provider and provider.GetOptions then
        return provider:GetOptions(context.runtime, slot and slot.id) or {}
    end

    return {}
end

local function getPath(value, path)
    if type(value) ~= "table" or type(path) ~= "string" then
        return nil
    end

    local current = value

    for part in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then
            return nil
        end

        current = current[part]
    end

    return current
end

local function finiteNumber(value, fallback)
    value = tonumber(value)

    if not value or value ~= value or value == math.huge or value == -math.huge then
        return fallback or 0
    end

    return value
end

local function slotLabel(provider, slot)
    if provider and provider.GetSlotLabel then
        return tostring(provider:GetSlotLabel(slot))
    end

    return tostring(slot and (slot.name or slot.id) or "Slot")
end

local function installedLabel(provider, definition, id)
    if provider and provider.GetInstalledLabel then
        return tostring(provider:GetInstalledLabel(definition, id))
    end

    return tostring(definition and definition.name or id or "EMPTY")
end

local function selectSlot(context, slotId)
    if not context or not context.state then
        return
    end

    context.state.selectedSlot = slotId
    context.state.selectedOption = nil
end

local function selectedSlot(provider, context)
    local slots = slotsFor(provider, context)
    local selected = context and context.state and context.state.selectedSlot

    for _, slot in ipairs(slots) do
        if slot.id == selected then
            return slot
        end
    end

    if slots[1] then
        selected = slots[1].id

        if context and context.state then
            context.state.selectedSlot = selected
        end

        return slots[1]
    end

    return nil
end

local function safeRefresh(context, reason)
    if context and context.Refresh then
        context:Refresh(reason)
    end
end

local function safeRequest(context, provider, slotId, attachmentId)
    if not context then
        return false
    end

    if provider and provider.BuildAttachmentRequest and context.swep
        and FTBase.Runtime.Networking then
        local request = provider:BuildAttachmentRequest(slotId, attachmentId)
        return FTBase.Runtime.Networking.RequestAttachment(context.swep,
            request.slotId, request.attachmentId)
    end

    if context.RequestAttachment then
        return context:RequestAttachment(slotId, attachmentId)
    end

    return false
end

local function makePanel(parent, provider, role)
    local panel = vgui.Create("DPanel", parent)
    Toolkit.StylePanel(panel, provider, role or "detail")
    return panel
end

local function makeLabel(parent, provider, text, font, color, margin)
    return Toolkit.Label(parent, text, font or provider and provider.font,
        color or provider and provider.accent, margin)
end

local function makeClose(parent, context, provider, label, width)
    local button = parent:Add("DButton")
    button:Dock(RIGHT)
    button:SetWide(width or 44)
    button:SetText(tostring(label or "X"))
    Toolkit.StyleButton(button, provider, false)
    button.DoClick = function()
        if context and context.Close then
            context:Close()
        end
    end
    return button
end

local function makeHeader(root, context, provider, options)
    options = options or {}
    local shell = shellFor(provider)
    local header = vgui.Create("DPanel", root)
    header:Dock(TOP)
    header:SetTall(options.height or shell.headerHeight or 44)

    local headerStyle = styleFor(provider, "header")
    header.Paint = function(_, width, height)
        Toolkit.Box(0, 0, width, height,
            options.background or headerStyle.background or shell.headerBackground or shell.background,
            headerStyle.corner or shell.corner)

        local material = options.material or headerStyle.material or shell.headerMaterial

        if material then
            Toolkit.PaintMaterial(material, 0, 0, width, height,
                {255, 255, 255, options.materialAlpha or headerStyle.materialAlpha or shell.headerMaterialAlpha or 255})
        end

        Toolkit.Text(displayName(context), options.titleFont or options.font or shell.titleFont or provider and provider.font,
            options.align == "right" and width - (options.closeWidth or 52)
                or options.align == "center" and width * 0.5 or 16,
            height * 0.5, options.color or shell.accent or provider and provider.accent,
            options.align == "right" and TEXT_ALIGN_RIGHT
                or options.align == "center" and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER)
    end

    makeClose(header, context, provider, options.closeLabel or shell.closeLabel or "X",
        options.closeWidth or shell.closeWidth or 44)
    return header
end

local function makeTabs(parent, context, provider, tabs)
    local shell = shellFor(provider)
    if context and context.state and not context.state.activeTab and tabs and tabs[1] then
        context.state.activeTab = tabs[1].id
    end
    local tabbar = vgui.Create("DPanel", parent)
    tabbar:Dock(TOP)
    tabbar:SetTall(34)
    Toolkit.StylePanel(tabbar, provider, "sidebar")

    for _, tab in ipairs(tabs or {}) do
        local button = tabbar:Add("DButton")
        button:Dock(LEFT)
        button:SetWide(tab.width or 130)
        button:SetText(tostring(tab.label or tab.id or "TAB"))
        button.FTTabId = tab.id
        Toolkit.StyleButton(button, provider, context.state.activeTab == tab.id)
        button.Paint = function(panel, width, height)
            local active = context.state.activeTab == tab.id
            panel.FTSelected = active
            local style = shell.button or {}
            local fill = active and (style.selected or provider.accent)
                or panel:IsHovered() and (style.hover or style.background)
                or style.background or provider.muted
            local textColor = active and (style.selectedText or style.hoverText or provider.accent)
                or style.text or {190, 196, 202, 255}
            Toolkit.Box(0, 0, width, height, fill, style.corner or 0)
            Toolkit.Text(tab.label or tab.id, style.font or provider.font,
                width * 0.5, height * 0.5, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        button.DoClick = function()
            context.state.activeTab = tab.id

            if tab.callback then
                tab.callback()
            else
                safeRefresh(context, "tab")
            end
        end
    end

    return tabbar
end

local function chooseSlot(context, provider, slot, parent, options)
    options = options or {}
    local button = parent:Add("DButton")
    button:SetText("")
    Toolkit.SafeSize(button, options.width or math.max(1, parent:GetWide() - 8), options.height or 42)
    button:Dock(options.dock or TOP)
    button:DockMargin(options.marginLeft or 4, options.marginTop or 4,
        options.marginRight or 4, options.marginBottom or 0)
    button.FTSlotId = slot.id
    button.Paint = function(panel, width, height)
        local active = context.state.selectedSlot == slot.id
        local shell = shellFor(provider)
        local style = shell.button or {}
        local fill = active and (options.selected or style.selected or provider.accent)
            or panel:IsHovered() and (options.hover or style.hover or options.background)
            or options.background or style.background or provider.muted
        Toolkit.Box(0, 0, width, height, fill, options.corner or style.corner or 0)

        local icon = slot.icon or options.icon or shell.slotIcons and (shell.slotIcons[slot.type] or shell.slotIcons.default)

        if icon then
            Toolkit.PaintMaterial(icon, 6, 6, height - 12, height - 12,
                {255, 255, 255, active and 255 or 180})
        end

        local x = icon and height or 8
        Toolkit.Text(slotLabel(provider, slot), options.font or style.font or provider.font,
            x, height * 0.35, active and (options.selectedText or style.hoverText or provider.accent)
                or options.text or style.text or provider.accent,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local id, definition = installed(context, slot)
        Toolkit.Text(installedLabel(provider, definition, id), options.smallFont or provider.hintFont,
            x, height * 0.72, options.subtext or {190, 196, 202, 255}, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    button.DoClick = function()
        selectSlot(context, slot.id)
        safeRefresh(context, "slot")
    end
    return button
end

local function optionButton(context, provider, slot, option, parent, options)
    options = options or {}
    local button = parent:Add("DButton")
    button:SetText("")
    Toolkit.SafeSize(button, options.width or math.max(1, parent:GetWide() - 8), options.height or 36)
    button:Dock(options.dock or TOP)
    button:DockMargin(options.marginLeft or 4, options.marginTop or 4,
        options.marginRight or 4, options.marginBottom or 0)
    button.FTOptionId = option.id
    button:SetTooltip(tostring(option.description or ""))
    button.Paint = function(panel, width, height)
        local selected = context.state.selectedOption == option.id
        local id = context.runtime and context.runtime.attachments
            and context.runtime.attachments.installed[slot.id]
        local active = id == option.id
        local shell = shellFor(provider)
        local style = shell.button or {}
        local fill = active and (options.active or style.selected or provider.accent)
            or selected and (options.selected or style.hover or provider.accent)
            or panel:IsHovered() and (options.hover or style.hover)
            or options.background or style.background or {20, 26, 32, 225}
        Toolkit.Box(0, 0, width, height, fill, options.corner or style.corner or 0)

        if option.icon then
            Toolkit.PaintMaterial(option.icon, 4, 4, height - 8, height - 8,
                {255, 255, 255, active and 255 or 190})
        end

        Toolkit.Text(tostring(option.name or option.id or "Attachment"), options.font or style.font or provider.font,
            height + 4, height * 0.5, active and (options.activeText or style.hoverText or provider.accent)
                or options.text or style.text or {220, 225, 230, 255},
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    button.DoClick = function()
        context.state.selectedOption = option.id
        safeRequest(context, provider, slot.id, option.id)
    end
    button.DoRightClick = function()
        safeRequest(context, provider, slot.id, "")
    end
    return button
end

local function renderOptions(context, provider, parent, slot, options)
    options = options or {}

    if not slot then
        makeLabel(parent, provider, options.emptyLabel or "No attachment slot selected",
            provider and provider.hintFont, {190, 196, 202, 255}, {left = 10, top = 12})
        return
    end

    makeLabel(parent, provider, slotLabel(provider, slot), options.titleFont or provider.font,
        options.titleColor or provider.accent, {left = 10, top = 8})

    local id, definition = installed(context, slot)
    makeLabel(parent, provider, installedLabel(provider, definition, id), options.valueFont or provider.hintFont,
        options.valueColor or {190, 196, 202, 255}, {left = 10, top = 2})

    local remove = parent:Add("DButton")
    remove:SetText(options.removeLabel or shellFor(provider).removeLabel or "REMOVE")
    remove:Dock(TOP)
    remove:DockMargin(8, 8, 8, 0)
    remove:SetTall(options.removeHeight or 30)
    remove:SetEnabled(id ~= nil)
    Toolkit.StyleButton(remove, provider, false)
    remove.DoClick = function()
        safeRequest(context, provider, slot.id, "")
    end

    local lastGroup
    for _, option in ipairs(optionsFor(provider, context, slot)) do
        if options.groupFolders then
            local group = option.folder or option.category

            if group and group ~= lastGroup then
                makeLabel(parent, provider, string.upper(tostring(group)), provider.hintFont,
                    {150, 203, 216, 255}, {left = 10, top = 10})
                lastGroup = group
            end
        end

        optionButton(context, provider, slot, option, parent, options.option or options)
    end
end

local function renderStats(context, provider, parent, options)
    options = options or {}
    local style = styleFor(provider, "detail")
    local stats = options.stats or provider and provider.stats or {}
    local ir = effectiveIR(context)
    local content = vgui.Create("DScrollPanel", parent)
    content:Dock(FILL)
    Toolkit.StylePanel(content, provider, "detail")

    makeLabel(content, provider, options.title or shellFor(provider).statsTitle or "PERFORMANCE",
        options.titleFont or style.statsTitleFont or provider.font, provider.accent,
        {left = style.padding or 14, top = 12})

    if type(stats) ~= "table" or #stats == 0 then
        stats = {
            {label = "Damage", path = "damage.base"},
            {label = "RPM", path = "fire.rpm"},
            {label = "Hip spread", path = "spread.hip"},
            {label = "ADS spread", path = "spread.ads"}
        }
    end

    local rows = {}

    for _, stat in ipairs(stats) do
        local label = type(stat) == "table" and (stat.label or stat.name or stat.path)
        local value = type(stat) == "table" and getPath(ir, stat.path or "") or stat

        if label then
            rows[#rows + 1] = {label = tostring(label), value = value, stat = stat}
        end
    end

    for _, row in ipairs(rows) do
        local panel = content:Add("DPanel")
        panel:Dock(TOP)
        panel:DockMargin(style.padding or 14, 6, style.padding or 14, 0)
        panel:SetTall(options.rowHeight or 30)
        panel.Paint = function(_, width, height)
            local value = finiteNumber(row.value, 0)
            local maximum = finiteNumber(type(row.stat) == "table"
                and (row.stat.max or row.stat.maximum) or 100, 100)
            if maximum <= 0 then maximum = 100 end
            local fraction = math.max(0, math.min(1, math.abs(value) / maximum))
            Toolkit.Text(row.label, options.rowFont or style.statsFont or provider.font,
                0, height * 0.25, {205, 211, 216, 255}, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            Toolkit.Text(tostring(row.value == nil and "-" or row.value), options.valueFont or provider.hintFont,
                width, height * 0.25, provider.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            Toolkit.Box(0, height - 8, width, 5, {0, 0, 0, 120}, 0)
            Toolkit.Box(0, height - 8, width * fraction, 5, provider.accent, 0)
        end
    end

    return content
end

local function renderTrivia(context, provider, parent)
    local style = styleFor(provider, "detail")
    local panel = vgui.Create("DScrollPanel", parent)
    panel:Dock(FILL)
    Toolkit.StylePanel(panel, provider, "detail")

    local ir = effectiveIR(context)
    local inspect = ir.ui and ir.ui.inspect or {}
    makeLabel(panel, provider, shellFor(provider).triviaTitle or "DETAILS",
        style.statsTitleFont or provider.font, provider.accent,
        {left = style.padding or 14, top = 12})
    makeLabel(panel, provider, tostring(inspect.description or ir.meta and ir.meta.description or ""),
        provider.hintFont, {205, 211, 216, 255}, {left = style.padding or 14, top = 8, right = style.padding or 14})
    makeLabel(panel, provider, tostring(inspect.credits or ir.meta and ir.meta.author or ""),
        provider.hintFont, {190, 196, 202, 255}, {left = style.padding or 14, top = 10, right = style.padding or 14})
    return panel
end

local function renderTacRPCharts(context, provider, parent)
    local chart = makePanel(parent, provider, "detail")
    chart:Dock(TOP)
    chart:SetTall(118)
    local ir = effectiveIR(context)
    local curve = ir.ballistics and ir.ballistics.damageCurve or {}
    local maximum = finiteNumber(curve.maxRange, 1000)
    local minimum = finiteNumber(curve.minRange, 0)
    local damage = finiteNumber(ir.damage and ir.damage.base, 1)
    local minimumDamage = finiteNumber(ir.damage and ir.damage.minimum, damage * 0.5)
    chart.Paint = function(_, width, height)
        Toolkit.Box(0, 0, width, height, {0, 0, 0, 150}, 0)
        Toolkit.Text("DAMAGE / RANGE", provider.hintFont, 8, 8, provider.accent)
        local left = 8
        local top = 26
        local right = width - 8
        local bottom = height - 12
        Toolkit.Line(left, bottom, right, bottom, {190, 196, 202, 150})
        Toolkit.Line(left, top, left, bottom, {190, 196, 202, 150})
        local points = {
            {x = left, y = bottom - (damage / math.max(damage, 1)) * (bottom - top)},
            {x = left + (right - left) * 0.33, y = bottom - (damage / math.max(damage, 1)) * (bottom - top)},
            {x = left + (right - left) * 0.66, y = bottom - (minimumDamage / math.max(damage, 1)) * (bottom - top)},
            {x = right, y = bottom - (minimumDamage / math.max(damage, 1)) * (bottom - top)}
        }
        for index = 2, #points do
            Toolkit.Line(points[index - 1].x, points[index - 1].y,
                points[index].x, points[index].y, provider.accent)
        end
        Toolkit.Text(tostring(math.floor(minimum)) .. "m", provider.hintFont,
            left, bottom + 2, {190, 196, 202, 255}, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        Toolkit.Text(tostring(math.floor(maximum)) .. "m", provider.hintFont,
            right, bottom + 2, {190, 196, 202, 255}, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    local body = vgui.Create("DPanel", chart)
    body:Dock(RIGHT)
    body:SetWide(48)
    body.Paint = function(_, width, height)
        Toolkit.PaintMaterial("ft_base/providers/tacrp/hud/body.png", 0, 8, width, height - 16,
            {255, 255, 255, 200})
    end

    return chart
end

local function renderPreview(context, provider, parent, options)
    options = options or {}
    local style = styleFor(provider, "detail")
    local panel = makePanel(parent, provider, "detail")
    panel:Dock(TOP)
    panel:SetTall(options.height or style.previewHeight or provider and provider.preview and provider.preview.height or 220)

    local ir = effectiveIR(context)
    local modelPath = ir.rendering and ir.rendering.viewModel

    if modelPath and vgui.Create then
        local model = vgui.Create("DModelPanel", panel)
        model:Dock(FILL)
        model:SetModel(modelPath)
        model:SetFOV(options.fov or provider.preview and provider.preview.fov or 45)
        local camera = options.camera or provider.preview and provider.preview.camera or {45, 45, 32}
        local lookAt = options.lookAt or provider.preview and provider.preview.lookAt or {0, 0, 0}

        if Vector then
            model:SetCamPos(Vector(camera[1] or 45, camera[2] or 45, camera[3] or 32))
            model:SetLookAt(Vector(lookAt[1] or 0, lookAt[2] or 0, lookAt[3] or 0))
        end

        model:SetMouseInputEnabled(false)
        model:SetKeyboardInputEnabled(false)
    end

    panel.PaintOver = function(_, width, height)
        Toolkit.Text(displayName(context), provider and provider.font, 12, height - 14,
            provider and provider.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return panel
end

local function callAttachmentSurface(provider, context, parent)
    if provider and provider.CreateAttachmentSurface then
        local ok, result = pcall(provider.CreateAttachmentSurface, provider, context, parent)

        if ok then
            return result
        end
    end

    local renderer = AttachmentRendererMap[provider and string.lower(tostring(provider.id or "ft")) or "ft"]
    return renderer and renderer(context, parent) or false
end

local function renderTFAAttachmentSurface(context, parent)
    local provider = providerFor(context, "attachments") or providerFor(context, "inspect")
    local shell = shellFor(provider)
    local slots = vgui.Create("DScrollPanel", parent)
    slots:Dock(LEFT)
    slots:SetWide(math.max(220, math.floor(parent:GetWide() * 0.38)))
    Toolkit.StylePanel(slots, provider, "sidebar")

    for _, slot in ipairs(slotsFor(provider, context)) do
        chooseSlot(context, provider, slot, slots, {
            height = shell.slot and shell.slot.height or 62,
            selected = shell.button and shell.button.selected or provider.accent,
            background = shell.button and shell.button.background or provider.muted,
            corner = 0,
            icon = shell.slotIcons and (shell.slotIcons[slot.type] or shell.slotIcons.default)
        })
    end

    local detail = Toolkit.Scroll(parent, provider, "detail")
    detail:Dock(FILL)
    renderOptions(context, provider, detail, selectedSlot(provider, context), {
        removeLabel = shell.removeLabel or "REMOVE ATTACHMENT",
        option = {height = 58, active = shell.button and shell.button.selected or provider.accent,
            background = {31, 34, 38, 220}, corner = 0}
    })
    return slots
end

local function renderMWAttachmentSurface(context, parent)
    local provider = providerFor(context, "attachments") or providerFor(context, "inspect")
    local shell = shellFor(provider)
    local utility = vgui.Create("DPanel", parent)
    utility:Dock(BOTTOM)
    utility:SetTall(math.max(78, math.floor(parent:GetTall() * 0.2)))
    utility.Paint = function(_, width, height)
        Toolkit.Box(0, 0, width, height, shell.background or provider.muted, 0)
        Toolkit.Line(0, 0, width, 0, provider.accent)
    end

    local function utilityButton(label, x, callback)
        local button = utility:Add("DButton")
        button:SetText(tostring(label))
        button:SetSize(84, 58)
        button:SetPos(math.floor(parent:GetWide() * 0.5 + x - 42), 8)
        Toolkit.StyleButton(button, provider, false)
        button.DoClick = callback
        return button
    end

    utilityButton("PRESETS", -150, function()
        context.state.activeTab = "presets"
        safeRefresh(context, "presets")
    end)
    utilityButton("RESET", -50, function()
        for _, slot in ipairs(slotsFor(provider, context)) do
            safeRequest(context, provider, slot.id, "")
        end
    end)
    utilityButton("RANDOM", 50, function()
        for _, slot in ipairs(slotsFor(provider, context)) do
            local options = optionsFor(provider, context, slot)
            if #options > 0 then
                local choice = options[math.random(1, #options)]
                safeRequest(context, provider, slot.id, choice.id)
            end
        end
    end)
    utilityButton("FAVORITES", 150, function()
        context.state.favoritesOnly = not context.state.favoritesOnly
        safeRefresh(context, "favorites")
    end)

    local rail = vgui.Create("DScrollPanel", parent)
    rail:Dock(LEFT)
    rail:SetWide(math.max(300, math.floor(parent:GetWide() * 0.42)))
    Toolkit.StylePanel(rail, provider, "sidebar")

    local detail = Toolkit.Scroll(parent, provider, "detail")
    detail:Dock(FILL)
    if context.state.activeTab == "presets" then
        renderTrivia(context, provider, detail)
    else
        renderPreview(context, provider, detail, {height = 220})
        renderOptions(context, provider, detail, selectedSlot(provider, context), {
            removeLabel = shell.removeLabel or "REMOVE FROM GUNSMITH",
            option = {height = 42, active = shell.button and shell.button.selected or provider.accent,
                background = {17, 22, 26, 225}, corner = 0}
        })
    end

    for _, slot in ipairs(slotsFor(provider, context)) do
        local row = rail:Add("DPanel")
        row:Dock(TOP)
        row:DockMargin(8, 8, 8, 0)
        row:SetTall(76)
        row.Paint = function(_, width, height)
            Toolkit.Box(0, 0, width, height, shell.button and shell.button.background or provider.muted, 0)
        end

        local button = row:Add("DButton")
        button:Dock(LEFT)
        button:SetWide(200)
        button:SetText("")
        Toolkit.StyleButton(button, provider, false)
        button.Paint = function(panel, width, height)
            panel.FTSelected = context.state.selectedSlot == slot.id
            local active = panel.FTSelected
            local style = shell.button or {}
            Toolkit.Box(0, 0, width, height, active and (style.selected or provider.accent)
                or panel:IsHovered() and (style.hover or style.background) or style.background or provider.muted, 0)
            Toolkit.Text(string.upper(slotLabel(provider, slot)), provider.font, width * 0.5, height * 0.5,
                active and (style.hoverText or {10, 12, 14, 255}) or style.text or {210, 217, 221, 255},
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        button.DoClick = function()
            selectSlot(context, slot.id)
            safeRefresh(context, "category")
        end

        local id, definition = installed(context, slot)
        local inUse = row:Add("DLabel")
        inUse:Dock(FILL)
        inUse:DockMargin(12, 0, 4, 0)
        inUse:SetText(installedLabel(provider, definition, id))
        inUse:SetFont(Toolkit.ResolveFont(provider.hintFont, "DermaDefault"))
        inUse:SetTextColor(Toolkit.Color(id and provider.accent or {150, 156, 160, 255}))
        inUse:SetContentAlignment(4)
    end

    return rail
end

local function renderARC9AttachmentSurface(context, parent)
    local provider = providerFor(context, "attachments") or providerFor(context, "inspect")
    local shell = shellFor(provider)
    local slotBar = vgui.Create("DPanel", parent)
    slotBar:Dock(BOTTOM)
    slotBar:SetTall(shell.slotBarHeight or 118)
    Toolkit.StylePanel(slotBar, provider, "detail")

    local slots = Toolkit.Scroll(slotBar, provider, "detail")
    slots:Dock(FILL)

    for _, slot in ipairs(slotsFor(provider, context)) do
        chooseSlot(context, provider, slot, slots, {
            dock = LEFT,
            width = shell.slot and shell.slot.width or 172,
            height = shell.slot and shell.slot.height or 78,
            marginLeft = 7,
            marginTop = 12,
            marginRight = 3,
            selected = shell.button and shell.button.selected or provider.accent,
            background = shell.button and shell.button.background or provider.muted,
            icon = shell.slotIcons and (shell.slotIcons[slot.type] or shell.slotIcons.default)
        })
    end

    local detail = Toolkit.Scroll(parent, provider, "detail")
    detail:Dock(FILL)
    if context.state.activeTab == "stats" then
        renderStats(context, provider, detail, {title = shell.statsTitle or "PERFORMANCE"})
    elseif context.state.activeTab == "trivia" then
        renderTrivia(context, provider, detail)
    else
        renderPreview(context, provider, detail, {height = 250})
        renderOptions(context, provider, detail, selectedSlot(provider, context), {
            removeLabel = shell.removeLabel or "UNINSTALL",
            groupFolders = true,
            option = {height = 42, active = shell.button and shell.button.selected or provider.accent,
                background = {12, 30, 38, 232}, corner = 0}
        })
    end

    return slotBar
end

local function renderArcCWAttachmentSurface(context, parent)
    local provider = providerFor(context, "attachments") or providerFor(context, "inspect")
    local shell = shellFor(provider)
    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(math.max(250, math.floor(parent:GetWide() * 0.25)))
    Toolkit.StylePanel(left, provider, "sidebar")
    makeTabs(left, context, provider, {
        {id = "customize", label = "CUSTOMIZE", width = 100},
        {id = "presets", label = "PRESETS", width = 78},
        {id = "inventory", label = "INVENTORY", width = 88}
    })

    local slotScroll = Toolkit.Scroll(left, provider, "sidebar")
    slotScroll:Dock(FILL)
    for _, slot in ipairs(slotsFor(provider, context)) do
        chooseSlot(context, provider, slot, slotScroll, {
            height = shell.slot and shell.slot.height or 54,
            selected = shell.button and shell.button.selected or provider.accent,
            background = shell.button and shell.button.background or provider.muted,
            corner = 4,
            icon = shell.slotIcons and (shell.slotIcons[slot.type] or shell.slotIcons.default)
        })
    end

    local center = Toolkit.Scroll(parent, provider, "detail")
    center:Dock(LEFT)
    center:SetWide(math.max(230, math.floor(parent:GetWide() * 0.22)))
    renderOptions(context, provider, center, selectedSlot(provider, context), {
        removeLabel = shell.removeLabel or "UNINSTALL",
        option = {height = 34, active = shell.button and shell.button.selected or provider.accent,
            background = {36, 29, 21, 224}, corner = 4}
    })

    local right = Toolkit.Scroll(parent, provider, "detail")
    right:Dock(FILL)
    renderPreview(context, provider, right, {height = 245})
    if context.state.activeTab == "inventory" then
        renderStats(context, provider, right, {title = "INVENTORY / BALLISTICS"})
    elseif context.state.activeTab == "presets" then
        renderTrivia(context, provider, right)
    else
        renderStats(context, provider, right, {title = shell.statsTitle or "WEAPON BALLISTICS"})
    end

    local pickx = vgui.Create("DPanel", parent)
    pickx:Dock(BOTTOM)
    pickx:SetTall(44)
    pickx.Paint = function(_, width, height)
        Toolkit.Box(0, 0, width, height, {0, 0, 0, 120}, 0)
        Toolkit.Text("PICK-X  /  SELECTED ATTACHMENT", provider.hintFont, 8, height * 0.5,
            provider.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    return left
end

local function renderTacRPAttachmentSurface(context, parent)
    local provider = providerFor(context, "attachments") or providerFor(context, "inspect")
    local shell = shellFor(provider)
    local slotPanel = vgui.Create("DPanel", parent)
    slotPanel:Dock(LEFT)
    slotPanel:SetWide(math.max(210, math.floor(parent:GetWide() * 0.25)))
    Toolkit.StylePanel(slotPanel, provider, "sidebar")

    local grid = slotPanel:Add("DIconLayout")
    grid:Dock(FILL)
    grid:DockMargin(10, 24, 10, 10)
    grid:SetSpaceX(6)
    grid:SetSpaceY(10)

    for _, slot in ipairs(slotsFor(provider, context)) do
        local holder = grid:Add("DPanel")
        holder:SetSize(82, 58)
        holder.Paint = function(_, width, height)
            Toolkit.Box(0, 0, width, height, shell.button and shell.button.background or provider.muted, 0)
        end
        local button = holder:Add("DButton")
        button:Dock(FILL)
        button:SetText("")
        button.Paint = function(panel, width, height)
            local active = context.state.selectedSlot == slot.id
            local style = shell.button or {}
            Toolkit.Box(0, 0, width, height, active and (style.selected or provider.accent)
                or panel:IsHovered() and (style.hover or style.background) or style.background or provider.muted, 0)
            local icon = shell.slotIcons and (shell.slotIcons[slot.type] or shell.slotIcons.default)
            if icon then Toolkit.PaintMaterial(icon, 20, 2, 38, 38, {255, 255, 255, 220}) end
            Toolkit.Text(slot.name or slot.id, provider.hintFont, width * 0.5, height - 8,
                active and (style.hoverText or {20, 8, 8, 255}) or style.text or provider.accent,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        button.DoClick = function()
            selectSlot(context, slot.id)
            safeRefresh(context, "slot")
        end
    end

    local middle = Toolkit.Scroll(parent, provider, "detail")
    middle:Dock(LEFT)
    middle:SetWide(math.max(250, math.floor(parent:GetWide() * 0.34)))
    renderOptions(context, provider, middle, selectedSlot(provider, context), {
        removeLabel = shell.removeLabel or "REMOVE",
        option = {height = 34, active = shell.button and shell.button.selected or provider.accent,
            background = {39, 18, 18, 224}, corner = 0}
    })

    local right = Toolkit.Scroll(parent, provider, "detail")
    right:Dock(FILL)
    makeTabs(right, context, provider, {
        {id = "stats", label = "STATS", width = 72},
        {id = "trivia", label = "TRIVIA", width = 72},
        {id = "credits", label = "CREDITS", width = 82}
    })
    renderPreview(context, provider, right, {height = 210})
    renderTacRPCharts(context, provider, right)
    if context.state.activeTab == "trivia" or context.state.activeTab == "credits" then
        renderTrivia(context, provider, right)
    else
        renderStats(context, provider, right, {title = shell.statsTitle or "BALLISTICS"})
    end

    return slotPanel
end

local function renderFTAttachmentSurface(context, parent)
    return renderTFAAttachmentSurface(context, parent)
end

local function renderRoot(context, options, attachmentSurface)
    local provider = context.inspectProvider or providerFor(context, "inspect") or providerFor(context, "attachments")
    local root = vgui.Create("DPanel", context.root)
    root:Dock(FILL)
    Toolkit.StylePanel(root, provider, "panel")
    makeHeader(root, context, provider, options)

    local content = vgui.Create("DPanel", root)
    content:Dock(FILL)
    content.Paint = function() end
    if attachmentSurface then
        local attachmentProvider = context.attachmentsProvider or provider

        if attachmentProvider then
            callAttachmentSurface(attachmentProvider, context, content)
        else
            attachmentSurface(context, content)
        end
    end
    return root
end

local function renderTFA(context)
    local provider = context.inspectProvider or providerFor(context, "inspect")
    local shell = shellFor(provider)
    local root = vgui.Create("DPanel", context.root)
    root:Dock(FILL)
    Toolkit.StylePanel(root, provider, "panel")
    makeHeader(root, context, provider, {height = shell.headerHeight or 48,
        align = "left", closeLabel = shell.closeLabel or "X", closeWidth = shell.closeWidth or 44})

    local content = vgui.Create("DPanel", root)
    content:Dock(FILL)
    content.Paint = function() end

    local leftRail = makePanel(content, provider, "sidebar")
    leftRail:Dock(LEFT)
    leftRail:SetWide(32)
    local rightRail = makePanel(content, provider, "sidebar")
    rightRail:Dock(RIGHT)
    rightRail:SetWide(32)

    local info = makePanel(content, provider, "detail")
    info:Dock(LEFT)
    local contentWidth = content:GetWide()
    if contentWidth <= 0 then
        contentWidth = screenWidth()
    end
    info:SetWide(math.floor(contentWidth * 0.5))
    makeLabel(info, provider, displayName(context), shell.detail and shell.detail.titleFont or provider.font,
        provider.accent, {left = 22, top = 24})
    makeLabel(info, provider, tostring((effectiveIR(context).meta or {}).type or "weapon"),
        shell.detail and shell.detail.valueFont or provider.hintFont, provider.accent, {left = 22, top = 8})
    local meta = effectiveIR(context).meta or {}
    local infoLines = {
        meta.category and ("CATEGORY  " .. tostring(meta.category)) or nil,
        meta.author and ("CREATOR  " .. tostring(meta.author)) or nil,
        meta.manufacturer and ("MANUFACTURER  " .. tostring(meta.manufacturer)) or nil,
        meta.description and tostring(meta.description) or nil
    }
    for _, line in ipairs(infoLines) do
        if line then
            makeLabel(info, provider, line, provider.hintFont, {205, 211, 216, 255}, {left = 22, top = 6, right = 22})
        end
    end
    renderStats(context, provider, info, {title = "WEAPON DATA"})

    local right = vgui.Create("DPanel", content)
    right:Dock(FILL)
    Toolkit.StylePanel(right, provider, "sidebar")
    local attachmentProvider = context.attachmentsProvider or provider
    callAttachmentSurface(attachmentProvider, context, right)

    local falloff = vgui.Create("DPanel", right)
    falloff:Dock(BOTTOM)
    falloff:SetTall(math.max(96, math.floor(content:GetTall() * 0.2)))
    falloff.Paint = function(_, width, height)
        Toolkit.Text("DAMAGE FALLOFF", provider.hintFont, 8, 8, provider.accent)
        Toolkit.Line(8, height - 14, width - 8, height - 14, provider.accent)
        Toolkit.Line(8, height - 14, width * 0.72, height * 0.45, provider.accent)
        Toolkit.Line(width * 0.72, height * 0.45, width - 8, height * 0.45, provider.accent)
    end
    return root
end

local function renderMW(context)
    local provider = context.inspectProvider or providerFor(context, "inspect")
    local shell = shellFor(provider)
    return renderRoot(context, {height = shell.headerHeight or 72, align = "center",
        titleFont = shell.titleFont or provider.font, closeLabel = shell.closeLabel or "CLOSE",
        closeWidth = shell.closeWidth or 72, material = shell.headerMaterial,
        materialAlpha = shell.headerMaterialAlpha or 255}, renderMWAttachmentSurface)
end

local function renderARC9(context)
    local provider = context.inspectProvider or providerFor(context, "inspect")
    local shell = shellFor(provider)
    local root = vgui.Create("DPanel", context.root)
    root:Dock(FILL)
    Toolkit.StylePanel(root, provider, "panel")
    makeHeader(root, context, provider, {height = shell.headerHeight or 48,
        align = "left", closeLabel = shell.closeLabel or "BACK", closeWidth = shell.closeWidth or 70,
        material = shell.headerMaterial, materialAlpha = shell.headerMaterialAlpha or 255})
    makeTabs(root, context, provider, {
        {id = "customize", label = "CUSTOMIZE", width = 128},
        {id = "personalize", label = "PERSONALIZE", width = 128},
        {id = "stats", label = "STATS", width = 90},
        {id = "trivia", label = "TRIVIA", width = 90},
        {id = "inspect", label = "INSPECT", width = 90}
    })
    local content = vgui.Create("DPanel", root)
    content:Dock(FILL)
    content.Paint = function() end
    local attachmentProvider = context.attachmentsProvider or provider
    if attachmentProvider and attachmentProvider.id == "arc9" then
        renderARC9AttachmentSurface(context, content)
    else
        callAttachmentSurface(attachmentProvider, context, content)
    end
    return root
end

local function renderArcCW(context)
    local provider = context.inspectProvider or providerFor(context, "inspect")
    local shell = shellFor(provider)
    return renderRoot(context, {height = shell.headerHeight or 42, align = "right",
        closeLabel = shell.closeLabel or "X", closeWidth = shell.closeWidth or 44,
        material = shell.headerMaterial, materialAlpha = shell.headerMaterialAlpha or 255},
        renderArcCWAttachmentSurface)
end

local function renderTacRP(context)
    local provider = context.inspectProvider or providerFor(context, "inspect")
    local shell = shellFor(provider)
    return renderRoot(context, {height = shell.headerHeight or 44, align = "right",
        closeLabel = shell.closeLabel or "X", closeWidth = shell.closeWidth or 44,
        material = shell.headerMaterial, materialAlpha = shell.headerMaterialAlpha or 255},
        renderTacRPAttachmentSurface)
end

local function renderFT(context)
    return renderRoot(context, {height = 38, align = "left", closeLabel = "X", closeWidth = 40},
        renderFTAttachmentSurface)
end

local function renderSWB()
    return false
end

local function renderNoCustomization()
    return false
end

RendererMap.ft = renderFT
RendererMap.tfa = renderTFA
RendererMap.mw = renderMW
RendererMap.arc9 = renderARC9
RendererMap.arccw = renderArcCW
RendererMap.tacrp = renderTacRP
RendererMap.swb = renderSWB

AttachmentRendererMap.ft = renderFTAttachmentSurface
AttachmentRendererMap.tfa = renderTFAAttachmentSurface
AttachmentRendererMap.mw = renderMWAttachmentSurface
AttachmentRendererMap.arc9 = renderARC9AttachmentSurface
AttachmentRendererMap.arccw = renderArcCWAttachmentSurface
AttachmentRendererMap.tacrp = renderTacRPAttachmentSurface
AttachmentRendererMap.swb = renderNoCustomization

function Renderers.Get(id)
    return RendererMap[string.lower(tostring(id or "ft"))] or RendererMap.ft
end

function Renderers.GetAttachmentSurface(id)
    return AttachmentRendererMap[string.lower(tostring(id or "ft"))] or AttachmentRendererMap.ft
end

FTBase.Runtime.UI.Renderers = Renderers
