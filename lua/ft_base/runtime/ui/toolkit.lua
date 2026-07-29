FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}
FTBase.Runtime.UI = FTBase.Runtime.UI or {}

local Toolkit = FTBase.Module.Define("RuntimeUI", {})

local Fonts = {
    Default = true,
    DermaDefault = true,
    DermaDefaultBold = true,
    DermaLarge = true,
    DermaLargeBold = true,
    Trebuchet18 = true,
    Trebuchet19 = true,
    Trebuchet20 = true,
    Trebuchet22 = true,
    Trebuchet24 = true,
    Trebuchet32 = true
}

local Materials = {}

local function valueColor(value, fallback)
    value = value or fallback or {255, 255, 255, 255}

    if Color then
        return Color(value.r or value[1] or 255, value.g or value[2] or 255,
            value.b or value[3] or 255, value.a or value[4] or 255)
    end

    return value
end

local function numeric(value, fallback)
    value = tonumber(value)
    return value or fallback or 0
end

local function fontUsable(font)
    if type(font) ~= "string" or font == "" or not Fonts[font] then
        return false
    end

    if CLIENT and surface and surface.SetFont and surface.GetTextSize then
        local ok, width, height = pcall(function()
            surface.SetFont(font)
            return surface.GetTextSize("Ag")
        end)

        if not ok or type(width) ~= "number" or type(height) ~= "number" or height <= 0 then
            return false
        end
    end

    return true
end

function Toolkit.RegisterFont(name)
    if type(name) == "string" and name ~= "" then
        Fonts[name] = true
    end
end

function Toolkit.ResolveFont(font, fallback)
    fallback = fallback or "DermaDefault"

    if fontUsable(font) then
        return font
    end

    if fontUsable(fallback) then
        return fallback
    end

    return "DermaDefault"
end

function Toolkit.Color(value, fallback)
    return valueColor(value, fallback)
end

function Toolkit.Material(path, flags)
    if not CLIENT or type(path) ~= "string" or path == "" or not Material then
        return nil
    end

    if Materials[path] then
        return Materials[path]
    end

    local ok, material = pcall(Material, path, flags or "mips smooth")

    if ok and material then
        Materials[path] = material
        return material
    end

    return nil
end

function Toolkit.PaintMaterial(pathOrMaterial, x, y, width, height, tint)
    if not surface or not surface.SetMaterial or not surface.DrawTexturedRect then
        return false
    end

    local material = type(pathOrMaterial) == "string"
        and Toolkit.Material(pathOrMaterial) or pathOrMaterial

    if not material then
        return false
    end

    tint = valueColor(tint)
    surface.SetDrawColor(tint.r or tint[1], tint.g or tint[2], tint.b or tint[3], tint.a or tint[4])
    surface.SetMaterial(material)
    surface.DrawTexturedRect(numeric(x), numeric(y), numeric(width), numeric(height))
    return true
end

function Toolkit.Text(text, font, x, y, textColor, xAlign, yAlign)
    if not draw or not draw.SimpleText then
        return false
    end

    x = tonumber(x)
    y = tonumber(y)

    if not x or not y then
        return false
    end

    local safeFont = Toolkit.ResolveFont(font, "DermaDefault")
    local ok = pcall(draw.SimpleText, tostring(text or ""), safeFont, x, y,
        valueColor(textColor), xAlign or TEXT_ALIGN_LEFT, yAlign or TEXT_ALIGN_TOP)
    return ok
end

function Toolkit.Box(x, y, width, height, fill, radius)
    if draw and draw.RoundedBox then
        draw.RoundedBox(tonumber(radius) or 0, numeric(x), numeric(y), numeric(width), numeric(height), valueColor(fill))
    elseif surface and surface.SetDrawColor and surface.DrawRect then
        local color = valueColor(fill)
        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        surface.DrawRect(numeric(x), numeric(y), numeric(width), numeric(height))
    end
end

function Toolkit.Line(x, y, x2, y2, lineColor)
    if not surface or not surface.SetDrawColor or not surface.DrawLine then
        return
    end

    local color = valueColor(lineColor)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawLine(numeric(x), numeric(y), numeric(x2), numeric(y2))
end

