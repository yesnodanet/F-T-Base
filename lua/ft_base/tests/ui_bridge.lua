-- Client-side bridge regression checks.  The portable runner starts in a
-- server-safe realm, so this test installs small vendor/UI stubs and restores
-- every global before returning.

local UIBridge = assert(FTBase.Runtime.UIBridge, "FTBase.Runtime.UIBridge was not loaded")
local Networking = assert(FTBase.Runtime.Networking, "FTBase.Runtime.Networking was not loaded")
local Attachments = assert(FTBase.Runtime.Attachments, "FTBase.Runtime.Attachments was not loaded")

local savedGlobals = {}

for _, key in ipairs({
    "ARC9", "ArcCW", "CLIENT", "SERVER", "TFA", "gui", "input", "LocalPlayer",
    "MW_ATTS", "MW_CUSTOMIZEMENU", "mw_utils", "net", "unpack", "weapons"
}) do
    savedGlobals[#savedGlobals + 1] = {
        key = key,
        present = rawget(_G, key) ~= nil,
        value = rawget(_G, key)
    }
end

local function restoreGlobals()
    for _, entry in ipairs(savedGlobals) do
        if entry.present then
            _G[entry.key] = entry.value
        else
            _G[entry.key] = nil
        end
    end
end

local function panel(children)
    local value = {
        __invalid = false,
        children = children or {}
    }

    function value:GetChildren()
        return self.children
    end

    function value:GetY()
        return 0
    end

    function value:Remove()
        if self.__invalid then
            return
        end

        -- VGUI marks a panel invalid before invoking OnRemove.  Mirroring
        -- that ordering prevents a bridge cleanup callback from recursing
        -- when it removes the same panel a second time.
        self.__invalid = true

        if self.OnRemove then
            self:OnRemove()
        end
    end

    return value
end

local function fixtureIR(providers)
    local ir = FTBase.IR.New()
    ir.meta.printName = "Bridge fixture"
    ir.meta.category = "F&T Tests"
    ir.fire.rpm = 720
    ir.fire.automatic = true
    ir.ammo.clipSize = 30
    ir.ammo.type = "SMG1"
    ir.attachments.slots = {
        {id = "optic", type = "optic", name = "Optic"}
    }
    ir.attachments.definitions = {
        optic_a = {
            type = "optic",
            name = "Reflex",
            description = "F&T optic"
        }
    }
    ir.ui.visual.providers = providers
    return ir
end

local function fixtureWeapon(ir, className)
    local swep = {
        Class = className,
        Attachments = {sentinel = true},
        AttachmentAddresses = "sentinel",
        LastScroll = 12,
        Primary = {},
        Clip1 = function()
            return 12
        end,
        GetClass = function(self)
            return self.Class
        end,
        GetOwner = function(self)
            return self.Owner
        end,
        EntIndex = function()
            return 77
        end
    }

    swep.FTRuntime = FTBase.Runtime.Engine.BuildRuntime(swep, ir, nil)
    return swep
end