function Toolkit.StylePanel(panel, provider, role)
    if not panel then
        return panel
    end

    local shell = provider and provider.shell or {}
    local style = shell[role or "panel"] or {}
    local background = style.background or shell.background or provider and provider.muted
    local material = style.material or shell[(role or "panel") .. "Material"]

    panel.Paint = function(_, width, height)
        Toolkit.Box(0, 0, width, height, background, style.corner or shell.corner)

        if material then
            Toolkit.PaintMaterial(material, 0, 0, width, height,
                {255, 255, 255, style.materialAlpha or shell.materialAlpha or 255})
        end
    end

    return panel
end

function Toolkit.StyleButton(button, provider, selected)
    if not button then
        return button
    end

    local shell = provider and provider.shell or {}
    local style = shell.button or {}
    local accent = provider and provider.accent or {94, 190, 235, 255}
    local background = selected and (style.selected or style.hover) or style.background

    button:SetFont(Toolkit.ResolveFont(style.font or provider and provider.font, "DermaDefaultBold"))
    button:SetTextColor(Toolkit.Color(style.text or accent))
    button.Paint = function(panel, width, height)
        local hovered = panel.IsHovered and panel:IsHovered()
        local active = selected or panel.FTSelected
        local fill = active and (style.selected or style.hover)
            or hovered and (style.hover or background) or background
        local textColor = active and (style.selectedText or style.hoverText or style.text or accent)
            or hovered and (style.hoverText or accent) or (style.text or accent)

        Toolkit.Box(0, 0, width, height, fill or {20, 26, 32, 225}, style.corner or shell.corner)

        if style.border and surface and surface.SetDrawColor and surface.DrawOutlinedRect then
            local border = Toolkit.Color(style.border)
            surface.SetDrawColor(border.r, border.g, border.b, border.a)
            surface.DrawOutlinedRect(0, 0, width, height, tonumber(style.borderWidth) or 1)
        end

        panel:SetTextColor(Toolkit.Color(textColor))

        if active and style.selectedMaterial then
            Toolkit.PaintMaterial(style.selectedMaterial, 0, 0, width, height,
                {255, 255, 255, style.selectedMaterialAlpha or 80})
        end
    end

    return button
end

function Toolkit.Scroll(parent, provider, role)
    if not vgui or not vgui.Create then
        return nil
    end

    local panel = vgui.Create("DScrollPanel", parent)
    Toolkit.StylePanel(panel, provider, role or "detail")

    if panel.GetVBar then
        local bar = panel:GetVBar()

        if bar then
            bar.Paint = function(_, width, height)
                Toolkit.Box(0, 0, width, height,
                    {0, 0, 0, 90})
            end

            if bar.btnUp then
                bar.btnUp.Paint = function() end
            end

            if bar.btnDown then
                bar.btnDown.Paint = function() end
            end

            if bar.btnGrip then
                bar.btnGrip.Paint = function(_, width, height)
                    Toolkit.Box(0, 0, width, height, provider and provider.accent or {94, 190, 235, 180})
                end
            end
        end
    end

    return panel
end

function Toolkit.Label(parent, text, font, textColor, margin)
    if not parent or not parent.Add then
        return nil
    end

    local label = parent:Add("DLabel")
    label:SetText(tostring(text or ""))
    label:SetFont(Toolkit.ResolveFont(font, "DermaDefault"))
    label:SetTextColor(Toolkit.Color(textColor))
    label:Dock(TOP)
    margin = margin or {}
    label:DockMargin(margin.left or 8, margin.top or 4, margin.right or 8, margin.bottom or 0)
    label:SizeToContentsY()
    return label
end

function Toolkit.Request(ctx, slotId, attachmentId)
    if not ctx or not ctx.swep or not FTBase.Runtime.Networking then
        return false
    end

    return FTBase.Runtime.Networking.RequestAttachment(ctx.swep, tostring(slotId or ""),
        tostring(attachmentId or ""))
end

function Toolkit.SafeSize(panel, width, height)
    if not panel then
        return
    end

    if panel.SetSize then
        panel:SetSize(math.max(1, math.floor(tonumber(width) or 1)),
            math.max(1, math.floor(tonumber(height) or 1)))
    end
end

FTBase.Runtime.UI.Toolkit = Toolkit