local ok, failure = pcall(function()
    CLIENT = true
    SERVER = false
    unpack = unpack or table.unpack

    local starts = {}
    local rawStart = function(name)
        starts[#starts + 1] = name
        return true
    end

    net = {
        Start = rawStart,
        WriteBool = function() end,
        WriteEntity = function() end,
        WriteString = function() end,
        WriteUInt = function() end,
        Send = function() end,
        SendToServer = function() end
    }

    gui = {
        EnableScreenClicker = function() end
    }

    input = {
        LookupBinding = function(bind)
            return bind
        end
    }

    local activeWeapon
    local owner = {
        Alive = function()
            return true
        end,
        GetActiveWeapon = function()
            return activeWeapon
        end,
        GetAmmoCount = function()
            return 90
        end
    }

    LocalPlayer = function()
        return owner
    end

    local arc9Close = {}
    local arc9Root = panel()
    arc9Root.topright_panel = panel({arc9Close})

    local arccwRoot = panel({
        {
            DoRightClick = function() end,
            GetY = function()
                return 0
            end
        }
    })

    local arc9Calls = {}
    local arc9Definition = {
            Base = "arc9_go_base",
            -- These methods represent gameplay owned by the vendor.  A
            -- bridge must never copy or invoke them on the F&T weapon.
            PrimaryAttack = function()
                error("vendor gameplay must not run")
            end,
            Reload = function()
                error("vendor gameplay must not run")
            end,
            Think = function()
                error("vendor gameplay must not run")
            end,
            AttInfoBar = "vendor-att-info",
            AttInfoBarAtt = "vendor-att",
            AttInfoBarAttSlot = "vendor-slot",
            CustomizeLastHoveredSlot = 4,
            CustomizeLastHoveredSlot2 = 5,
            LastScroll = 41,
            CreateCustomizeHUD = function(self)
                self.CustomizeHUD = arc9Root
                return true
            end,
            RemoveCustomizeHUD = function(self)
                if self.CustomizeHUD and self.CustomizeHUD.Remove then
                    self.CustomizeHUD:Remove()
                end
                return true
            end,
            DrawHUD = function()
                return true
            end
    }
    local arc9UIHelpers = {
        "CreateHUD_Stats", "CreateHUD_Credits", "CreatePresetName",
        "CreateExportPreset", "CreateDeleteDefPreset", "CreateImportPreset",
        "RefreshCustomizeMenu", "CreatePresetMenu", "ClosePresetMenu"
    }
    for _, methodName in ipairs(arc9UIHelpers) do
        arc9Definition[methodName] = function()
            arc9Calls[methodName] = (arc9Calls[methodName] or 0) + 1
            return true
        end
    end

    local classes = {
        arc9_go_ak47 = arc9Definition,
        arc9_go_base = {Base = "arc9_base"},
        arc9_base = {Base = "weapon_base"},
        arccw_go_ak47 = {
            Base = "arccw_base",
            CreateCustomize2HUD = function()
                ArcCW.InvHUD_FormGamemodeFunctions()
                ArcCW.InvHUD = arccwRoot
                return true
            end,
            DrawHUD = function()
                return true
            end
        },
        arccw_base = {Base = "weapon_base"},
        tfa_ins2_cw_ar15 = {
            Base = "tfa_gun_base",
            GenerateInspectionDerma = function()
                TFA.INSPECTIONPANEL = panel()
                return true
            end,
            DrawHUD = function()
                -- This message must be suppressed while a mixed-domain HUD
                -- bridge is rendered through a temporary state.
                net.Start("TFA_Attachment_Request")
                net.SendToServer()
                return true
            end
        },
        tfa_gun_base = {Base = "weapon_base"},
        mg_mike4 = {
            Base = "mg_base",
            CustomizationMenu = function()
                MW_CUSTOMIZEMENU = panel()
                return true
            end,
            DrawHUD = function()
                return true
            end
        },
        mg_base = {Base = "weapon_base"}
    }

    weapons = {
        GetStored = function(className)
            return classes[className]
        end
    }

    ARC9 = {Attachments = {}}
    TFA = {}
    local originalArcCWPlayerCanAttach = function()
        return "vendor"
    end
    local originalConVar = {
        marker = true,
        GetBool = function()
            return true
        end
    }
    local gamemodeButtonsValue
    ArcCW = {
        AttachmentTable = {},
        ConVars = {attinv_gamemodebuttons = originalConVar},
        Inv_SelectedMenu = false,
        Inv_SelectedInfo = false,
        Inv_Fade = 0.5,
        Inv_Hidden = "hidden",
        Inv_ShownAtt = "shown",
        PlayerCanAttach = originalArcCWPlayerCanAttach,
        InvHUD_FormGamemodeFunctions = function()
            gamemodeButtonsValue = ArcCW.ConVars.attinv_gamemodebuttons:GetBool()
        end
    }

    local originalMWAttachment = function()
        return "vendor"
    end
    MW_ATTS = {}
    mw_utils = {SendAttachmentToServer = originalMWAttachment}
    MW_CUSTOMIZEMENU = "original-menu"

    local providers = FTBase.Runtime.ProviderHost
    for _, id in ipairs({"tfa", "arc9", "arccw", "mw", "tacrp", "swb"}) do
        assert(type(UIBridge.Get(id)) == "table", "missing registered UI bridge: " .. id)
        assert(type(providers.Get(id)) == "table", "missing visual provider: " .. id)
    end

    -- Mixed provider selection remains per-domain and never collapses to one
    -- vendor runtime owner.
    local mixedIR = fixtureIR({
        inspect = "tfa",
        attachments = "mw",
        hud = "tfa",
        presentation = "tfa"
    })
    local mixedRuntime = {ir = mixedIR}
    assert(providers.GetProviderId(mixedRuntime, "inspect") == "tfa",
        "mixed inspect provider was not selected")
    assert(providers.GetProviderId(mixedRuntime, "attachments") == "mw",
        "mixed attachment provider was not selected")
    assert(providers.GetProviderId(mixedRuntime, "hud") == "tfa",
        "mixed HUD provider was not selected")

    -- Mixed-domain bridge switching must respect the requested domain.  An MW
    -- attachment panel followed by TFA inspection should close/switch rather
    -- than refreshing the MW surface in place.
    local mixedWeapon = fixtureWeapon(fixtureIR({
        inspect = "tfa",
        attachments = "mw",
        hud = "tfa",
        presentation = "tfa"
    }), "ft_bridge_mixed")
    mixedWeapon.Owner = owner
    activeWeapon = mixedWeapon
    assert(UIBridge.Open(mixedWeapon, "attachments"),
        "mixed MW attachment bridge did not open")
    local mixedCustomization = mixedWeapon.Customization
    local mixedPrimary = mixedWeapon.Primary
    assert(FTBase.Runtime.Inspect and not FTBase.Runtime.Inspect.IsOpen(mixedWeapon),
        "MW attachment bridge was incorrectly reported as inspect-open")
    assert(FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Open
        and FTBase.Runtime.Inspect.Toggle(mixedWeapon),
        "mixed TFA inspect bridge did not switch from MW")
    assert(UIBridge.IsBridgeWeapon(mixedWeapon, "tfa"),
        "mixed inspect request retained the MW bridge")
    assert(FTBase.Runtime.Inspect.IsOpen(mixedWeapon),
        "TFA inspect bridge was not reported as inspect-open")
    assert(mixedWeapon.Customization == nil,
        "mixed inspect switch did not restore MW attachment projection")
    assert(TFA.INSPECTIONPANEL ~= nil,
        "mixed TFA inspect panel was not created")
    assert(UIBridge.Close(mixedWeapon), "mixed TFA bridge did not close")

    -- Rendering a different HUD provider uses a temporary state.  Its overlay
    -- and net guard must unwind back to the still-open MW customization state.
    assert(UIBridge.Open(mixedWeapon, "attachments"),
        "mixed MW bridge did not reopen")
    mixedCustomization = mixedWeapon.Customization
    mixedPrimary = mixedWeapon.Primary
    assert(not FTBase.Runtime.Inspect.IsOpen(mixedWeapon),
        "MW attachment bridge was treated as an inspect bridge after reopen")
    assert(not FTBase.Runtime.Inspect.Refresh(mixedWeapon),
        "Inspect.Refresh refreshed the MW attachment bridge")
    local startsBeforeMixedHUD = #starts
    assert(UIBridge.DrawHUD(mixedWeapon), "mixed TFA HUD bridge did not render")
    assert(#starts == startsBeforeMixedHUD,
        "temporary mixed HUD state leaked a vendor net transaction")
    assert(UIBridge.IsOpen(mixedWeapon)
        and UIBridge.IsBridgeWeapon(mixedWeapon, "mw"),
        "temporary mixed HUD state replaced the active MW bridge")
    assert(mixedWeapon.Customization == mixedCustomization
        and mixedWeapon.Primary == mixedPrimary,
        "temporary mixed HUD state did not restore active MW overlays")
    assert(UIBridge.Close(mixedWeapon), "mixed MW bridge did not close")

    -- ARC9 facade: projected slots, F&T attachment requests, nil-safe helper
    -- methods, and vendor net suppression.
    local arc9Weapon = fixtureWeapon(fixtureIR({
        inspect = "arc9",
        attachments = "arc9",
        hud = "arc9",
        presentation = "arc9"
    }), "ft_bridge_arc9")
    arc9Weapon.Owner = owner
    activeWeapon = arc9Weapon
    local originalSlots = arc9Weapon.Attachments
    local originalAddresses = arc9Weapon.AttachmentAddresses

    assert(UIBridge.GetConfigured(arc9Weapon, "attachments") == "arc9",
        "ARC9 bridge configuration was not resolved")
    assert(UIBridge.IsAvailable(arc9Weapon, "attachments"),
        "ARC9 UI dependency fixture was rejected")
    assert(UIBridge.Open(arc9Weapon, "attachments"), "ARC9 bridge did not open")
    assert(UIBridge.IsOpen(arc9Weapon), "ARC9 bridge did not retain open state")
    assert(type(arc9Weapon.Attachments) == "table" and #arc9Weapon.Attachments == 1,
        "ARC9 did not receive an F&T projected slot")
    assert(arc9Weapon.AttInfoBar == "vendor-att-info"
        and arc9Weapon.AttInfoBarAtt == "vendor-att"
        and arc9Weapon.AttInfoBarAttSlot == "vendor-slot",
        "ARC9 AttInfoBar UI fields were not projected")
    assert(arc9Weapon.CustomizeLastHoveredSlot == 4
        and arc9Weapon.CustomizeLastHoveredSlot2 == 5
        and arc9Weapon.LastScroll == 41,
        "ARC9 hover/scroll UI fields were not projected")

    for _, methodName in ipairs(arc9UIHelpers) do
        assert(type(arc9Weapon[methodName]) == "function",
            "ARC9 UI overlay is missing " .. methodName)
        local helperCalled, helperResult = pcall(arc9Weapon[methodName], arc9Weapon)
        assert(helperCalled and helperResult ~= false,
            "ARC9 UI overlay errored: " .. methodName .. " / " .. tostring(helperResult))
        assert(arc9Calls[methodName] == 1,
            "ARC9 UI overlay did not call vendor presentation helper: " .. methodName)
    end

    local filled = arc9Weapon:GetFilledMergeSlot(1)
    assert(type(filled) == "table", "ARC9 GetFilledMergeSlot returned nil")
    local position, facing, origin = arc9Weapon:GetAttachmentPos(1)
    assert(type(position) == "Vector" and type(facing) == "Angle" and type(origin) == "Vector",
        "ARC9 GetAttachmentPos did not return safe F&T values")
    assert(arc9Weapon:GetCurrentFiremode() == 2,
        "ARC9 GetCurrentFiremode did not return the numeric F&T mode")
    local currentMode = arc9Weapon:GetCurrentFiremodeTable()
    assert(type(currentMode) == "table" and currentMode.Mode == 2,
        "ARC9 GetCurrentFiremodeTable did not expose the F&T mode table")
    assert(arc9Weapon.ClipSize == 30 and arc9Weapon.ChamberSize == 1
        and arc9Weapon.Num == 1 and arc9Weapon.ReloadTime == 1.8
        and arc9Weapon.ManualAction == false
        and arc9Weapon.TriggerDelayRepeat == false
        and arc9Weapon.TriggerDelayTime == 0
        and arc9Weapon.CycleTime == 0
        and arc9Weapon.PostBurstDelay == 0
        and arc9Weapon.BottomlessClip == false,
        "ARC9 stats facade did not provide safe F&T-backed operands")
    assert(type(arc9Weapon.BodyDamageMults) == "table"
        and arc9Weapon:RandomChoice({"first", "second"}) == "first",
        "ARC9 benchmark helpers did not receive safe presentation values")

    local arc9FacadeMethods = {
        "GetTrueRPM", "GetAnimationTime", "GetAnimationEntry", "GetCurrentFiremodeTable",
        "GetUBGL", "GetMaxClip2", "GetNthShot", "GetHeatAmount", "GetHeatLockout",
        "GetBipod", "StillWaiting", "HoldBreathHUD", "DrawRadialMenu", "DrawLockOnHUD",
        "GetReadyTime", "GetSlotMissingDependents", "ToggleStat"
    }
    for _, methodName in ipairs(arc9FacadeMethods) do
        assert(type(arc9Weapon[methodName]) == "function",
            "ARC9 facade is missing " .. methodName)
        local called, result = pcall(arc9Weapon[methodName], arc9Weapon, 1)
        assert(called, "ARC9 facade errored: " .. methodName .. " / " .. tostring(result))
    end
    assert(arc9Weapon.PrimaryAttack == nil and arc9Weapon.Reload == nil
        and arc9Weapon.Think == nil,
        "ARC9 vendor gameplay methods leaked onto the F&T weapon")
    assert(type(arc9Weapon.GetBinding(arc9Weapon, "+use")) == "string",
        "ARC9 GetBinding did not return a string")

    local syntheticId
    for id in pairs(ARC9.Attachments) do
        if string.find(id, "_att_", 1, true) then
            syntheticId = id
            break
        end
    end
    assert(syntheticId ~= nil, "ARC9 did not project an F&T attachment option")

    local originalRequest = Networking.RequestAttachment
    local requests = {}
    Networking.RequestAttachment = function(swep, slotId, attachmentId)
        requests[#requests + 1] = {slotId = slotId, attachmentId = attachmentId}

        if attachmentId == "" then
            Attachments.Uninstall(swep.FTRuntime, slotId)
        else
            Attachments.Install(swep.FTRuntime, slotId, attachmentId)
        end

        return true
    end

    assert(arc9Weapon:Attach(1, syntheticId), "ARC9 attach facade rejected a valid F&T option")
    assert(requests[1].slotId == "optic" and requests[1].attachmentId == "optic_a",
        "ARC9 attach facade did not emit {slotId, attachmentId}")
    assert(arc9Weapon.FTRuntime.attachments.installed.optic == "optic_a",
        "ARC9 projected install did not update F&T runtime")
    assert(arc9Weapon:Detach(1), "ARC9 detach facade rejected an installed F&T option")
    assert(requests[2].slotId == "optic" and requests[2].attachmentId == "",
        "ARC9 detach facade did not emit an empty attachment id")
    assert(arc9Weapon.FTRuntime.attachments.installed.optic == nil,
        "ARC9 projected remove did not update F&T runtime")
    Networking.RequestAttachment = originalRequest

    local beforeBlocked = #starts
    assert(net.Start("ARC9_togglecustomize") == false,
        "ARC9 vendor customize net message was not blocked")
    net.SendToServer()
    assert(#starts == beforeBlocked, "blocked ARC9 net transaction leaked to transport")
    local wrappedStart = net.Start
    assert(type(arc9Close.DoClick) == "function", "ARC9 close button was not patched")
    assert(arc9Close.DoClick(), "ARC9 close button did not close through the bridge")
    assert(not UIBridge.IsOpen(arc9Weapon), "ARC9 bridge remained open after close")
    assert(arc9Weapon.Attachments == originalSlots
        and arc9Weapon.AttachmentAddresses == originalAddresses,
        "ARC9 projected state was not restored")
    assert(net.Start == rawStart, "ARC9 net.Start wrapper was not restored")
    assert(wrappedStart ~= rawStart, "ARC9 net guard was not installed")
    assert(arc9Weapon.AttInfoBar == nil and arc9Weapon.AttInfoBarAtt == nil
        and arc9Weapon.AttInfoBarAttSlot == nil,
        "ARC9 AttInfoBar UI fields were not restored")
    assert(arc9Weapon.CustomizeLastHoveredSlot == nil
        and arc9Weapon.CustomizeLastHoveredSlot2 == nil
        and arc9Weapon.LastScroll == 12,
        "ARC9 hover/scroll UI fields were not restored")

    -- ArcCW's attachment predicate and gamemode-convar guard are scoped to
    -- the bridge and must be removed when the panel is externally deleted.
    local arcwWeapon = fixtureWeapon(fixtureIR({
        inspect = "arccw",
        attachments = "arccw",
        hud = "arccw",
        presentation = "arccw"
    }), "ft_bridge_arccw")
    arcwWeapon.Owner = owner
    activeWeapon = arcwWeapon
    local oldSelectedMenu = ArcCW.Inv_SelectedMenu
    local oldSelectedInfo = ArcCW.Inv_SelectedInfo
    local oldPlayerCanAttach = ArcCW.PlayerCanAttach
    assert(UIBridge.Open(arcwWeapon, "attachments"), "ArcCW bridge did not open")
    assert(gamemodeButtonsValue == false,
        "ArcCW gamemode buttons were not disabled while building the UI")
    assert(ArcCW.ConVars.attinv_gamemodebuttons == originalConVar,
        "ArcCW gamemode convar was not restored after UI creation")
    assert(ArcCW.Inv_SelectedMenu == 1 and ArcCW.Inv_SelectedInfo == 1,
        "ArcCW selected-menu state was not scoped to the bridge")

    local validResult, installedResult, blockedResult = arcwWeapon:ValidateAttachment(
        "optic_a", nil, 1)
    assert(validResult and not installedResult and not blockedResult,
        "ArcCW ValidateAttachment did not use F&T attachment rules")
    assert(ArcCW.PlayerCanAttach(ArcCW, owner, arcwWeapon, "optic_a", 1, false),
        "ArcCW PlayerCanAttach facade rejected a valid F&T option")
    assert(not ArcCW.PlayerCanAttach(ArcCW, {}, arcwWeapon, "optic_a", 1, false),
        "ArcCW PlayerCanAttach facade accepted a foreign player")

    -- A partially initialized runtime must not make the vendor presentation
    -- layer throw while F&T is still rebuilding attachment state.  Restore the
    -- projected values before exercising the normal close/cleanup path below.
    local savedArcCWInstalled = arcwWeapon.FTRuntime.attachments.installed
    local savedArcCWProjection = arcwWeapon.Attachments
    arcwWeapon.FTRuntime.attachments.installed = nil
    arcwWeapon.Attachments = nil
    local malformedArcCWOK = pcall(function()
        arcwWeapon:GetSlotInstalled(1)
        arcwWeapon:ValidateAttachment("optic_a", nil, 1)
        ArcCW.PlayerCanAttach(ArcCW, owner, arcwWeapon, "optic_a", 1, false)
    end)
    arcwWeapon.FTRuntime.attachments.installed = savedArcCWInstalled
    arcwWeapon.Attachments = savedArcCWProjection
    assert(malformedArcCWOK,
        "ArcCW facade errored for a partially initialized F&T attachment state")

    local blockedBefore = #starts
    assert(net.Start("arccw_slidepos") == false,
        "ArcCW slide-position net message was not blocked")
    net.SendToServer()
    assert(net.Start("arccw_togglenum") == false,
        "ArcCW toggle-number net message was not blocked")
    net.SendToServer()
    assert(#starts == blockedBefore, "blocked ArcCW net transaction leaked to transport")

    local externalPanel = ArcCW.InvHUD
    externalPanel:Remove()
    assert(not UIBridge.IsOpen(arcwWeapon),
        "ArcCW external panel removal did not close the bridge")
    assert(ArcCW.PlayerCanAttach == oldPlayerCanAttach,
        "ArcCW PlayerCanAttach facade was not restored")
    assert(ArcCW.Inv_SelectedMenu == oldSelectedMenu
        and ArcCW.Inv_SelectedInfo == oldSelectedInfo,
        "ArcCW selected-menu globals were not restored")
    assert(ArcCW.InvHUD == nil and ArcCW.Inv_Fade == 0.5
        and ArcCW.Inv_Hidden == "hidden" and ArcCW.Inv_ShownAtt == "shown",
        "ArcCW UI globals were not restored")
    assert(ArcCW.ConVars.attinv_gamemodebuttons == originalConVar,
        "ArcCW convar changed after bridge cleanup")
    assert(net.Start == rawStart, "ArcCW net.Start wrapper was not restored")

    -- MW's attachment interception is temporary and must disappear with the
    -- last bridge, while still producing F&T-owned requests.
    local mwWeapon = fixtureWeapon(fixtureIR({
        inspect = "mw",
        attachments = "mw",
        hud = "mw",
        presentation = "mw"
    }), "ft_bridge_mw")
    mwWeapon.Owner = owner
    activeWeapon = mwWeapon
    local oldMWMenu = MW_CUSTOMIZEMENU
    local oldMWSend = mw_utils.SendAttachmentToServer
    assert(UIBridge.Open(mwWeapon, "attachments"), "MW bridge did not open")
    assert(mw_utils.SendAttachmentToServer ~= oldMWSend,
        "MW attachment interceptor was not installed")

    local mwRequests = {}
    local mwOriginalRequest = Networking.RequestAttachment
    Networking.RequestAttachment = function(swep, slotId, attachmentId)
        mwRequests[#mwRequests + 1] = {slotId = slotId, attachmentId = attachmentId}
        return true
    end
    local options = mwWeapon.Customization and mwWeapon.Customization.optic
    assert(type(options) == "table" and type(options[2]) == "string"
        and type(MW_ATTS[options[2]]) == "table",
        "MW customization projection omitted the F&T option")
    assert(mw_utils.SendAttachmentToServer(mwWeapon, "optic", 2),
        "MW attachment interceptor rejected a valid F&T option")
    assert(mwRequests[1].slotId == "optic" and mwRequests[1].attachmentId == "optic_a",
        "MW interceptor did not emit an F&T attachment request")
    Networking.RequestAttachment = mwOriginalRequest
    assert(UIBridge.Close(mwWeapon), "MW bridge did not close")
    assert(mw_utils.SendAttachmentToServer == oldMWSend,
        "MW attachment interceptor was not restored")
    assert(mw_utils.SendAttachmentToServer({}, "optic", 2) == "vendor",
        "MW attachment interceptor did not restore vendor delegation")
    assert(MW_CUSTOMIZEMENU == oldMWMenu,
        "MW customization menu global was not restored")

    -- If the vendor removes its panel first, bridge cleanup must not invoke
    -- CustomizationMenu again (which would create a fresh panel while closing).
    assert(UIBridge.Open(mwWeapon, "attachments"),
        "MW bridge did not reopen for external teardown")
    local externalMWPanel = MW_CUSTOMIZEMENU
    assert(externalMWPanel and externalMWPanel.Remove,
        "MW bridge did not expose a removable customization panel")
    externalMWPanel:Remove()
    assert(not UIBridge.IsOpen(mwWeapon),
        "MW external panel removal did not close the bridge")
    assert(MW_CUSTOMIZEMENU == oldMWMenu,
        "MW external panel cleanup recreated or leaked the customization menu")
    assert(mw_utils.SendAttachmentToServer == oldMWSend,
        "MW interceptor was not restored after external panel cleanup")

    -- Native fixtures must not silently fall back to the F&T inspection panel
    -- when the declared vendor dependency is unavailable.
    local oldInspectOpen = FTBase.Runtime.Inspect and FTBase.Runtime.Inspect.Open
    local inspectCalls = 0
    if FTBase.Runtime.Inspect then
        FTBase.Runtime.Inspect.Open = function()
            inspectCalls = inspectCalls + 1
            return true
        end
    end

    local native = fixtureWeapon(fixtureIR({
        inspect = "arc9",
        attachments = "arc9",
        hud = "arc9",
        presentation = "arc9"
    }), "ft_native_bridge_missing")
    native.Owner = owner
    native.FTNative = true
    native.FTUIBridge = {
        provider = "arc9",
        clientOnly = true,
        uiOnly = true
    }
    local availableWeapons = weapons
    weapons = {
        GetStored = function()
            return nil
        end
    }
    assert(UIBridge.GetConfigured(native, "attachments") == "arc9",
        "native bridge configuration was lost when dependency was absent")
    assert(not FTBase.Runtime.Customization.Open(native),
        "native bridge fell back to F&T UI without its vendor dependency")
    assert(inspectCalls == 0, "native no-fallback path invoked the F&T inspection panel")
    weapons = availableWeapons
    if FTBase.Runtime.Inspect then
        FTBase.Runtime.Inspect.Open = oldInspectOpen
    end

    -- A vendor callback failure must still clean every transient overlay and
    -- leave the net wrappers usable for subsequent F&T requests.
    local failingClasses = {
        arc9_go_ak47 = {
            Base = "arc9_go_base",
            CreateCustomizeHUD = function()
                error("intentional UI failure")
            end
        },
        arc9_go_base = {Base = "arc9_base"},
        arc9_base = {Base = "weapon_base"}
    }
    weapons = {
        GetStored = function(className)
            return failingClasses[className]
        end
    }
    local failing = fixtureWeapon(fixtureIR({
        inspect = "arc9",
        attachments = "arc9",
        hud = "arc9",
        presentation = "arc9"
    }), "ft_bridge_failing")
    failing.Owner = owner
    local failingSlots = failing.Attachments
    assert(not UIBridge.Open(failing, "attachments"),
        "failing vendor UI callback was reported as successful")
    assert(not UIBridge.IsOpen(failing), "failed bridge retained an open state")
    assert(failing.Attachments == failingSlots,
        "failed bridge did not restore projected weapon fields")
    assert(net.Start == rawStart, "failed bridge leaked a net wrapper")
end)

restoreGlobals()

if not ok then
    error(failure, 0)
end

print("F&T UI bridge regression tests passed")
return true
