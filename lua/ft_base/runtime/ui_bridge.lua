FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local UIBridge = FTBase.Module.Define("UIBridge", {})

local Table = FTBase.Util.Table
local Bridges = {}
local States = setmetatable({}, {__mode = "k"})
-- HUD rendering can briefly need a provider different from the open
-- customization surface.  Keep that state separate so the active bridge is
-- never lost while the temporary provider is being prepared and torn down.
local TemporaryStates = setmetatable({}, {__mode = "k"})
local MissingWarnings = {}
local callVendor
local restoreArcCWFacade
local restoreMWInterceptor

-- A bridge must never inherit a vendor SWEP.  The allow lists below are the
-- only vendor members that may be called while a F&T weapon is active.  They
-- contain UI construction/drawing helpers only; weapon lifecycle, firing,
-- animation, networking and attachment-state methods remain F&T-owned.
local function asSet(values)
    local result = {}

    for _, value in ipairs(values or {}) do
        result[tostring(value)] = true
    end

    return result
end

local function copy(value)
    if type(value) ~= "table" then
        return value
    end

    if table and table.Copy then
        return table.Copy(value)
    end

    return Table.DeepCopy(value)
end

-- Vendor UI descriptor tables may contain executable callbacks.  Copying them
-- verbatim would let a presentation field invoke arbitrary vendor gameplay or
-- persistence code on the F&T SWEP.  Preserve data needed for rendering while
-- dropping function values (all supported actions are installed through the
-- explicit F&T facades below).
local function copyUIData(value, seen)
    local kind = type(value)

    if kind ~= "table" then
        return kind == "function" and nil or value
    end

    seen = seen or {}

    if seen[value] then
        return seen[value]
    end

    local result = {}
    seen[value] = result

    for key, child in pairs(value) do
        if type(child) ~= "function" then
            local copied = copyUIData(child, seen)

            if copied ~= nil then
                result[key] = copied
            end
        end
    end

    return result
end

local function normalize(value)
    return string.lower(tostring(value or ""))
end

-- ARC9 expects native Vector/Angle values and immediately invokes their
-- arithmetic/transform methods from its HUD.  F&T attachment metadata may be
-- represented as native values or plain compiler tables, so normalize both
-- forms and always provide a non-nil fallback for the vendor presentation
-- layer.
local function safeVector(value)
    if type(isvector) == "function" then
        local ok, result = pcall(isvector, value)

        if ok and result then
            return value
        end
    end

    local x, y, z = 0, 0, 0

    if type(value) == "table" then
        x = tonumber(value.x or value[1]) or 0
        y = tonumber(value.y or value[2]) or 0
        z = tonumber(value.z or value[3]) or 0
    end

    if type(Vector) == "function" then
        local ok, result = pcall(Vector, x, y, z)

        if ok and result ~= nil then
            return result
        end
    end

    return {x = x, y = y, z = z}
end

local function safeAngle(value)
    if type(isangle) == "function" then
        local ok, result = pcall(isangle, value)

        if ok and result then
            return value
        end
    end

    local pitch, yaw, roll = 0, 0, 0

    if type(value) == "table" then
        pitch = tonumber(value.p or value.pitch or value[1]) or 0
        yaw = tonumber(value.y or value.yaw or value[2]) or 0
        roll = tonumber(value.r or value.roll or value[3]) or 0
    end

    if type(Angle) == "function" then
        local ok, result = pcall(Angle, pitch, yaw, roll)

        if ok and result ~= nil then
            return result
        end
    end

    return {p = pitch, y = yaw, r = roll}
end

local function valid(value)
    if value == nil then
        return false
    end

    if not IsValid then
        return true
    end

    local ok, result = pcall(IsValid, value)
    return ok and result == true
end

local function weaponTable(swep)
    if swep and swep.GetTable then
        local ok, value = pcall(swep.GetTable, swep)

        if ok and type(value) == "table" then
            return value
        end
    end

    return type(swep) == "table" and swep or nil
end

local function storedWeapon(className)
    if type(className) ~= "string" or className == ""
        or type(weapons) ~= "table" then
        return nil
    end

    for _, methodName in ipairs({"GetStored", "Get"}) do
        local method = weapons[methodName]

        if type(method) == "function" then
            local ok, value = pcall(method, className)

            if not ok then
                ok, value = pcall(method, weapons, className)
            end

            if ok and type(value) == "table" then
                return value
            end
        end
    end

    return nil
end

local function classChain(className)
    local result = {}
    local seen = {}
    local current = className

    while type(current) == "string" and current ~= "" and not seen[current] do
        seen[current] = true
        local definition = storedWeapon(current)

        if not definition then
            break
        end

        result[#result + 1] = definition
        current = definition.Base

        if current == "weapon_base" then
            break
        end
    end

    return result
end

local function effectiveIR(swep, base)
    local runtime = swep and swep.FTRuntime

    if not runtime then
        return nil
    end

    if base then
        return runtime.ir
    end

    if FTBase.Runtime.Attachments and FTBase.Runtime.Attachments.GetEffectiveIR then
        return FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir
    end

    return runtime.effectiveIR or runtime.ir
end

local function rangeValues(ir)
    local ballistics = ir and ir.ballistics
    local curve = type(ballistics) == "table" and ballistics.damageCurve or {}

    if type(curve) ~= "table" then
        curve = {}
    end

    return tonumber(curve.minRange) or 0, tonumber(curve.maxRange or curve.range) or 0
end

local function statValue(ir, key)
    if not ir then
        return nil
    end

    local normalized = normalize(key):gsub("[%s%-]", ""):gsub("_", "")
    local minRange, maxRange = rangeValues(ir)
    local damage = type(ir.damage) == "table" and ir.damage or {}
    local ballistics = type(ir.ballistics) == "table" and ir.ballistics or {}
    local fire = type(ir.fire) == "table" and ir.fire or {}
    local ammo = type(ir.ammo) == "table" and ir.ammo or {}
    local spread = type(ir.spread) == "table" and ir.spread or {}
    local recoil = type(ir.recoil) == "table" and ir.recoil or {}
    local procedural = type(recoil.procedural) == "table" and recoil.procedural or {}
    local movement = type(ir.movement) == "table" and ir.movement or {}
    local meta = type(ir.meta) == "table" and ir.meta or {}
    local mapping = {
        ["primary.damage"] = damage.base,
        ["damage"] = damage.base,
        ["damagemax"] = damage.base,
        ["primary.damagemax"] = damage.base,
        ["damagemin"] = damage.minimum,
        ["primary.damagemin"] = damage.minimum,
        ["primary.numshots"] = ballistics.pellets,
        ["num"] = ballistics.pellets,
        ["primary.rpm"] = fire.rpm,
        ["primary.rpmdisplayed"] = fire.rpm,
        ["rpm"] = fire.rpm,
        ["delay"] = fire.delay or (fire.rpm and 60 / fire.rpm),
        ["firingdelay"] = fire.delay or (fire.rpm and 60 / fire.rpm),
        ["primary.clipsize"] = ammo.clipSize,
        ["clipsize"] = ammo.clipSize,
        ["capacity"] = ammo.clipSize,
        ["primary.ammo"] = ammo.type,
        ["ammotype"] = ammo.type,
        ["primary.spread"] = spread.hip,
        ["spread"] = spread.hip,
        ["primary.ironaccuracy"] = spread.ads,
        ["accuracy"] = spread.ads,
        ["primary.kickup"] = procedural.vertical,
        ["primary.kickdown"] = 0,
        ["primary.kickhorizontal"] = procedural.horizontal,
        ["recoil"] = procedural.vertical,
        ["recoilup"] = procedural.vertical,
        ["recoilside"] = procedural.horizontal,
        ["regularmovespeedmultiplier"] = movement.speed,
        ["sightspeed"] = movement.sightedSpeed,
        ["rangemin"] = minRange,
        ["rangemax"] = maxRange,
        ["range"] = maxRange,
        ["muzzlevelocity"] = ballistics.muzzleVelocity,
        ["secondary.ironsightsenabled"] = true,
        ["secondary.displayspread"] = true,
        ["primary.displayfalloff"] = true,
        ["type"] = meta.subCategory ~= "" and meta.subCategory or meta.category,
        ["typedisplayed"] = meta.subCategory ~= "" and meta.subCategory or meta.category,
        ["printname"] = meta.printName,
        ["fullname"] = meta.printName
    }

    return mapping[normalized]
end

local function rawPath(value, path)
    if type(path) ~= "string" or path == "" then
        return nil
    end

    local current = value

    for part in string.gmatch(path, "[^%.]+") do
        if current == nil then
            return nil
        end

        local ok, nextValue = pcall(function()
            return current[part]
        end)

        if not ok then
            return nil
        end

        current = nextValue
    end

    return current
end

local function stateFor(swep)
    return swep and States[swep] or nil
end

local function routedStateFor(swep)
    return swep and (TemporaryStates[swep] or States[swep]) or nil
end

-- Vendor customize panels occasionally send their own attachment, preset or
-- inventory messages directly from a VGUI callback.  F&T already translates
-- supported attachment actions into its own request path, so suppress those
-- vendor transactions while a bridge is open.  The wrapper is installed only
-- for an active bridge and is restored afterwards.
local NetGuard = {
    originals = {},
    wrappers = {},
    states = setmetatable({}, {__mode = "k"})
}

local function activeBridgeState()
    if not LocalPlayer then
        return nil
    end

    local player = LocalPlayer()
    local swep = player and player.GetActiveWeapon and player:GetActiveWeapon()
    local state = routedStateFor(swep)
    -- Keep the guard active while an explicit close is running.  Vendor panel
    -- teardown hooks commonly emit their own net message from OnRemove; that
    -- transaction must remain suppressed until all cleanup has completed.
    return state and (state.open or state.closing or state.netGuard) and state or nil
end

local function messageBlocked(state, name)
    if not state then
        return false
    end

    local wanted = normalize(name)

    local function matches(candidateState)
        for _, candidate in ipairs(candidateState and candidateState.bridge.blockNetMessages or {}) do
            if normalize(candidate) == wanted then
                return true
            end
        end

        return false
    end

    return matches(state) or matches(state.fallbackState)
end

local function installVendorNetGuard(state)
    if not CLIENT or type(net) ~= "table" or type(net.Start) ~= "function" then
        return
    end

    NetGuard.states[state] = true

    if NetGuard.installed then
        return
    end

    NetGuard.installed = true
    NetGuard.originals.Start = net.Start
    NetGuard.wrappers.Start = function(name, ...)
        -- A completed/abandoned suppressed transaction cannot leak into the
        -- next net.Start call.
        NetGuard.suppressed = nil
        local stateForMessage = activeBridgeState()

        if messageBlocked(stateForMessage, name) then
            NetGuard.suppressed = stateForMessage
            return false
        end

        return NetGuard.originals.Start(name, ...)
    end
    net.Start = NetGuard.wrappers.Start

    local writeMethods = {
        "WriteAngle",
        "WriteBit",
        "WriteBool",
        "WriteColor",
        "WriteData",
        "WriteDouble",
        "WriteEntity",
        "WriteFloat",
        "WriteInt",
        "WriteMatrix",
        "WriteNormal",
        "WriteString",
        "WriteTable",
        "WriteType",
        "WriteUInt",
        "WriteVector"
    }

    for _, methodName in ipairs(writeMethods) do
        if type(net[methodName]) == "function" then
            local name = methodName
            NetGuard.originals[name] = net[name]
            NetGuard.wrappers[name] = function(...)
                if NetGuard.suppressed then
                    return
                end

                return NetGuard.originals[name](...)
            end
            net[name] = NetGuard.wrappers[name]
        end
    end

    local sendMethods = {
        "Broadcast",
        "Send",
        "SendPAS",
        "SendPVS",
        "SendToServer"
    }

    for _, methodName in ipairs(sendMethods) do
        if type(net[methodName]) == "function" then
            local name = methodName
            NetGuard.originals[name] = net[name]
            NetGuard.wrappers[name] = function(...)
                if NetGuard.suppressed then
                    NetGuard.suppressed = nil
                    return
                end

                return NetGuard.originals[name](...)
            end
            net[name] = NetGuard.wrappers[name]
        end
    end
end

local function restoreVendorNetGuard(state)
    if not NetGuard.installed then
        return
    end

    NetGuard.states[state] = nil

    if NetGuard.suppressed == state then
        NetGuard.suppressed = nil
    end

    for _ in pairs(NetGuard.states) do
        return
    end

    for methodName, original in pairs(NetGuard.originals) do
        if net[methodName] == NetGuard.wrappers[methodName] then
            net[methodName] = original
        end
    end

    NetGuard.originals = {}
    NetGuard.wrappers = {}
    NetGuard.installed = false
end

-- Weapon overlays use the same stack semantics as globals.  This matters for
-- mixed profiles where (for example) an MW customization surface can remain
-- open while a TFA HUD is rendered through a temporary state each frame.
local OverlayScopes = setmetatable({}, {__mode = "k"})

local function saveAndSet(state, key, value)
    local target = state.swep
    local raw = weaponTable(target)

    if not raw then
        return false
    end

    if state.saved[key] == nil then
        local scopes = OverlayScopes[raw]

        if not scopes then
            scopes = {}
            OverlayScopes[raw] = scopes
        end

        local scope = scopes[key]

        if not scope then
            scope = {
                basePresent = rawget(raw, key) ~= nil,
                baseValue = rawget(raw, key),
                baseTarget = target,
                stack = {}
            }
            scopes[key] = scope
        end

        state.saved[key] = {
            present = rawget(raw, key) ~= nil,
            value = rawget(raw, key),
            raw = raw,
            scope = scope,
            target = target
        }

        scope.stack[#scope.stack + 1] = state.saved[key]
        state.savedOrder[#state.savedOrder + 1] = key
    end

    target[key] = value

    -- Keep the value written by this state alongside the value it displaced.
    -- When a temporary mixed-domain HUD state unwinds, the surviving state must
    -- be restored to its own overlay rather than to that overlay's old base
    -- value.
    local saved = state.saved[key]
    if saved then
        saved.appliedPresent = value ~= nil
        saved.appliedValue = value
    end

    return true
end

local function restoreOverlay(state)
    if not state or state.restored then
        return
    end

    state.restored = true
    local target = state.swep

    for index = #state.savedOrder, 1, -1 do
        local key = state.savedOrder[index]
        local saved = state.saved[key]

        local scope = saved.scope

        if scope and scope.stack then
            local removedIndex

            for stackIndex = #scope.stack, 1, -1 do
                if scope.stack[stackIndex] == saved then
                    removedIndex = stackIndex
                    table.remove(scope.stack, stackIndex)
                    break
                end
            end

            if removedIndex == #scope.stack + 1 then
                if #scope.stack > 0 then
                    local previous = scope.stack[#scope.stack]
                    if previous.appliedPresent ~= nil then
                        if previous.appliedPresent then
                            previous.target[key] = previous.appliedValue
                        else
                            previous.target[key] = nil
                        end
                    elseif previous.present then
                        -- Compatibility with state entries created before
                        -- applied overlay values were recorded.
                        previous.target[key] = previous.value
                    else
                        previous.target[key] = nil
                    end
                else
                    local baseTarget = scope.baseTarget or target

                    if scope.basePresent then
                        baseTarget[key] = scope.baseValue
                    else
                        baseTarget[key] = nil
                    end
                end
            end

            if #scope.stack == 0 then
                local scopes = OverlayScopes[saved.raw]
                if scopes then
                    scopes[key] = nil
                end
            end
        elseif saved.present then
            target[key] = saved.value
        else
            target[key] = nil
        end
    end
end

-- Process-wide fields need stack semantics because more than one bridge can
-- temporarily overlay the same vendor global.  Weak table keys avoid keeping
-- addon-owned tables alive after their realm is reloaded.
local GlobalScopes = setmetatable({}, {__mode = "k"})

local function saveGlobal(state, target, key)
    if type(target) ~= "table" or type(key) ~= "string" or key == "" then
        return
    end

    state.savedGlobals = state.savedGlobals or {}

    for _, entry in ipairs(state.savedGlobals) do
        if entry.target == target and entry.key == key then
            return
        end
    end

    -- Globals such as ArcCW.InvHUD and MW_CUSTOMIZEMENU are process-wide and
    -- can be overlaid by more than one bridge at a time.  Keep a per-key stack
    -- so closing an older state cannot restore over a newer active state.
    local scopes = GlobalScopes[target]

    if not scopes then
        scopes = {}
        GlobalScopes[target] = scopes
    end

    local scope = scopes[key]

    if not scope then
        scope = {
            basePresent = rawget(target, key) ~= nil,
            baseValue = rawget(target, key),
            baseTarget = target,
            stack = {}
        }
        scopes[key] = scope
    end

    local entry = {
        key = key,
        present = rawget(target, key) ~= nil,
        target = target,
        value = rawget(target, key),
        appliedPresent = rawget(target, key) ~= nil,
        appliedValue = rawget(target, key),
        scope = scope
    }

    scope.stack[#scope.stack + 1] = entry
    state.savedGlobals[#state.savedGlobals + 1] = entry
end

local function setGlobal(state, target, key, value)
    saveGlobal(state, target, key)

    if type(target) ~= "table" or type(key) ~= "string" or key == "" then
        return false
    end

    target[key] = value

    for _, entry in ipairs(state.savedGlobals or {}) do
        if entry.target == target and entry.key == key then
            entry.appliedPresent = value ~= nil
            entry.appliedValue = value
            break
        end
    end

    return true
end

local function captureGlobalOverlays(state)
    for _, entry in ipairs(state and state.savedGlobals or {}) do
        if entry.target then
            local value = rawget(entry.target, entry.key)
            entry.appliedPresent = value ~= nil
            entry.appliedValue = value
        end
    end
end

local function restoreGlobals(state)
    if not state or state.globalsRestored then
        return
    end

    state.globalsRestored = true

    for index = #(state.savedGlobals or {}), 1, -1 do
        local entry = state.savedGlobals[index]
        local scope = entry.scope

        if scope and scope.stack then
            local removedIndex

            for stackIndex = #scope.stack, 1, -1 do
                if scope.stack[stackIndex] == entry then
                    removedIndex = stackIndex
                    table.remove(scope.stack, stackIndex)
                    break
                end
            end

            -- Only the top overlay may restore immediately.  If an older
            -- state closes first, leave the newest active bridge untouched.
            if removedIndex == #scope.stack + 1 then
                if #scope.stack > 0 then
                    local previous = scope.stack[#scope.stack]
                    if previous.appliedPresent ~= nil then
                        if previous.appliedPresent then
                            entry.target[entry.key] = previous.appliedValue
                        else
                            entry.target[entry.key] = nil
                        end
                    elseif previous.present then
                        -- Compatibility with entries created before applied
                        -- overlay values were recorded.
                        entry.target[entry.key] = previous.value
                    else
                        entry.target[entry.key] = nil
                    end
                else
                    local baseTarget = scope.baseTarget or entry.target

                    if scope.basePresent then
                        baseTarget[entry.key] = scope.baseValue
                    else
                        baseTarget[entry.key] = nil
                    end
                end
            end

            if #scope.stack == 0 then
                local scopes = GlobalScopes[entry.target]
                if scopes then
                    scopes[entry.key] = nil
                end
            end
        elseif entry.present then
            -- Compatibility path for states created before stack metadata was
            -- introduced (for example after a hot reload).
            entry.target[entry.key] = entry.value
        else
            entry.target[entry.key] = nil
        end
    end
end

local function saveBridgeState(state)
    for _, key in ipairs(state.bridge.stateFields or {}) do
        saveAndSet(state, key, state.swep[key])
    end

    for _, spec in ipairs(state.bridge.globalFields or {}) do
        local target = spec.target == "_G" and _G or rawget(_G, spec.target)
        saveGlobal(state, target, spec.key)
    end
end

local function vendorMember(chain, key)
    local value = nil

    -- `classChain` is sample -> base.  Read base members first so the sample
    -- class wins exactly like a normal SWEP lookup, without copying either
    -- table to the F&T entity.
    for index = #chain, 1, -1 do
        local candidate = rawget(chain[index], key)

        if candidate ~= nil then
            value = candidate
        end
    end

    return value
end

local function collectVendorData(state)
    local bridge = state.bridge
    local chain = classChain(bridge.sampleClass or bridge.baseClass)
    local allowedMethods = asSet(bridge.uiMethods)
    local overlayMethods = asSet(bridge.overlayMethods)
    local allowedFields = asSet(bridge.uiFields)
    local seen = {}

    state.vendorMethods = {}
    state.vendorFields = {}

    -- Never enumerate a vendor table.  Apart from making behaviour depend on
    -- an external base version, enumeration used to copy gameplay callbacks
    -- such as Think/Reload/PrimaryAttack into a live F&T weapon.
    for _, key in ipairs(bridge.uiMethods or {}) do
        key = tostring(key)

        if not seen[key] and allowedMethods[key] then
            seen[key] = true
            local value = vendorMember(chain, key)

            if type(value) == "function" then
                state.vendorMethods[key] = value

                if overlayMethods[key] then
                    -- Route nested vendor UI calls through the same guarded
                    -- entry point.  This keeps transient markers scoped and
                    -- prevents a helper from becoming a permanent SWEP hook.
                    saveAndSet(state, key, function(_, ...)
                        local ok, result = callVendor(state, key, ...)
                        return ok and result or nil
                    end)
                end
            end
        end
    end

    seen = {}

    for _, key in ipairs(bridge.uiFields or {}) do
        key = tostring(key)

        if not seen[key] and allowedFields[key] then
            seen[key] = true
            local value = vendorMember(chain, key)

            if value ~= nil and type(value) ~= "function" then
                state.vendorFields[key] = copyUIData(value)
                saveAndSet(state, key, state.vendorFields[key])
            end
        end
    end
end

local function attachmentSlots(runtime)
    local attachments = runtime and runtime.attachments
    local slots = attachments and attachments.slots

    return type(slots) == "table" and slots or {}
end

local function slotById(runtime, slotId)
    for _, slot in ipairs(attachmentSlots(runtime)) do
        if tostring(slot.id) == tostring(slotId) then
            return slot
        end
    end

    return nil
end

local function installedAttachments(runtime)
    local attachments = runtime and runtime.attachments
    local installed = attachments and attachments.installed

    return type(installed) == "table" and installed or {}
end

local function canInstall(runtime, slotId, attachmentId)
    local attachments = FTBase.Runtime and FTBase.Runtime.Attachments

    if type(attachments) ~= "table"
        or type(attachments.CanInstall) ~= "function"
        or not runtime then
        return false
    end

    local ok, allowed = pcall(attachments.CanInstall, runtime, slotId, attachmentId)
    return ok and allowed == true
end

local function resolveSlotId(state, vendorSlot, attachmentId)
    local runtime = state.swep.FTRuntime
    local mapped = state.vendorSlotToFT[tostring(vendorSlot)]

    if mapped and slotById(runtime, mapped) then
        return mapped
    end

    if type(vendorSlot) == "table" then
        mapped = state.vendorSlotToFT[tostring(vendorSlot.Address or vendorSlot.address or vendorSlot.id)]

        if mapped then
            return mapped
        end
    end

    if slotById(runtime, vendorSlot) then
        return tostring(vendorSlot)
    end

    if attachmentId and attachmentId ~= "" then
        for _, slot in ipairs(attachmentSlots(runtime)) do
            local allowed = canInstall(runtime, slot.id, attachmentId)

            if allowed then
                return slot.id
            end
        end
    end

    return nil
end

local function attachmentIdFor(state, vendorAttachment)
    if type(vendorAttachment) == "table" then
        vendorAttachment = vendorAttachment.ClassName or vendorAttachment.ShortName
            or vendorAttachment.id or vendorAttachment.ID
    end

    local id = tostring(vendorAttachment or "")
    return state.syntheticToFT[id] or id
end

local function requestAttachment(state, vendorSlot, vendorAttachment)
    local attachmentId = attachmentIdFor(state, vendorAttachment)
    local slotId = resolveSlotId(state, vendorSlot, attachmentId ~= "" and attachmentId or nil)

    if not slotId or not FTBase.Runtime.Networking
        or not FTBase.Runtime.Networking.RequestAttachment then
        return false
    end

    if attachmentId ~= "" then
        local allowed = canInstall(state.swep.FTRuntime, slotId, attachmentId)

        if not allowed then
            return false
        end
    end

    return FTBase.Runtime.Networking.RequestAttachment(state.swep, slotId, attachmentId)
end

local function iconMaterial(definition, fallback)
    local icon = definition and (definition.iconMaterial or definition.icon) or nil

    if type(icon) == "string" and Material then
        return Material(icon, "smooth mips")
    end

    if icon ~= nil then
        return icon
    end

    if fallback and Material then
        return Material(fallback, "smooth mips")
    end

    return icon
end

local function cleanupSynthetic(state)
    for index = #state.registryEntries, 1, -1 do
        local entry = state.registryEntries[index]

        if entry.table then
            if entry.present then
                entry.table[entry.id] = entry.value
            else
                entry.table[entry.id] = nil
            end
        end
    end

    state.registryEntries = {}
    state.syntheticToFT = {}
    state.ftToSynthetic = {}
    state.vendorSlotToFT = {}
end

local function registerSynthetic(state, registry, id, value, attachmentId)
    if type(registry) ~= "table" then
        return false
    end

    state.registryEntries[#state.registryEntries + 1] = {
        table = registry,
        id = id,
        present = registry[id] ~= nil,
        value = registry[id]
    }
    registry[id] = value
    state.syntheticToFT[id] = attachmentId
    state.ftToSynthetic[attachmentId] = id
    return true
end

local function providerOptions(runtime, slotId)
    local provider = FTBase.Runtime.ProviderHost
        and FTBase.Runtime.ProviderHost.GetProvider(runtime, "attachments")

    if provider and provider.GetOptions then
        local options = provider:GetOptions(runtime, slotId)
        return type(options) == "table" and options or {}
    end

    return {}
end

local function syntheticToken(swep)
    local index = swep and swep.EntIndex and swep:EntIndex() or tostring(swep)
    return "ft_ui_" .. tostring(index):gsub("[^%w_]", "_")
end

local function buildSynthetic(state)
    cleanupSynthetic(state)
    local bridge = state.bridge
    local runtime = state.swep.FTRuntime
    local registry = bridge.GetRegistry and bridge.GetRegistry() or nil
    local slots = {}
    local token = syntheticToken(state.swep)

    for index, slot in ipairs(attachmentSlots(runtime)) do
        local category = token .. "_slot_" .. tostring(index)
        local installed = installedAttachments(runtime)[slot.id]
        local projection = {
            category = category,
            index = index,
            installed = installed,
            name = tostring(slot.name or slot.id or ("Slot " .. index)),
            options = {},
            slot = slot,
            slotId = slot.id
        }

        state.vendorSlotToFT[tostring(index)] = slot.id
        state.vendorSlotToFT[tostring(slot.id)] = slot.id

        for optionIndex, option in ipairs(providerOptions(runtime, slot.id)) do
            local irAttachments = runtime and runtime.ir and runtime.ir.attachments or {}
            local definitions = type(irAttachments.definitions) == "table"
                and irAttachments.definitions or {}
            local definition = option.definition or definitions[option.id] or {}
            local syntheticId = token .. "_att_" .. tostring(index) .. "_" .. tostring(optionIndex)
            local vendorDefinition = bridge.BuildDefinition(
                state,
                projection,
                option,
                definition,
                syntheticId
            )

            if registerSynthetic(state, registry, syntheticId, vendorDefinition, option.id) then
                projection.options[#projection.options + 1] = {
                    id = syntheticId,
                    attachmentId = option.id,
                    definition = vendorDefinition
                }
            end
        end

        if installed and not state.ftToSynthetic[installed] then
            local irAttachments = runtime and runtime.ir and runtime.ir.attachments or {}
            local definitions = type(irAttachments.definitions) == "table"
                and irAttachments.definitions or {}
            local definition = definitions[installed] or {}
            local syntheticId = token .. "_installed_" .. tostring(index)
            local option = {
                id = installed,
                name = definition.name or installed,
                description = definition.description or "",
                definition = definition
            }
            local vendorDefinition = bridge.BuildDefinition(
                state,
                projection,
                option,
                definition,
                syntheticId
            )

            registerSynthetic(state, registry, syntheticId, vendorDefinition, installed)
        end

        slots[#slots + 1] = projection
    end

    state.projectedSlots = slots
    bridge.ApplySlots(state, slots)
end

local function commonOverrides(state)
    local swep = state.swep

    local function slotAddress(value)
        if type(value) ~= "table" then
            return value
        end

        if value.Address ~= nil then
            return value.Address
        end

        if value.address ~= nil then
            return value.address
        end

        if value.slotId ~= nil then
            return value.slotId
        end

        if value.id ~= nil then
            return value.id
        end

        if value.index ~= nil then
            return value.index
        end

        local nested = value.slot

        if type(nested) == "table" then
            return nested.id or nested.slotId or nested.Address or nested.address
        end

        return nil
    end

    local function projectionFor(address)
        local requested = slotAddress(address)
        local numeric = tonumber(requested)

        for _, entry in ipairs(state.projectedSlots or {}) do
            if address == entry
                or tostring(entry.index) == tostring(requested)
                or tostring(entry.slotId) == tostring(requested) then
                return entry
            end
        end

        if numeric and state.projectedSlots and state.projectedSlots[numeric] then
            return state.projectedSlots[numeric]
        end

        return nil
    end

    local function projectedSlot(address)
        local projection = projectionFor(address)
        local numeric = tonumber(slotAddress(address))
        local attachments = type(swep.Attachments) == "table"
            and swep.Attachments or nil

        if projection and numeric and attachments and attachments[numeric] then
            return attachments[numeric]
        end

        if projection then
            return projection
        end

        return numeric and attachments and attachments[numeric] or nil
    end

    local function normalizedSlot(address)
        local projection = projectionFor(address)
        local result = projectedSlot(address)

        if type(result) ~= "table" then
            result = {}
        end

        local source = projection and projection.slot
            or (type(result.slot) == "table" and result.slot)
            or result
        local index = result.Address or result.address
            or (projection and projection.index)
            or tonumber(slotAddress(address))
            or slotAddress(address)
        local installed = result.Installed

        if installed == nil and projection then
            installed = projection.installed
        end

        if installed ~= nil then
            installed = state.ftToSynthetic[installed] or installed
        end

        result.Address = index
        result.OriginalAddress = result.OriginalAddress or index
        result.Bone = result.Bone or source.bone or source.Bone or "__ft"
        result.Category = result.Category or source.category or source.Category
            or source.type or ""
        result.Installed = installed
        result.Pos = safeVector(result.Pos or result.pos or source.pos or source.position)
        result.Ang = safeAngle(result.Ang or result.ang or source.ang or source.angle)
        result.Icon_Offset = safeVector(
            result.Icon_Offset or result.IconOffset or result.icon_offset
                or source.iconOffset or source.icon_offset or source.Icon_Offset
        )
        result.PrintName = result.PrintName or source.name or source.PrintName
            or source.id or ("Slot " .. tostring(index or ""))
        result.Scale = tonumber(result.Scale or result.scale or source.scale) or 1

        return result
    end

    local function getIR(base)
        return effectiveIR(swep, base)
    end

    local function getValue(key, default, base)
        local value = statValue(getIR(base), key)

        if value == nil then
            value = rawPath(swep, key)
        end

        if value == nil then
            value = default
        end

        return value
    end

    local function activeSightSlot()
        for _, entry in ipairs(state.projectedSlots or {}) do
            local source = entry.slot or entry
            local kind = normalize(source.type or source.category or source.id)

            if string.find(kind, "optic", 1, true)
                or string.find(kind, "sight", 1, true)
                or string.find(kind, "scope", 1, true) then
                return normalizedSlot(entry.index)
            end
        end

        return normalizedSlot(1)
    end

    local overrides = {
        OwnerIsValid = function(self)
            return valid(self.GetOwner and self:GetOwner())
        end,
        GetCustomizing = function()
            return state.open
        end,
        GetCustomize = function()
            return state.open
        end,
        GetInspectingProgress = function()
            return state.open and 1 or 0
        end,
        SetCustomize = function(_, enabled)
            if enabled == false then
                return UIBridge.Close(swep)
            end

            return true
        end,
        ToggleCustomize = function(_, enabled)
            if enabled == nil then
                enabled = not state.open
            end

            if enabled then
                return UIBridge.Open(swep, "attachments")
            end

            return UIBridge.Close(swep)
        end,
        ToggleCustomizeHUD = function(_, enabled)
            if enabled == false then
                return UIBridge.Close(swep)
            end

            return true
        end,
        GetPriorityAnim = function()
            return false
        end,
        GetReloading = function()
            return swep.FTRuntime and swep.FTRuntime.reloading or false
        end,
        -- Presentation-only status accessors used by the vendor HUDs.  They
        -- intentionally read F&T runtime state instead of a vendor datatable.
        GetStatus = function()
            local runtime = swep.FTRuntime or {}
            local enum = rawget(_G, "TFA") and rawget(_G, "TFA").Enum or {}

            if runtime.reloading then
                return enum.STATUS_RELOADING or 0
            elseif runtime.aiming then
                return enum.STATUS_IRONSIGHTS or 0
            end

            return enum.STATUS_IDLE or 0
        end,
        GetStatusProgress = function()
            return swep.FTRuntime and swep.FTRuntime.aimFraction or 0
        end,
        GetHidden = function()
            return false
        end,
        IsJammed = function()
            return false
        end,
        Ammo1 = function()
            local owner = swep.GetOwner and swep:GetOwner()
            local ir = getIR()

            if owner and owner.GetAmmoCount and ir and ir.ammo then
                return owner:GetAmmoCount(ir.ammo.type or "")
            end

            return 0
        end,
        GetMuzzlePos = function()
            return nil
        end,
        GetTFAAttachment = function(_, category)
            local slotId = resolveSlotId(state, category)
            local installed = slotId and installedAttachments(swep.FTRuntime)[slotId]
            return installed and state.ftToSynthetic[installed] or nil
        end,
        GetPrimaryAmmoType = function()
            local ir = getIR()
            return ir and ir.ammo and ir.ammo.type or ""
        end,
        GetMaxClip1 = function()
            return getValue("ClipSize", 0)
        end,
        GetState = function()
            return state.open and (state.bridge.customizeState or 4) or 0
        end,
        SetState = function()
            return false
        end,
        HasFlag = function(_, flag)
            local name = normalize(flag)

            if name == "customizing" then
                return state.open
            elseif name == "reloading" then
                return swep.FTRuntime and swep.FTRuntime.reloading or false
            elseif name == "aiming" then
                return swep.FTRuntime and swep.FTRuntime.aiming or false
            end

            return false
        end,
        GetStatL = function(_, key, default)
            return getValue(key, default)
        end,
        GetStat = function(_, key, default)
            return getValue(key, default)
        end,
        GetStatRawL = function(_, key, default)
            return getValue(key, default, true)
        end,
        GetValue = function(_, key, _, invert)
            local value = getValue(key, 0)

            if invert and type(value) == "number" and value ~= 0 then
                return 1 / value
            end

            return value
        end,
        GetBaseValue = function(_, key)
            return getValue(key, 0, true)
        end,
        GetProcessedValue = function(_, key)
            return getValue(key, 0)
        end,
        GetBuff = function(_, key, defaultNil, defaultValue)
            local value = getValue(key, nil)

            if value ~= nil then
                return value
            end

            return defaultNil and nil or defaultValue
        end,
        GetBuff_Stat = function(_, key)
            return getValue(key, 0)
        end,
        GetBuff_Override = function(_, key, default)
            key = tostring(key or ""):gsub("^Override_", "")
            return getValue(key, default)
        end,
        GetBuff_Mult = function()
            return 1
        end,
        GetBuff_Add = function()
            return 0
        end,
        GetBuff_Hook = function(_, _, data)
            return data
        end,
        RunHook = function()
            return nil
        end,
        GetType = function()
            return getValue("Type", "Weapon")
        end,
        GetAmmoType = function()
            return getValue("AmmoType", "")
        end,
        CanChamber = function()
            local ir = getIR()
            return ir and ir.ammo and (ir.ammo.chamberSize or 0) > 0 or false
        end,
        CanBeJammed = function()
            return false
        end,
        GetJamFactor = function()
            return 0
        end,
        GetJammed = function()
            return false
        end,
        GetSafe = function()
            return false
        end,
        GetSightAmount = function()
            return swep.FTRuntime and swep.FTRuntime.aimFraction or 0
        end,
        GetIronSightsProgress = function()
            return swep.FTRuntime and swep.FTRuntime.aimFraction or 0
        end,
        GetAimDelta = function()
            return swep.FTRuntime and swep.FTRuntime.aimFraction or 0
        end,
        GetTacStanceDelta = function()
            return 0
        end,
        GetSprintAmount = function()
            return swep.FTRuntime and swep.FTRuntime.sprintFraction or 0
        end,
        GetSprintProgress = function()
            return swep.FTRuntime and swep.FTRuntime.sprintFraction or 0
        end,
        GetRecoilAmount = function()
            return 0
        end,
        GetScopeLevel = function()
            return 0
        end,
        GetBreath = function()
            return 1
        end,
        GetOutOfBreath = function()
            return false
        end,
        GetTactical = function()
            return false
        end,
        GetFiremode = function()
            return 1
        end,
        GetFireMode = function()
            local ir = getIR()
            return ir and ir.fire and ir.fire.automatic and 2 or 1
        end,
        GetFireModeName = function()
            local ir = getIR()
            return ir and ir.fire and ir.fire.automatic and "AUTO" or "SEMI"
        end,
        GetFiremodeName = function()
            local ir = getIR()
            return ir and ir.fire and ir.fire.automatic and "AUTO" or "SEMI"
        end,
        GetFiremodeBars = function()
            return 1
        end,
        GetCapacity = function()
            return getValue("ClipSize", 0)
        end,
        GetHUDData = function()
            local runtime = swep.FTRuntime or {}
            local ir = getIR() or {}
            local owner = swep.GetOwner and swep:GetOwner()
            local reserve = owner and owner.GetAmmoCount and owner:GetAmmoCount(
                ir.ammo and ir.ammo.type or "") or 0

            return {
                ammo = reserve,
                ammo2 = 0,
                clip = swep.Clip1 and swep:Clip1() or 0,
                clip2 = swep.Clip2 and swep:Clip2() or 0,
                heat_level = 0,
                mode = runtime.aiming and "ADS" or (ir.fire and ir.fire.automatic and "AUTO" or "SEMI"),
                plus = "0",
                plus2 = "0"
            }
        end,
        GetCurrentFiremode = function()
            local ir = getIR() or {}
            return {Mode = ir.fire and ir.fire.automatic and 2 or 1}
        end,
        GetIsManualAction = function()
            return false
        end,
        GetInUBGL = function()
            return false
        end,
        -- ARC9 HUD and animation helpers expect these accessors even for
        -- weapons that do not expose an under-barrel launcher.  Keep the
        -- values derived from the F&T IR and never delegate to vendor
        -- attachment/gameplay state.
        GetUBGL = function()
            return false
        end,
        GetMaxClip2 = function()
            return 0
        end,
        GetInBipod = function()
            return false
        end,
        CanBipod = function()
            return false
        end,
        WidescreenFix = function()
            return 1
        end,
        GetViewModelFOV = function()
            local ir = getIR()
            return ir and ir.rendering and ir.rendering.viewModelFOV or 60
        end,
        GetFiringDelay = function()
            return getValue("FiringDelay", 0.1)
        end,
        GetDamage = function(_, range)
            local ir = getIR()

            if FTBase.Runtime.Ballistics and FTBase.Runtime.Ballistics.DamageAtDistance then
                return FTBase.Runtime.Ballistics.DamageAtDistance(ir, range or 0)
            end

            return ir and ir.damage and ir.damage.base or 0
        end,
        GetDamageAtRange = function(_, range)
            local ir = getIR()

            if FTBase.Runtime.Ballistics and FTBase.Runtime.Ballistics.DamageAtDistance then
                return FTBase.Runtime.Ballistics.DamageAtDistance(ir, range or 0)
            end

            return ir and ir.damage and ir.damage.base or 0
        end,
        GetMinMaxRange = function()
            return rangeValues(getIR())
        end,
        GetMuzzleVelocity = function()
            return getValue("MuzzleVelocity", 0)
        end,
        GetSpread = function()
            return getValue("Spread", 0)
        end,
        GetConfigDamageMultiplier = function()
            return 1
        end,
        GetBodyDamageMultipliers = function()
            local multipliers = {}
            multipliers[HITGROUP_HEAD or 1] = 1
            multipliers[HITGROUP_CHEST or 2] = 1
            multipliers[HITGROUP_STOMACH or 3] = 1
            multipliers[HITGROUP_LEFTARM or 4] = 1
            multipliers[HITGROUP_RIGHTARM or 5] = 1
            multipliers[HITGROUP_LEFTLEG or 6] = 1
            multipliers[HITGROUP_RIGHTLEG or 7] = 1
            return multipliers
        end,
        RangeUnitize = function(_, range)
            return tostring(math.Round and math.Round(range or 0) or math.floor(range or 0)) .. "m"
        end,
        Curve = function(_, value)
            return value
        end,
        SavePreset = function()
            return false
        end,
        LoadPreset = function()
            return false
        end,
        GetPresets = function()
            return {}
        end,
        GetPresetBase = function()
            -- ARC9 concatenates this value into a DATA path while building
            -- its preset panel.  Keep the path deterministic and scoped to
            -- this F&T entity; never expose the vendor class/save namespace.
            return syntheticToken(swep)
        end,
        CreatePresetSave = function()
            return false
        end,
        ShowInventoryButton = function()
            return false
        end,
        BuildCustomizedGun = function()
            return false
        end,
        DoScope = function() end,
        HasInfiniteAmmo = function()
            return false
        end,
        HasBottomlessClip = function()
            return false
        end,
        HeatEnabled = function()
            return false
        end,
        GetHeat = function()
            return 0
        end,
        GetMaxHeat = function()
            return 1
        end,
        GetHeatLocked = function()
            return false
        end,
        CheckFlags = function()
            return true
        end,
        IsAttachmentAllowed = function()
            return true
        end,
        GetBlockerAttachment = function()
            return nil
        end,
        HasAttachment = function(_, attachment)
            local id = attachmentIdFor(state, attachment)

            for _, installed in pairs(installedAttachments(swep.FTRuntime)) do
                if installed == id then
                    return true
                end
            end

            return false
        end,
        Attach = function(_, slot, attachment)
            return requestAttachment(state, slot, attachment)
        end,
        Detach = function(_, slot)
            return requestAttachment(state, slot, "")
        end,
        DetachAllMergeSlots = function(_, slot)
            return requestAttachment(state, slot, "")
        end,
        DetachAllFromSubSlot = function(_, slot)
            return requestAttachment(state, slot, "")
        end,
        CanDetach = function(_, slot)
            local slotId = resolveSlotId(state, slot)
            return slotId and installedAttachments(swep.FTRuntime)[slotId] ~= nil or false
        end,
        CanAttach = function(_, slot, attachment)
            if attachment == nil then
                attachment = slot
                slot = nil
            end

            local attachmentId = attachmentIdFor(state, attachment)
            local slotId = resolveSlotId(state, slot, attachmentId)

            if not slotId then
                return false
            end

            return canInstall(swep.FTRuntime, slotId, attachmentId)
        end,
        GetSubSlotList = function()
            return state.swep.Attachments or {}
        end,
        GetAttachmentList = function()
            local result = {}

            for _, slot in ipairs(attachmentSlots(swep.FTRuntime)) do
                local installed = installedAttachments(swep.FTRuntime)[slot.id]

                if installed then
                    result[#result + 1] = state.ftToSynthetic[installed] or installed
                end
            end

            return result
        end,
        GetSlotBlocked = function()
            return false
        end,
        SlotIsCosmetic = function()
            return false
        end,
        GetFilledMergeSlot = function(_, address)
            return normalizedSlot(address)
        end,
        GetFinalAttTable = function(_, slot)
            local id = type(slot) == "table" and slot.Installed or slot
            id = state.ftToSynthetic[id] or id
            local registry = state.bridge.GetRegistry and state.bridge.GetRegistry() or nil
            return registry and registry[id] or {}
        end,
        GetAttachmentPos = function(_, slottbl, _, _, _, custompos, customang)
            local slot = normalizedSlot(slottbl)
            local position = custompos ~= nil and safeVector(custompos) or slot.Pos
            local facing = customang ~= nil and safeAngle(customang) or slot.Ang

            return safeVector(position), safeAngle(facing), safeVector(slot.Icon_Offset)
        end,
        GetPickX = function()
            return 999
        end,
        CountAttachments = function()
            local count = 0

            for _ in pairs(installedAttachments(swep.FTRuntime)) do
                count = count + 1
            end

            return count
        end,
        ValidateAttachment = function(_, attachment, _, address)
            local attachmentId = attachmentIdFor(state, attachment)
            local slotId = resolveSlotId(state, address, attachmentId ~= "" and attachmentId or nil)
            local installed = slotId and installedAttachments(swep.FTRuntime)[slotId]
            local isInstalled = installed ~= nil and installed == attachmentId

            if attachmentId == "" then
                return slotId ~= nil, isInstalled or installed == nil, false, false
            end

            local allowed = slotId and canInstall(
                swep.FTRuntime,
                slotId,
                attachmentId
            ) or false

            return true, isInstalled, not allowed, false
        end,
        GetSlotMissingDependents = function()
            return false
        end,
        ToggleStat = function()
            return false
        end,
        GetTrueRPM = function()
            return getValue("RPM", 0)
        end,
        GetAnimationTime = function()
            return 1
        end,
        GetAnimationEntry = function()
            return {}
        end,
        GetCurrentFiremodeTable = function()
            local ir = getIR() or {}
            return {Mode = ir.fire and ir.fire.automatic and 2 or 1}
        end,
        GetSecondaryAmmoType = function()
            return "none"
        end,
        GetNthShot = function()
            return 0
        end,
        GetHeatAmount = function()
            return 0
        end,
        GetHeatLockout = function()
            return false
        end,
        GetBipod = function()
            return false
        end,
        GetBipodAmount = function()
            return 0
        end,
        GetBipodAng = function()
            return safeAngle()
        end,
        GetBipodPos = function()
            return safeVector()
        end,
        StillWaiting = function()
            return false
        end,
        GetReadyTime = function()
            return 0
        end,
        GetBinding = function(_, bind)
            if input and input.LookupBinding then
                local ok, value = pcall(input.LookupBinding, bind)

                if ok then
                    return string.upper(value or tostring(bind or ""))
                end
            end

            return tostring(bind or "")
        end,
        GetSight = function()
            local ir = getIR() or {}
            local ads = ir.ads or {}

            return {
                Ang = safeAngle(ads.ang),
                FlatScope = false,
                Pos = safeVector(ads.pos),
                atttbl = {},
                slottbl = activeSightSlot()
            }
        end,
        GetSightPositions = function()
            local ir = getIR() or {}
            local ads = ir.ads or {}
            return safeVector(ads.pos), safeAngle(ads.ang)
        end,
        GetExtraSightPositions = function()
            return safeVector(), safeAngle()
        end,
        GetActiveSightSlotTable = function()
            return activeSightSlot()
        end,
        GetSightDelta = function()
            return swep.FTRuntime and swep.FTRuntime.aimFraction or 0
        end,
        GetInSights = function()
            return swep.FTRuntime and swep.FTRuntime.aiming or false
        end,
        GetInspecting = function()
            return state.open
        end,
        GetClass = function()
            if swep.GetClass then
                return swep:GetClass()
            end

            return swep.Class or "ft_weapon"
        end,
        GetPrintName = function()
            local ir = getIR() or {}
            return ir.meta and ir.meta.printName or swep.PrintName or "Weapon"
        end,
        HoldBreathHUD = function() end,
        DrawRadialMenu = function() end,
        DrawLockOnHUD = function() end,
        SetupActiveSights = function() end,
        SendDetail_SlidePos = function() end,
        ToggleSlot = function() end,
        GetInfiniteAmmo = function()
            return false
        end,
        GetGrenadeIndex = function()
            return nil
        end,
        GetLockOnEntity = function()
            return nil
        end,
        GetLockOnStartTime = function()
            return 0
        end,
        PostModify = function()
            return false
        end,
        InvalidateCache = function()
            return false
        end,
        CancelReload = function()
            return false
        end,
        PlayTranslatedSound = function(_, data)
            if surface and surface.PlaySound and type(data) == "table" and data.sound then
                surface.PlaySound(data.sound)
            end
        end
    }

    if state.bridge.id == "arc9" then
        -- ARC9's preset panel is presentation-only.  Keep its UI helpers and
        -- route all persistence/attachment actions through the F&T facades.
        -- ARC9's `GetCurrentFiremode` contract is numeric (the table-valued
        -- companion is `GetCurrentFiremodeTable`).  Keep both contracts
        -- explicit so the vendor stats/animation UI cannot compare a table
        -- with a number or fall through to vendor firemode state.
        overrides.GetCurrentFiremode = function()
            local ir = getIR() or {}
            return ir.fire and ir.fire.automatic and 2 or 1
        end
        overrides.RandomChoice = function(_, choice)
            if type(choice) == "table" then
                -- Preserve a stable presentation result without invoking
                -- vendor randomness or touching F&T gameplay state.
                if choice[1] ~= nil then
                    return choice[1]
                end

                local keys = Table.Keys(choice)
                return #keys > 0 and choice[keys[1]] or ""
            end

            return choice or ""
        end
        overrides.CreatePresetMenu = nil
        overrides.ClosePresetMenu = nil
        overrides.DeletePreset = function()
            return false
        end
        overrides.IgnorePreset = function()
            return false
        end
        overrides.LoadPresetFromCode = function()
            return false
        end
        overrides.LoadPresetFromTable = function()
            return false
        end
        overrides.ImportPresetCode = function()
            return nil
        end
        overrides.GeneratePresetExportCode = function()
            return ""
        end
        overrides.GetPresetJSON = function()
            return "{}"
        end
        overrides.GetPresetData = function(_, preset)
            return tostring(preset or ""), 0
        end
        overrides.GetPresetName = function(_, preset)
            return tostring(preset or "")
        end
        overrides.GetAttCountFromTable = function()
            return 0
        end
        overrides.DevStuffMenu = function()
            return false
        end
    else
        overrides.CreatePresetMenu = function()
            return false
        end
        overrides.ClosePresetMenu = function() end
    end

    for key, value in pairs(overrides) do
        saveAndSet(state, key, value)
    end

    local ir = getIR()

    if type(ir) ~= "table" then
        ir = {}
    end
    local meta = type(ir.meta) == "table" and ir.meta or {}
    local damage = type(ir.damage) == "table" and ir.damage or {}
    local fire = type(ir.fire) == "table" and ir.fire or {}
    local ammo = type(ir.ammo) == "table" and ir.ammo or {}
    local spread = type(ir.spread) == "table" and ir.spread or {}
    local ballistics = type(ir.ballistics) == "table" and ir.ballistics or {}
    local recoil = type(ir.recoil) == "table" and ir.recoil or {}
    local procedural = type(recoil.procedural) == "table" and recoil.procedural or {}
    local minRange, maxRange = rangeValues(ir)
    local vertical = tonumber(procedural.vertical) or 0
    local horizontal = tonumber(procedural.horizontal) or 0

    if state.bridge.id == "arc9" then
        -- The shipped ARC9 stats/bench panels read these fields directly in
        -- addition to calling GetProcessedValue.  Populate every operand
        -- from the effective F&T IR so nil arithmetic cannot escape through
        -- the presentation layer, while keeping unsupported vendor gameplay
        -- features explicitly disabled.
        local animations = type(ir.animations) == "table" and ir.animations or {}
        local reloadTime = tonumber(animations.reloadDuration)

        saveAndSet(state, "ClipSize", tonumber(ammo.clipSize) or 0)
        saveAndSet(state, "ChamberSize", tonumber(ammo.chamberSize) or 0)
        saveAndSet(state, "Num", tonumber(ballistics.pellets) or 1)
        saveAndSet(state, "ReloadTime", reloadTime and reloadTime > 0 and reloadTime or 1.8)
        saveAndSet(state, "ManualAction", false)
        saveAndSet(state, "TriggerDelayRepeat", false)
        saveAndSet(state, "TriggerDelayTime", 0)
        saveAndSet(state, "CycleTime", 0)
        saveAndSet(state, "PostBurstDelay", 0)
        saveAndSet(state, "BottomlessClip", false)

        -- ARC9's benchmark accesses this table directly.  Use the same
        -- neutral body multipliers exposed by the common F&T facade.
        saveAndSet(state, "BodyDamageMults", {
            [HITGROUP_HEAD or 1] = 1,
            [HITGROUP_CHEST or 2] = 1,
            [HITGROUP_STOMACH or 3] = 1,
            [HITGROUP_LEFTARM or 4] = 1,
            [HITGROUP_RIGHTARM or 5] = 1,
            [HITGROUP_LEFTLEG or 6] = 1,
            [HITGROUP_RIGHTLEG or 7] = 1
        })
        saveAndSet(state, "DistributeDamage", false)
        saveAndSet(state, "NormalizeNumDamage", false)
        saveAndSet(state, "TriggerDelay", false)
        saveAndSet(state, "PrimaryBash", false)
        saveAndSet(state, "Throwable", false)
        saveAndSet(state, "ShootEnt", false)
        saveAndSet(state, "InfiniteAmmo", false)
        saveAndSet(state, "HeadshotDamage", 1)
        saveAndSet(state, "ChestDamage", 1)
        saveAndSet(state, "StomachDamage", 1)
        saveAndSet(state, "ArmDamage", 1)
        saveAndSet(state, "LegDamage", 1)
        saveAndSet(state, "SweetSpot", false)
        saveAndSet(state, "SweetSpotRange", 0)
        saveAndSet(state, "SweetSpotDamage", 0)
        saveAndSet(state, "ExplosionDamage", 0)
        saveAndSet(state, "RecoilUp", tonumber(vertical) or 0)
        saveAndSet(state, "RecoilSide", tonumber(horizontal) or 0)
        saveAndSet(state, "RPM", tonumber(fire.rpm) or 0)
    end

    local baseDamage = tonumber(damage.base) or 0
    local minimumDamage = tonumber(damage.minimum) or 0
    local rpm = tonumber(fire.rpm) or 0
    local clipSize = tonumber(ammo.clipSize) or 0
    local pellets = tonumber(ballistics.pellets) or 1
    local delay = tonumber(fire.delay)

    if not delay and rpm > 0 then
        delay = 60 / rpm
    end

    saveAndSet(state, "PrintName", meta.printName or "Weapon")
    saveAndSet(state, "Category", meta.category or "F&T Base")
    saveAndSet(state, "Author", meta.author or "")
    saveAndSet(state, "Manufacturer", meta.manufacturer or "")
    saveAndSet(state, "Purpose", meta.purpose or "")
    saveAndSet(state, "Description", meta.description or "")
    saveAndSet(state, "Primary", {
        Ammo = ammo.type or "",
        Automatic = fire.automatic == true,
        ClipSize = clipSize,
        Damage = baseDamage,
        DamageMax = baseDamage,
        DamageMin = minimumDamage,
        Delay = delay or 0.1,
        IronAccuracy = tonumber(spread.ads) or 0,
        KickDown = 0,
        KickHorizontal = horizontal,
        KickUp = vertical,
        NumShots = pellets,
        RPM = rpm,
        RangeFalloffLUTBuilt = {{0, 1}, {maxRange, baseDamage ~= 0 and minimumDamage / baseDamage or 1}},
        Spread = tonumber(spread.hip) or 0
    })
    saveAndSet(state, "Secondary", {
        Ammo = "none",
        Automatic = false,
        DisplayIronSpread = true,
        DisplaySpread = true,
        IronSightsEnabled = true
    })
    saveAndSet(state, "Damage", baseDamage)
    saveAndSet(state, "DamageMax", baseDamage)
    saveAndSet(state, "DamageMin", minimumDamage)
    saveAndSet(state, "Damage_Max", baseDamage)
    saveAndSet(state, "Damage_Min", minimumDamage)
    saveAndSet(state, "Range", maxRange)
    saveAndSet(state, "RangeMax", maxRange)
    saveAndSet(state, "RangeMin", minRange)
    saveAndSet(state, "Range_Max", maxRange)
    saveAndSet(state, "Range_Min", minRange)
    saveAndSet(state, "RPM", rpm)
    saveAndSet(state, "Recoil", vertical)
    saveAndSet(state, "RecoilSide", horizontal)
    saveAndSet(state, "Cone", tonumber(spread.hip) or 0)
    saveAndSet(state, "Firemodes", {
        {Name = fire.automatic and "Automatic" or "Semi-Automatic"}
    })
end

local function withTemporaryFields(state, fields, callback)
    if type(fields) ~= "table" or #fields == 0 then
        return pcall(callback)
    end

    local swep = state.swep
    local raw = weaponTable(swep)

    if not raw then
        return false, "invalid F&T weapon"
    end

    local saved = {}

    for index, field in ipairs(fields) do
        local key = type(field) == "table" and (field.key or field[1]) or field
        local value = type(field) == "table" and field.value or true

        if type(key) == "string" and key ~= "" then
            saved[#saved + 1] = {
                key = key,
                present = rawget(raw, key) ~= nil,
                value = rawget(raw, key)
            }
            swep[key] = value
        end
    end

    local ok, result = pcall(callback)

    for index = #saved, 1, -1 do
        local field = saved[index]
        if field.present then
            swep[field.key] = field.value
        else
            swep[field.key] = nil
        end
    end

    return ok, result
end

callVendor = function(state, methodName, ...)
    local method = state.vendorMethods[methodName]

    if type(method) ~= "function" then
        return false, "missing UI method " .. tostring(methodName)
    end

    local arguments = {...}
    local ok, result = withTemporaryFields(state, state.bridge.transientFields, function()
        return method(state.swep, unpack(arguments))
    end)

    -- Vendor constructors commonly publish their panel through a process-wide
    -- global.  Capture the value they actually left behind so nested bridge
    -- scopes can restore the surviving overlay instead of its stale baseline.
    captureGlobalOverlays(state)

    if not ok then
        return false, result
    end

    return true, result
end

local function warnMissing(id, reason)
    local key = tostring(id) .. ":" .. tostring(reason)

    if MissingWarnings[key] then
        return
    end

    MissingWarnings[key] = true

    if ErrorNoHalt then
        ErrorNoHalt("[F&T Base] UI bridge " .. tostring(id) .. " unavailable: " .. tostring(reason) .. "\n")
    elseif print then
        print("[F&T Base] UI bridge " .. tostring(id) .. " unavailable: " .. tostring(reason))
    end
end

local function patchCloseButtons(state)
    local bridge = state.bridge.id

    if bridge == "tfa" then
        local root = state.tfaPanel

        if valid(root) then
            if root.OnRemove ~= state.tfaOnRemove then
                state.tfaOriginalOnRemove = root.OnRemove
                state.tfaVendorRemoved = false
                state.tfaOnRemove = function(self)
                    if state.tfaPanel ~= self or state.inTfaOnRemove then
                        return
                    end

                    if state.open and not state.closing and not state.refreshing
                        and not state.panelRemoving then
                        if type(state.tfaOriginalOnRemove) == "function" then
                            state.inTfaOnRemove = true
                            pcall(state.tfaOriginalOnRemove, self)
                            state.inTfaOnRemove = false
                        end

                        UIBridge.Close(state.swep)
                        return
                    end

                    if type(state.tfaOriginalOnRemove) == "function"
                        and not state.tfaVendorRemoved then
                        state.tfaVendorRemoved = true
                        state.inTfaOnRemove = true
                        pcall(state.tfaOriginalOnRemove, self)
                        state.inTfaOnRemove = false
                    end
                end
                root.OnRemove = state.tfaOnRemove
            end
        end
    elseif bridge == "arc9" then
        local root = state.swep.CustomizeHUD
        local panel = root and root.topright_panel
        local children = panel and panel.GetChildren and panel:GetChildren() or {}
        local close = children[#children]

        -- ARC9 removes its root panel from paint/weapon callbacks without
        -- calling the bridge close path.  Keep the vendor teardown callback,
        -- but make an unprompted removal close the scoped bridge as well.  The
        -- guards make this idempotent when `UIBridge.Close` itself removes the
        -- panel and when a refresh reuses the same root.
        if root then
            if state.arc9Panel ~= root or root.OnRemove ~= state.arc9OnRemove then
                state.arc9Panel = root
                state.arc9OriginalOnRemove = root.OnRemove
                state.arc9VendorRemoved = false
                state.arc9OnRemove = function(self)
                    if state.arc9Panel ~= self or state.inArc9OnRemove then
                        return
                    end

                    if state.open and not state.closing and not state.refreshing
                        and not state.panelRemoving then
                        state.panelRemoving = true
                        UIBridge.Close(state.swep)
                        state.panelRemoving = false
                    end

                    if type(state.arc9OriginalOnRemove) == "function"
                        and not state.arc9VendorRemoved then
                        state.arc9VendorRemoved = true
                        state.inArc9OnRemove = true
                        pcall(state.arc9OriginalOnRemove, self)
                        state.inArc9OnRemove = false
                    end
                end
                root.OnRemove = state.arc9OnRemove
            end
        end

        if close then
            close.DoClick = function()
                return UIBridge.Close(state.swep)
            end
        end
    elseif bridge == "arccw" then
        local root = ArcCW and ArcCW.InvHUD

        if valid(root) then
            state.arcCWPanel = root
            local originalOnRemove = root.OnRemove

            root.OnRemove = function(self)
                if state.arcCWPanel ~= self then
                    return
                end

                if state.open and not state.closing and not state.refreshing
                    and not state.panelRemoving and not state.inVendorOnRemove then
                    -- Preserve vendor teardown (including any vendor-side
                    -- net transaction, which remains guarded while state.open
                    -- is true), then let the bridge perform full cleanup.
                    if type(originalOnRemove) == "function" then
                        state.inVendorOnRemove = true
                        pcall(originalOnRemove, self)
                        state.inVendorOnRemove = false
                    end
                    UIBridge.Close(state.swep)
                    return
                end

                -- A controlled refresh and the explicit bridge close both
                -- remove the vendor panel deliberately.  Preserve its own
                -- teardown hook, but do not recurse if that hook removes the
                -- panel again.
                if type(originalOnRemove) == "function"
                    and not state.inVendorOnRemove then
                    if type(originalOnRemove) == "function" then
                        state.inVendorOnRemove = true
                        pcall(originalOnRemove, self)
                        state.inVendorOnRemove = false
                    end
                end

                if ArcCW then
                    ArcCW.Inv_Fade = 0.01
                end

                if gui and gui.EnableScreenClicker then
                    gui.EnableScreenClicker(false)
                end
            end

            local children = root.GetChildren and root:GetChildren() or {}

            for _, child in ipairs(children) do
                if child and child.DoRightClick and child.GetY and child:GetY() <= 64 then
                    child.DoClick = function()
                        return UIBridge.Close(state.swep)
                    end
                    child.DoRightClick = function()
                        return UIBridge.Close(state.swep)
                    end
                    break
                end
            end
        end
    elseif bridge == "mw" then
        local root = rawget(_G, "MW_CUSTOMIZEMENU")

        if valid(root) then
            state.mwPanel = root
            local originalOnRemove = root.OnRemove

            root.OnRemove = function(self)
                if state.mwPanel ~= self then
                    return
                end

                if state.open and not state.closing and not state.refreshing
                    and not state.panelRemoving and not state.inVendorOnRemove then
                    state.inVendorOnRemove = true
                    pcall(originalOnRemove, self)
                    state.inVendorOnRemove = false
                    UIBridge.Close(state.swep)
                    return
                end

                if type(originalOnRemove) == "function"
                    and not state.inVendorOnRemove then
                    state.inVendorOnRemove = true
                    pcall(originalOnRemove, self)
                    state.inVendorOnRemove = false
                end

                if gui and gui.EnableScreenClicker then
                    gui.EnableScreenClicker(false)
                end
            end
        end
    elseif bridge == "tacrp" then
        local root = state.swep.CustomizeHUD

        if valid(root) then
            state.tacrpPanel = root

            if root.OnRemove ~= state.tacrpOnRemove then
                state.tacrpOriginalOnRemove = root.OnRemove
                state.tacrpVendorRemoved = false
                state.tacrpOnRemove = function(self)
                    if state.tacrpPanel ~= self or state.inTacRPOnRemove then
                        return
                    end

                    if state.open and not state.closing and not state.refreshing
                        and not state.panelRemoving then
                        if type(state.tacrpOriginalOnRemove) == "function" then
                            state.inTacRPOnRemove = true
                            pcall(state.tacrpOriginalOnRemove, self)
                            state.inTacRPOnRemove = false
                        end

                        UIBridge.Close(state.swep)
                        return
                    end

                    if type(state.tacrpOriginalOnRemove) == "function"
                        and not state.tacrpVendorRemoved then
                        state.tacrpVendorRemoved = true
                        state.inTacRPOnRemove = true
                        pcall(state.tacrpOriginalOnRemove, self)
                        state.inTacRPOnRemove = false
                    end
                end
                root.OnRemove = state.tacrpOnRemove
            end
        end
    end
end

local function prepareState(swep, bridge, open, domain, registerState)
    local registered = registerState ~= false
    local state = {
        bridge = bridge,
        domain = normalize(domain),
        ftToSynthetic = {},
        globalsRestored = false,
        open = open and true or false,
        projectedSlots = {},
        registryEntries = {},
        restored = false,
        saved = {},
        savedOrder = {},
        swep = swep,
        syntheticToFT = {},
        vendorSlotToFT = {}
    }
    state.registered = registered
    state.netGuard = state.open or state.domain == "hud"
    state.previousTemporary = not registered and TemporaryStates[swep] or nil
    state.fallbackState = not registered and States[swep] or nil

    local ok, reason = pcall(function()
        if registered then
            States[swep] = state
        else
            TemporaryStates[swep] = state
        end

        if state.netGuard then
            installVendorNetGuard(state)
        end

        saveBridgeState(state)
        collectVendorData(state)
        commonOverrides(state)
        buildSynthetic(state)

        if bridge.Prepare then
            bridge.Prepare(state)
        end
    end)

    if ok then
        return state
    end

    -- Preparation can touch several vendor registries/globals before the
    -- panel exists.  Roll those changes back even when a stripped dependency
    -- throws from a helper, otherwise a failed open would poison later F&T UI.
    state.open = false
    state.closing = true
    cleanupSynthetic(state)
    restoreOverlay(state)

    if restoreArcCWFacade then
        restoreArcCWFacade(state)
    end

    if restoreMWInterceptor then
        restoreMWInterceptor(state)
    end

    restoreGlobals(state)
    restoreVendorNetGuard(state)

    if registered then
        if States[swep] == state then
            States[swep] = nil
        end
    elseif TemporaryStates[swep] == state then
        TemporaryStates[swep] = state.previousTemporary
    end

    return nil, reason
end

local function configuredValue(configuration, key)
    if type(configuration) ~= "table" then
        return nil, false
    end

    if rawget(configuration, key) ~= nil then
        return rawget(configuration, key), true
    end

    for _, candidate in ipairs(Table.Keys(configuration)) do
        if normalize(candidate) == normalize(key) then
            return configuration[candidate], true
        end
    end

    return nil, false
end

local function bridgeConfig(swep, domain)
    local configured = swep and swep.FTUIBridge

    if configured == nil and swep then
        configured = swep.FTNativeUIBridge
    end

    domain = normalize(domain)

    if configured == false then
        return "none"
    end

    if type(configured) == "string" then
        return normalize(configured)
    end

    if type(configured) == "table" then
        local value, explicit = configuredValue(configured.domains, domain)

        if not explicit then
            value, explicit = configuredValue(configured, domain)
        end

        if not explicit then
            value, explicit = configuredValue(configured, "default")
        end

        if not explicit then
            value, explicit = configuredValue(configured, "provider")
        end

        if explicit then
            if value == false or normalize(value) == "none" then
                return "none"
            end

            return value ~= nil and normalize(value) or nil
        end
    end

    -- Ordinary dialect templates do not need an extra SWEP-side bridge table.
    -- Their compiled per-domain provider is already selected from FT.Visual,
    -- provenance and FT.Priority by ProviderHost.  Only opt into a vendor
    -- renderer when that provider has a registered bridge; `ft` still follows
    -- the existing F&T UI path.
    local runtime = swep and swep.FTRuntime
    local host = FTBase.Runtime.ProviderHost
    local providerId = host and host.GetProviderId and host.GetProviderId(runtime, domain)

    if providerId and Bridges[normalize(providerId)] then
        return normalize(providerId)
    end

    return nil
end

function UIBridge.Register(id, definition)
    if type(definition) ~= "table" then
        return false
    end

    id = normalize(id)
    definition.id = id
    definition.blockFields = definition.blockFields or {}
    definition.blockMethods = definition.blockMethods or {}
    Bridges[id] = definition
    return true
end

function UIBridge.Get(id)
    return Bridges[normalize(id)]
end

function UIBridge.GetConfigured(swep, domain)
    return bridgeConfig(swep, domain)
end

function UIBridge.IsConfigured(swep, domain)
    return bridgeConfig(swep, domain) ~= nil
end

function UIBridge.IsBridgeWeapon(swep, id)
    local state = stateFor(swep)
    return state ~= nil and (not id or state.bridge.id == normalize(id))
end

function UIBridge.IsAvailable(swep, domain)
    if not CLIENT then
        return false, "UI bridges are client-only"
    end

    local id = bridgeConfig(swep, domain)

    if id == nil then
        return false, "weapon has no UI bridge for " .. tostring(domain)
    end

    if id == "none" then
        return false, "UI domain is disabled"
    end

    local bridge = Bridges[id]

    if not bridge then
        return false, "unknown bridge " .. tostring(id)
    end

    if not storedWeapon(bridge.sampleClass or bridge.baseClass) then
        return false, "missing dependency class " .. tostring(bridge.sampleClass or bridge.baseClass)
    end

    if bridge.IsAvailable then
        return bridge.IsAvailable(swep)
    end

    return true
end

local function globalSpecTarget(spec)
    if type(spec) ~= "table" then
        return nil
    end

    if spec.target == "_G" then
        return _G
    end

    return type(spec.target) == "string" and rawget(_G, spec.target) or nil
end

local function bridgesShareGlobal(older, newer)
    for _, oldSpec in ipairs(older and older.globalFields or {}) do
        local oldTarget = globalSpecTarget(oldSpec)

        if oldTarget then
            for _, newSpec in ipairs(newer and newer.globalFields or {}) do
                if oldTarget == globalSpecTarget(newSpec)
                    and oldSpec.key == newSpec.key then
                    return true
                end
            end
        end
    end

    return false
end

local function closeConflictingStates(swep, bridge)
    local conflicts = {}

    for other, state in pairs(States) do
        if other ~= swep and state and state.open and not state.closing
            and bridgesShareGlobal(state.bridge, bridge) then
            conflicts[#conflicts + 1] = other
        end
    end

    for _, other in ipairs(conflicts) do
        UIBridge.Close(other)
    end
end

local function hasOpenState()
    for _, state in pairs(States) do
        if state and state.open and not state.closing then
            return true
        end
    end

    return false
end

local function playOpenAnimation(swep)
    local runtime = swep.FTRuntime
    local ir = effectiveIR(swep)
    local animation = ir and ir.ui and ir.ui.inspect and ir.ui.inspect.animation
        or ir and ir.animations and ir.animations.inspect
    local animationAPI = FTBase.Runtime.Animation

    runtime.customizationOpen = true

    if animation ~= nil and animationAPI
        and type(animationAPI.PlaySequence) == "function" then
        animationAPI.PlaySequence(swep, runtime, "inspect", animation)
    elseif animationAPI and type(animationAPI.Play) == "function" then
        animationAPI.Play(swep, runtime, "inspect")
    end
end

function UIBridge.Open(swep, domain)
    domain = domain or "inspect"

    if not swep or not swep.FTRuntime then
        return false
    end

    local existing = stateFor(swep)

    if existing and existing.open then
        local requestedId = bridgeConfig(swep, domain)

        if requestedId == existing.bridge.id then
            return UIBridge.Refresh(swep)
        end

        -- Mixed profiles can select different vendor surfaces per domain.  Do
        -- not refresh an attachments bridge when inspect/HUD requested another
        -- provider; switch the single active panel explicitly.
        UIBridge.Close(swep)
    end

    local available, reason = UIBridge.IsAvailable(swep, domain)
    local id = bridgeConfig(swep, domain)

    if not available then
        if id and id ~= "none" then
            warnMissing(id, reason)
        end

        return false
    end

    local bridge = Bridges[id]
    closeConflictingStates(swep, bridge)
    local state, prepareError = prepareState(swep, bridge, true, domain)

    if not state then
        warnMissing(id, prepareError or "bridge preparation failed")
        return false
    end

    local animationOK, animationError = pcall(playOpenAnimation, swep)

    if not animationOK then
        warnMissing(id, animationError or "F&T inspect animation failed")
        UIBridge.Close(swep)
        return false
    end

    local ok, result

    if bridge.Open then
        ok, result = pcall(bridge.Open, state, callVendor)
    else
        ok, result = callVendor(state, bridge.openMethod)
    end

    if not ok or result == false then
        warnMissing(id, result or "vendor UI refused to open")
        UIBridge.Close(swep)
        return false
    end

    patchCloseButtons(state)
    return true
end

function UIBridge.Close(swep)
    local state = stateFor(swep)

    if not state then
        return false
    end

    if state.closing then
        return true
    end

    state.open = false
    state.closing = true

    if state.bridge.Close then
        pcall(state.bridge.Close, state, callVendor)
    elseif state.bridge.closeMethod then
        callVendor(state, state.bridge.closeMethod)
    end

    if not hasOpenState() and gui and gui.EnableScreenClicker then
        gui.EnableScreenClicker(false)
    end

    if swep.FTRuntime then
        swep.FTRuntime.customizationOpen = false

        if FTBase.Runtime.Animation
            and type(FTBase.Runtime.Animation.Play) == "function" then
            pcall(FTBase.Runtime.Animation.Play, swep, swep.FTRuntime, "idle")
        end
    end

    cleanupSynthetic(state)
    restoreOverlay(state)
    if restoreArcCWFacade then
        restoreArcCWFacade(state)
    end
    if restoreMWInterceptor then
        restoreMWInterceptor(state)
    end
    restoreGlobals(state)
    restoreVendorNetGuard(state)
    States[swep] = nil
    return true
end

function UIBridge.IsOpen(swep)
    local state = stateFor(swep)
    return state ~= nil and state.open == true
end

function UIBridge.Refresh(swep)
    local state = stateFor(swep)

    if not state or not state.open or state.refreshing then
        return false
    end

    state.refreshing = true

    local prepared, prepareError = pcall(function()
        buildSynthetic(state)

        if state.bridge.Prepare then
            state.bridge.Prepare(state)
        end
    end)

    if not prepared then
        state.refreshing = false
        warnMissing(state.bridge.id, prepareError)
        UIBridge.Close(swep)
        return false
    end

    local ok, result = true, true

    if state.bridge.Refresh then
        ok, result = pcall(state.bridge.Refresh, state, callVendor)
    elseif state.bridge.refreshMethod then
        ok, result = callVendor(state, state.bridge.refreshMethod)
    end

    state.refreshing = false

    if not ok or result == false then
        warnMissing(state.bridge.id, result)
        UIBridge.Close(swep)
        return false
    end

    patchCloseButtons(state)
    return result ~= false
end

function UIBridge.DrawHUD(swep)
    if not swep or not swep.FTRuntime then
        return false
    end

    local available, reason = UIBridge.IsAvailable(swep, "hud")
    local id = bridgeConfig(swep, "hud")

    if not available then
        if id and id ~= "none" then
            warnMissing(id, reason)
        end

        return false
    end

    local activeState = stateFor(swep)
    local state = activeState
    local temporary = not state or state.bridge.id ~= id

    if temporary then
        -- Keep an open customization bridge associated with the weapon while a
        -- different per-domain HUD provider is rendered.  The temporary state
        -- is routed separately so the active state and its overlays remain
        -- intact throughout preparation, drawing, and teardown.
        local prepared, prepareError = prepareState(
            swep,
            Bridges[id],
            false,
            "hud",
            false
        )

        if not prepared then
            warnMissing(id, prepareError or "HUD bridge preparation failed")
            return false
        end

        state = prepared
    end

    local ok, result

    if state.bridge.DrawHUD then
        ok, result = pcall(state.bridge.DrawHUD, state, callVendor)
    else
        ok, result = callVendor(state, state.bridge.hudMethod or "DrawHUD")
    end

    if temporary then
        cleanupSynthetic(state)
        restoreOverlay(state)
        if restoreArcCWFacade then
            restoreArcCWFacade(state)
        end
        if restoreMWInterceptor then
            restoreMWInterceptor(state)
        end
        restoreGlobals(state)
        restoreVendorNetGuard(state)

        if TemporaryStates[swep] == state then
            TemporaryStates[swep] = state.previousTemporary
        end
    end

    if not ok then
        warnMissing(id, result)
        return false
    end

    return result ~= false
end

local function defaultDefinition(_, slot, option, definition, syntheticId)
    return {
        Category = slot.category,
        Description = option.description or definition.description or "",
        Free = true,
        Icon = iconMaterial(definition),
        PrintName = option.name or definition.name or option.id,
        ShortName = syntheticId
    }
end

local function defaultSlots(state, slots)
    local projected = {}

    for _, slot in ipairs(slots) do
        projected[#projected + 1] = {
            Category = slot.category,
            Installed = slot.installed and state.ftToSynthetic[slot.installed] or nil,
            PrintName = slot.name,
            Slot = slot.category
        }
    end

    saveAndSet(state, "Attachments", projected)
end

UIBridge.Register("tfa", {
    sampleClass = "tfa_ins2_cw_ar15",
    baseClass = "tfa_gun_base",
    -- The original inspection panel is composed from these client-side
    -- helpers.  No TFA weapon-state method is imported into the F&T entity.
    uiMethods = {
        "GenerateInspectionDerma",
        "DoInspectionDerma",
        "InspectionVGUISideBars",
        "InspectionVGUIMainInfo",
        "InspectionVGUIStats",
        "InspectionVGUIAttachments",
        "GenerateVGUIAttachmentTable",
        "DrawHUD",
        "DrawHUDAmmo",
        "DrawKeyBindHints",
        "DrawFallbackHUD",
        "HUDShouldDraw",
        "PopulateKeyBindHints",
        "PrePopulateKeyBindHints",
        "PostPopulateKeyBindHints"
    },
    overlayMethods = {
        "GenerateInspectionDerma",
        "DoInspectionDerma",
        "InspectionVGUISideBars",
        "InspectionVGUIMainInfo",
        "InspectionVGUIStats",
        "InspectionVGUIAttachments",
        "GenerateVGUIAttachmentTable",
        "DrawHUDAmmo",
        "DrawKeyBindHints",
        "DrawFallbackHUD",
        "PopulateKeyBindHints",
        "PrePopulateKeyBindHints",
        "PostPopulateKeyBindHints"
    },
    uiFields = {
        "TextCol",
        "TextColContrast",
        "VGUIPaddingH",
        "VGUIPaddingW",
        "textfwdoffset",
        "textrightoffset",
        "textsize",
        "textupoffset"
    },
    transientFields = {
        {key = "IsTFAWeapon", value = true}
    },
    stateFields = {
        "AttachmentCache",
        "AttachmentDependencies",
        "AttachmentExclusions",
        "Attachments"
    },
    globalFields = {
        {target = "TFA", key = "INSPECTIONPANEL"},
        {target = "_G", key = "TFA_INSPECTIONPANEL"}
    },
    blockNetMessages = {
        "TFA_Attachment_Reload",
        "TFA_Attachment_Request",
        "TFA_Attachment_Set",
        "TFA_Attachment_SetStatus"
    },
    GetRegistry = function()
        return TFA and TFA.Attachments and TFA.Attachments.Atts
    end,
    BuildDefinition = function(_, slot, option, definition, syntheticId)
        local description = option.description or definition.description or ""
        return {
            Attach = function() end,
            AttachSound = "buttons/button14.wav",
            CanAttach = function()
                return true
            end,
            Category = slot.category,
            Description = description ~= "" and {description} or {},
            Detach = function() end,
            DetachSound = "buttons/button15.wav",
            Icon = type(definition.icon) == "string" and definition.icon or "entities/tfa_qmark.png",
            Name = option.name or definition.name or option.id,
            ShortName = syntheticId
        }
    end,
    ApplySlots = function(state, slots)
        local projected = {}

        for _, slot in ipairs(slots) do
            local definition = {offset = {0, 0}, atts = {}, order = slot.index}

            for optionIndex, option in ipairs(slot.options) do
                definition.atts[#definition.atts + 1] = option.id

                if option.attachmentId == slot.installed then
                    definition.sel = optionIndex
                end
            end

            projected[slot.index] = definition
            state.vendorSlotToFT[tostring(slot.index)] = slot.slotId
        end

        saveAndSet(state, "Attachments", projected)
        saveAndSet(state, "AttachmentCache", {})
        saveAndSet(state, "AttachmentDependencies", {})
        saveAndSet(state, "AttachmentExclusions", {})
        saveAndSet(state, "SetTFAAttachment", function(_, category, attachmentIndex)
            local definition = projected[category]
            local syntheticId = definition and definition.atts[tonumber(attachmentIndex) or -1] or ""
            local requested = requestAttachment(state, category, syntheticId)

            if requested and definition then
                definition.sel = tonumber(attachmentIndex) and tonumber(attachmentIndex) > 0
                    and tonumber(attachmentIndex) or nil
            end

            return requested
        end)
        saveAndSet(state, "CanAttach", function(_, attachment, detaching)
            local attachmentId = attachmentIdFor(state, attachment)
            local slotId = resolveSlotId(state, nil, attachmentId)

            if detaching then
                return slotId and installedAttachments(state.swep.FTRuntime)[slotId] ~= nil or false
            end

            return slotId and FTBase.Runtime.Attachments.CanInstall(
                state.swep.FTRuntime,
                slotId,
                attachmentId
            ) or false
        end)
    end,
    Open = function(state, call)
        local previousPanel = TFA and TFA.INSPECTIONPANEL
            or rawget(_G, "TFA_INSPECTIONPANEL")

        if valid(previousPanel) and previousPanel.Remove then
            pcall(previousPanel.Remove, previousPanel)
        end

        if TFA then
            setGlobal(state, TFA, "INSPECTIONPANEL", nil)
        end
        setGlobal(state, _G, "TFA_INSPECTIONPANEL", nil)

        local ok, result = call(state, "GenerateInspectionDerma")

        if not ok then
            return false, result
        end

        local panel = TFA and TFA.INSPECTIONPANEL
            or rawget(_G, "TFA_INSPECTIONPANEL")

        if not valid(panel) or panel == previousPanel then
            return false, result or "TFA inspection panel was not created"
        end

        state.tfaPanel = panel

        if valid(panel) then
            panel.Think = function(self)
                local owner = state.swep.GetOwner and state.swep:GetOwner()
                local active = owner and owner.GetActiveWeapon and owner:GetActiveWeapon()

                if not valid(state.swep) or active ~= state.swep then
                    self:Remove()
                    UIBridge.Close(state.swep)
                    return
                end

                self.Player = owner
                self.Weapon = state.swep
            end
        end

        return true, result
    end,
    Close = function(state)
        local panel = state.tfaPanel

        if valid(panel) and panel.Remove then
            state.panelRemoving = true
            panel:Remove()
            state.panelRemoving = false
        end

        state.tfaPanel = nil
    end,
    Refresh = function(state, call)
        local panel = state.tfaPanel

        if valid(panel) and panel.Remove then
            state.panelRemoving = true
            panel:Remove()
            state.panelRemoving = false
        end

        state.tfaPanel = nil

        if TFA then
            setGlobal(state, TFA, "INSPECTIONPANEL", nil)
        end
        setGlobal(state, _G, "TFA_INSPECTIONPANEL", nil)

        return UIBridge.Get("tfa").Open(state, call)
    end,
    DrawHUD = function(state, call)
        return call(state, "DrawHUD")
    end
})

UIBridge.Register("arc9", {
    sampleClass = "arc9_go_ak47",
    baseClass = "arc9_base",
    uiMethods = {
        "CycleSelectedAtt",
        "ClearTabPanel",
        "CreateCustomizeHUD",
        "RemoveCustomizeHUD",
        "DrawCustomizeHUD",
        "CreateHUD_Bottom",
        "ClearBottomBar",
        "CreateHUD_RHP",
        "CreateHUD_Bench",
        "CreateHUD_Stats",
        "CreateHUD_Trivia",
        "CreateHUD_Credits",
        "CreateHUD_Slots",
        "ClearAttInfoBar",
        "CreateHUD_AttInfo",
        "CreatePresetMenu",
        "ClosePresetMenu",
        "CreatePresetName",
        "CreateExportPreset",
        "CreateDeleteDefPreset",
        "CreateImportPreset",
        "RefreshCustomizeMenu",
        "GetSlotMissingDependents",
        "ToggleStat",
        "SlotIsCosmetic",
        "DrawHUD"
    },
    overlayMethods = {
        "CycleSelectedAtt",
        "ClearTabPanel",
        "CreateCustomizeHUD",
        "RemoveCustomizeHUD",
        "DrawCustomizeHUD",
        "CreateHUD_Bottom",
        "ClearBottomBar",
        "CreateHUD_RHP",
        "CreateHUD_Bench",
        "CreateHUD_Stats",
        "CreateHUD_Trivia",
        "CreateHUD_Credits",
        "CreateHUD_Slots",
        "ClearAttInfoBar",
        "CreateHUD_AttInfo",
        "CreatePresetMenu",
        "ClosePresetMenu",
        "CreatePresetName",
        "CreateExportPreset",
        "CreateDeleteDefPreset",
        "CreateImportPreset",
        "RefreshCustomizeMenu",
        "GetSlotMissingDependents",
        "ToggleStat",
        "SlotIsCosmetic"
    },
    stateFields = {
        "AttachmentAddresses",
        "Attachments",
        "CustomizeHUD",
        "RemovingCustHud"
    },
    uiFields = {
        "CustomizeButtons",
        "CustomizeButtonsOriginal",
        "CustomizeTab",
        "CustomizeHints",
        "CustomizePanX",
        "CustomizePanY",
        "CustomizePitch",
        "CustomizeYaw",
        "CustomizeRoll",
        "CustomizeZoom",
        "BottomBar",
        "BottomBarAnchor",
        "BottomBarMode",
        "BottomBarAddress",
        "BottomBarFolders",
        "BottomBarPath",
        "BottomBarAtts",
        "BottomBarCategory",
        "TabPanel",
        "CustomizeBoxes",
        "CustomizeLastHovered",
        "CustomizeLastHoveredSlot2",
        "CustomizeLastHoveredSlot",
        "CustomizeLastHoveredFolder",
        "CustomizeLastHoveredAtt",
        "CustomizeLastHoveredAttSlot",
        "CustomizeLastSelectedSlot",
        "CustomizeLastSelectedAtt",
        "CustomizeAlphaBuffer",
        "LastCustomizeTab",
        "CustomizeSelectAddr",
        "AttInfoBar",
        "AttInfoBarAtt",
        "AttInfoBarAttSlot",
        "LastScroll",
        "Credits",
        "Trivia"
    },
    blockNetMessages = {
        "ARC9_InvalidateAll",
        "ARC9_togglecustomize",
        "arc9_randomizeatts"
    },
    GetRegistry = function()
        return ARC9 and ARC9.Attachments
    end,
    BuildDefinition = function(_, slot, option, definition, syntheticId)
        local projected = defaultDefinition(nil, slot, option, definition, syntheticId)
        projected.CompactName = projected.PrintName
        projected.FullColorIcon = true
        projected.Free = true
        projected.Pros = {}
        projected.Cons = {}
        return projected
    end,
    ApplySlots = function(state, slots)
        local projected = {}

        for _, slot in ipairs(slots) do
            local source = slot.slot or {}
            local position = source.pos or source.position
            local angle = source.ang or source.angle
            local iconOffset = source.iconOffset or source.icon_offset or source.Icon_Offset

            projected[#projected + 1] = {
                Ang = safeAngle(angle),
                Address = slot.index,
                Bone = source.bone or source.Bone or "__ft",
                Category = slot.category or source.category or source.type or "",
                Installed = slot.installed and state.ftToSynthetic[slot.installed] or nil,
                Icon_Offset = safeVector(iconOffset),
                Pos = safeVector(position),
                PrintName = slot.name or source.name or source.id or "Slot",
                OriginalAddress = slot.index,
                Scale = tonumber(source.scale) or 1
            }
        end

        saveAndSet(state, "Attachments", projected)
        saveAndSet(state, "AttachmentAddresses", {})

        -- ARC9's original helper recursively constructs a vendor attachment
        -- tree and calls vendor state methods.  The UI only needs stable slot
        -- addresses, so expose an F&T projection instead.
        saveAndSet(state, "BuildAttachmentAddresses", function(self)
            self.AttachmentAddresses = {}

            for index, slot in ipairs(projected) do
                slot.Address = index
                slot.OriginalAddress = index
                self.AttachmentAddresses[index] = slot
            end

            return self.AttachmentAddresses
        end)
        saveAndSet(state, "LocateSlotFromAddress", function(self, address)
            return self.AttachmentAddresses and self.AttachmentAddresses[address] or nil
        end)
        state.swep:BuildAttachmentAddresses()
    end,
    Open = function(state, call)
        local ok, result = call(state, "CreateCustomizeHUD")
        return ok and valid(state.swep.CustomizeHUD), result
    end,
    Close = function(state, call)
        local root = state.swep.CustomizeHUD

        if root and root.Remove then
            root:Remove()
        else
            call(state, "RemoveCustomizeHUD")
        end
    end,
    Refresh = function(state, call)
        local ok = call(state, "CreateHUD_Bottom")
        return ok
    end,
    DrawHUD = function(state, call)
        local ok, result = withTemporaryFields(state, {
            {key = "ARC9", value = true}
        }, function()
            local okGlobal, resultGlobal = true, true

            if ARC9 and type(ARC9.DrawHUD) == "function" then
                okGlobal, resultGlobal = pcall(ARC9.DrawHUD)
            end

            if not okGlobal then
                return false, resultGlobal
            end

            local okWeapon, resultWeapon = call(state, "DrawHUD")
            return okWeapon, resultWeapon
        end)

        if not ok then
            return false, result
        end

        return result
    end
})

-- ArcCW exposes attachment validation as a global method and its customize
-- panel calls that method after the panel has been created.  Keep one scoped
-- facade for all active ArcCW bridges so refreshes do not stack wrappers and
-- closing one weapon cannot restore a function still needed by another.
local ArcCWFacade = {
    installed = false,
    original = nil,
    states = setmetatable({}, {__mode = "k"}),
    target = nil,
    wrapper = nil
}

local function arcCWCanAttach(state, player, weapon, attachment, slot, detach)
    if not state or weapon ~= state.swep then
        return false
    end

    local owner = state.swep.GetOwner and state.swep:GetOwner()

    -- ArcCW normally performs this check in its global helper.  Keep the
    -- check here as a UI hint, while the F&T networking path remains the
    -- authoritative server-side ownership/cooldown gate.
    if not valid(player) or not valid(owner) or owner ~= player then
        return false
    end

    local attachmentId = attachmentIdFor(state, attachment)
    local slotId = resolveSlotId(state, slot,
        attachmentId ~= "" and attachmentId or nil)

    if not slotId then
        return false
    end

    local runtime = state.swep.FTRuntime
    local installed = installedAttachments(runtime)[slotId]

    if detach or attachmentId == "" then
        return installed ~= nil
    end

    if installed == attachmentId then
        return true
    end

    return canInstall(runtime, slotId, attachmentId)
end

local function arcCWInvokeOriginal(selfArg, player, weapon, attachment, slot, detach)
    if type(ArcCWFacade.original) ~= "function" then
        return false
    end

    return ArcCWFacade.original(ArcCWFacade.target, player, weapon, attachment, slot, detach)
end

local function installArcCWFacade(state)
    local target = rawget(_G, "ArcCW")

    if type(target) ~= "table" then
        return false
    end

    if ArcCWFacade.target and ArcCWFacade.target ~= target then
        if ArcCWFacade.wrapper
            and ArcCWFacade.target.PlayerCanAttach == ArcCWFacade.wrapper then
            ArcCWFacade.target.PlayerCanAttach = ArcCWFacade.original
        end

        ArcCWFacade.installed = false
        ArcCWFacade.original = nil
        ArcCWFacade.target = nil
        ArcCWFacade.wrapper = nil
    end

    if not ArcCWFacade.wrapper then
        ArcCWFacade.target = target
        ArcCWFacade.original = type(target.PlayerCanAttach) == "function"
            and target.PlayerCanAttach or nil
        ArcCWFacade.wrapper = function(selfArg, player, weapon, attachment, slot, detach)
            -- Accept both `ArcCW:PlayerCanAttach(...)` (the vendor form) and
            -- dot-style calls that omit the table receiver.
            if selfArg ~= ArcCWFacade.target then
                detach = slot
                slot = attachment
                attachment = weapon
                weapon = player
                player = selfArg
            end

            local stateForWeapon = routedStateFor(weapon)

            if stateForWeapon and stateForWeapon.bridge.id ~= "arccw" then
                local activeState = stateFor(weapon)

                if activeState and activeState.bridge.id == "arccw" then
                    stateForWeapon = activeState
                end
            end

            if stateForWeapon and stateForWeapon.bridge.id == "arccw" then
                return arcCWCanAttach(
                    stateForWeapon,
                    player,
                    weapon,
                    attachment,
                    slot,
                    detach
                )
            end

            return arcCWInvokeOriginal(
                selfArg,
                player,
                weapon,
                attachment,
                slot,
                detach
            )
        end
    end

    -- If another addon replaced the method while a bridge was open, retain
    -- that replacement as the delegate instead of calling our wrapper
    -- recursively.  The latest external function is restored after the last
    -- bridge closes.
    if target.PlayerCanAttach ~= ArcCWFacade.wrapper then
        ArcCWFacade.original = type(target.PlayerCanAttach) == "function"
            and target.PlayerCanAttach or nil
        target.PlayerCanAttach = ArcCWFacade.wrapper
    end

    ArcCWFacade.installed = true
    ArcCWFacade.states[state] = true
    state.arcCWFacade = true
    return true
end

restoreArcCWFacade = function(state)
    if not ArcCWFacade.installed then
        return
    end

    ArcCWFacade.states[state] = nil

    for _ in pairs(ArcCWFacade.states) do
        return
    end

    if ArcCWFacade.target and ArcCWFacade.wrapper
        and ArcCWFacade.target.PlayerCanAttach == ArcCWFacade.wrapper then
        ArcCWFacade.target.PlayerCanAttach = ArcCWFacade.original
    end

    ArcCWFacade.installed = false
    ArcCWFacade.original = nil
    ArcCWFacade.target = nil
    ArcCWFacade.wrapper = nil
end

local function withArcCWGamemodeButtonsDisabled(callback)
    local arc = rawget(_G, "ArcCW")
    local convars = arc and arc.ConVars

    local present = type(convars) == "table"
        and rawget(convars, "attinv_gamemodebuttons") ~= nil
    local previous = present and rawget(convars, "attinv_gamemodebuttons") or nil
    local originalFunction = arc and arc.InvHUD_FormGamemodeFunctions
    local scopedFunction

    local function setDisabled()
        if type(convars) ~= "table" then
            return
        end

        -- The vendor helper dereferences this value unconditionally.  A
        -- false-valued facade also handles stripped/minimal dependency builds
        -- where the convar entry is absent.
        convars.attinv_gamemodebuttons = {
            GetBool = function()
                return false
            end
        }
    end

    local function restoreConVar()
        if type(convars) ~= "table" then
            return
        end

        if present then
            convars.attinv_gamemodebuttons = previous
        else
            convars.attinv_gamemodebuttons = nil
        end
    end

    local function invokeVendorGamemodeFunction(...)
        setDisabled()
        local invoked, result, extra = pcall(originalFunction, ...)
        restoreConVar()

        if not invoked then
            error(result, 0)
        end

        return result, extra
    end

    -- Wrap the exact helper that creates TTT/radio/drop controls.  This keeps
    -- the guard effective even if the vendor constructor reads the convar
    -- after entering the helper, and restores the original function on every
    -- exit path.
    if arc and type(originalFunction) == "function" then
        scopedFunction = function(...)
            return invokeVendorGamemodeFunction(...)
        end
        arc.InvHUD_FormGamemodeFunctions = scopedFunction
    end

    setDisabled()
    local invoked, ok, result = pcall(callback)
    restoreConVar()

    if arc and scopedFunction and arc.InvHUD_FormGamemodeFunctions == scopedFunction then
        arc.InvHUD_FormGamemodeFunctions = originalFunction
    end

    if not invoked then
        return false, ok
    end

    return ok, result
end

UIBridge.Register("arccw", {
    sampleClass = "arccw_go_ak47",
    baseClass = "arccw_base",
    customizeState = 4,
    uiMethods = {
        "CreateCustomize2HUD",
        "DrawHUD"
    },
    stateFields = {
        "Attachments"
    },
    globalFields = {
        {target = "ArcCW", key = "InvHUD"},
        {target = "ArcCW", key = "Inv_Fade"},
        {target = "ArcCW", key = "Inv_Hidden"},
        {target = "ArcCW", key = "Inv_ShownAtt"},
        {target = "ArcCW", key = "Inv_SelectedMenu"},
        {target = "ArcCW", key = "Inv_SelectedInfo"}
    },
    blockNetMessages = {
        "arccw_applypreset",
        "arccw_asktoattach",
        "arccw_asktodetach",
        "arccw_asktodrop",
        "arccw_networkatts",
        "arccw_togglecustomize",
        "arccw_slidepos",
        "arccw_togglenum"
    },
    GetRegistry = function()
        return ArcCW and ArcCW.AttachmentTable
    end,
    BuildDefinition = function(_, slot, option, definition, syntheticId)
        local projected = defaultDefinition(nil, slot, option, definition, syntheticId)
        projected.CompactName = projected.PrintName
        projected.Slot = slot.category
        projected.IgnorePickX = true
        return projected
    end,
    ApplySlots = function(state, slots)
        local projected = {}

        for _, slot in ipairs(slots) do
            projected[#projected + 1] = {
                Address = slot.index,
                Category = slot.category,
                Installed = slot.installed and state.ftToSynthetic[slot.installed] or nil,
                PrintName = slot.name,
                Slot = slot.category
            }
            state.vendorSlotToFT[tostring(slot.index)] = slot.slotId
        end

        saveAndSet(state, "Attachments", projected)
    end,
    Prepare = function(state)
        saveAndSet(state, "GetSlotInstalled", function(_, slot)
            local attachments = state.swep.Attachments
            local projected = type(attachments) == "table"
                and attachments[slot] or nil
            return projected and projected.Installed
        end)

        if ArcCW then
            -- These are process-wide UI cursors in ArcCW.  saveBridgeState
            -- captures their original values before Prepare changes them;
            -- restoreGlobals puts them back when the bridge closes.
            setGlobal(state, ArcCW, "Inv_SelectedMenu", 1)
            setGlobal(state, ArcCW, "Inv_SelectedInfo", 1)
        end

        installArcCWFacade(state)

        -- ArcCW's vendor implementation checks this method during rendering
        -- and otherwise applies vendor slot/flag/ownership rules.  Keep the
        -- complete decision in F&T and expose only the four values expected
        -- by the presentation code: show, installed, blocked, show quantity.
        saveAndSet(state, "ValidateAttachment", function(_, attachment, attslot, index)
            local attachmentId = attachmentIdFor(state, attachment)
            local slotId = resolveSlotId(state, attslot,
                attachmentId ~= "" and attachmentId or nil)

            if not slotId and index ~= nil then
                slotId = resolveSlotId(state, index,
                    attachmentId ~= "" and attachmentId or nil)
            end

            if not slotId then
                return false, false, true, false
            end

            local runtime = state.swep.FTRuntime
            local installed = installedAttachments(runtime)[slotId]
            local isInstalled = attachmentId == ""
                and installed == nil or installed == attachmentId

            if attachmentId == "" then
                return true, isInstalled, false, false
            end

            local allowed = isInstalled

            if not allowed then
                allowed = canInstall(runtime, slotId, attachmentId)
            end

            if not allowed then
                return true, false, true, false
            end

            return true, isInstalled, false, false
        end)
    end,
    Open = function(state, call)
        local previousPanel = rawget(_G, "ArcCW") and ArcCW.InvHUD

        -- A panel left by another weapon must not be mistaken for the panel
        -- created by this bridge.  The vendor constructor is expected to
        -- publish a fresh ArcCW.InvHUD value.
        if ArcCW and previousPanel and valid(previousPanel)
            and previousPanel.Remove then
            pcall(previousPanel.Remove, previousPanel)
        end

        if ArcCW then
            setGlobal(state, ArcCW, "InvHUD", nil)
        end

        local ok, result = withArcCWGamemodeButtonsDisabled(function()
            return call(state, "CreateCustomize2HUD")
        end)

        local panel = ArcCW and ArcCW.InvHUD

        if not ok or not valid(panel) or panel == previousPanel then
            return false, result or "ArcCW customize panel was not created"
        end

        state.arcCWPanel = panel
        return true, result
    end,
    Close = function(state)
        local panel = state.arcCWPanel

        if not valid(panel) and ArcCW and valid(ArcCW.InvHUD) then
            panel = ArcCW.InvHUD
        end

        if valid(panel) and panel.Remove then
            state.panelRemoving = true
            pcall(panel.Remove, panel)
            state.panelRemoving = false
        end

        state.arcCWPanel = nil
    end,
    Refresh = function(state, call)
        local previousPanel = state.arcCWPanel

        if not valid(previousPanel) and ArcCW and valid(ArcCW.InvHUD) then
            previousPanel = ArcCW.InvHUD
        end

        if valid(previousPanel) and previousPanel.Remove then
            state.panelRemoving = true
            pcall(previousPanel.Remove, previousPanel)
            state.panelRemoving = false
        end

        if ArcCW and ArcCW.InvHUD == previousPanel then
            setGlobal(state, ArcCW, "InvHUD", nil)
        end

        local ok, result = withArcCWGamemodeButtonsDisabled(function()
            return call(state, "CreateCustomize2HUD")
        end)

        local panel = ArcCW and ArcCW.InvHUD

        if not ok or not valid(panel) or panel == previousPanel then
            return false, result or "ArcCW customize panel was not refreshed"
        end

        state.arcCWPanel = panel
        return true, result
    end,
    DrawHUD = function(state, call)
        return call(state, "DrawHUD")
    end
})

local MWInterceptor = {
    installed = false,
    original = nil,
    states = setmetatable({}, {__mode = "k"}),
    target = nil,
    wrapper = nil
}

local function installMWInterceptor(state)
    local target = rawget(_G, "mw_utils")

    if type(target) ~= "table"
        or type(target.SendAttachmentToServer) ~= "function" then
        return false
    end

    if MWInterceptor.target and MWInterceptor.target ~= target then
        if MWInterceptor.wrapper
            and MWInterceptor.target.SendAttachmentToServer == MWInterceptor.wrapper then
            MWInterceptor.target.SendAttachmentToServer = MWInterceptor.original
        end

        MWInterceptor.installed = false
        MWInterceptor.original = nil
        MWInterceptor.target = nil
        MWInterceptor.wrapper = nil
    end

    if not MWInterceptor.wrapper then
        MWInterceptor.target = target
        MWInterceptor.original = target.SendAttachmentToServer
        MWInterceptor.wrapper = function(weapon, slot, index)
            local stateForWeapon = routedStateFor(weapon)

            if stateForWeapon and stateForWeapon.bridge.id ~= "mw" then
                local activeState = stateFor(weapon)

                if activeState and activeState.bridge.id == "mw" then
                    stateForWeapon = activeState
                end
            end

            if stateForWeapon and stateForWeapon.open
                and stateForWeapon.bridge.id == "mw" then
                local options = weapon.Customization and weapon.Customization[slot]
                local optionIndex = tonumber(index)
                local syntheticId = options and optionIndex and options[optionIndex]

                if optionIndex == 1 then
                    syntheticId = ""
                end

                if syntheticId == nil then
                    return false
                end

                return requestAttachment(stateForWeapon, slot, syntheticId)
            end

            return MWInterceptor.original(weapon, slot, index)
        end
    end

    -- Preserve a replacement installed by another addon and delegate all
    -- non-F&T calls to it.  Our wrapper remains scoped to active bridge
    -- states and is removed as soon as the last one closes.
    if target.SendAttachmentToServer ~= MWInterceptor.wrapper then
        MWInterceptor.original = target.SendAttachmentToServer
        target.SendAttachmentToServer = MWInterceptor.wrapper
    end

    MWInterceptor.installed = true
    MWInterceptor.states[state] = true
    state.mwInterceptor = true
    return true
end

restoreMWInterceptor = function(state)
    if not MWInterceptor.installed then
        return
    end

    MWInterceptor.states[state] = nil

    for _ in pairs(MWInterceptor.states) do
        return
    end

    if MWInterceptor.target and MWInterceptor.wrapper
        and MWInterceptor.target.SendAttachmentToServer == MWInterceptor.wrapper then
        MWInterceptor.target.SendAttachmentToServer = MWInterceptor.original
    end

    MWInterceptor.installed = false
    MWInterceptor.original = nil
    MWInterceptor.target = nil
    MWInterceptor.wrapper = nil
end

UIBridge.Register("mw", {
    sampleClass = "mg_mike4",
    baseClass = "mg_base",
    uiMethods = {
        "CustomizationMenu",
        "GetStatPositive",
        "DrawStat",
        "DrawStats",
        "DrawHUD",
        "DrawFiremode",
        "DrawBipod",
        "DrawCommands",
        "CanDrawCrosshair",
        "DrawCrosshairSticks",
        "DrawUnderbarrelCrosshair",
        "Crosshair"
    },
    overlayMethods = {
        "GetStatPositive",
        "DrawStat",
        "DrawStats",
        "DrawFiremode",
        "DrawBipod",
        "CanDrawCrosshair",
        "DrawCrosshairSticks",
        "DrawUnderbarrelCrosshair",
        "Crosshair"
    },
    stateFields = {
        "Customization",
        "m_CustomizationInUse"
    },
    globalFields = {
        {target = "_G", key = "MW_CUSTOMIZEMENU"}
    },
    blockNetMessages = {
        "mgbase_customize_att"
    },
    GetRegistry = function()
        return rawget(_G, "MW_ATTS")
    end,
    IsAvailable = function()
        return type(rawget(_G, "MW_ATTS")) == "table"
            and type(rawget(_G, "mw_utils")) == "table"
            and type(rawget(_G, "mw_utils").SendAttachmentToServer) == "function",
            "MW attachment UI globals are unavailable"
    end,
    BuildDefinition = function(_, slot, option, definition, syntheticId)
        return {
            Breadcrumbs = {},
            Category = slot.name,
            ClassName = syntheticId,
            CosmeticChange = false,
            CustomText = option.description or definition.description or "",
            Icon = iconMaterial(definition, "mg/att_default"),
            Name = option.name or definition.name or option.id,
            Slot = slot.slotId,
            UIColor = Color and Color(255, 255, 255, 255) or nil
        }
    end,
    ApplySlots = function(state, slots)
        local customization = {}
        local inUse = {}
        local registry = rawget(_G, "MW_ATTS")

        for _, slot in ipairs(slots) do
            local emptyId = syntheticToken(state.swep) .. "_empty_" .. tostring(slot.index)
            local empty = {
                Breadcrumbs = {},
                Category = slot.name,
                ClassName = emptyId,
                Name = "No attachment",
                Slot = slot.slotId
            }
            registerSynthetic(state, registry, emptyId, empty, "")
            customization[slot.slotId] = {emptyId}

            for _, option in ipairs(slot.options) do
                customization[slot.slotId][#customization[slot.slotId] + 1] = option.id
            end

            local installedId = slot.installed and state.ftToSynthetic[slot.installed] or emptyId
            local installed = registry and registry[installedId] or empty
            inUse[slot.slotId] = copy(installed)
            inUse[slot.slotId].Index = 1
            inUse[slot.slotId].Slot = slot.slotId

            for optionIndex, optionId in ipairs(customization[slot.slotId]) do
                if optionId == installedId then
                    inUse[slot.slotId].Index = optionIndex
                    break
                end
            end
        end

        saveAndSet(state, "Customization", customization)
        saveAndSet(state, "m_CustomizationInUse", inUse)
        saveAndSet(state, "GetAttachmentInUseForSlot", function(_, slot)
            return inUse[slot]
        end)
        saveAndSet(state, "GetAllAttachmentsInUse", function()
            return inUse
        end)
        saveAndSet(state, "GetStoredAttachment", function(_, id)
            return registry and registry[id]
        end)
    end,
    Prepare = function(state)
        installMWInterceptor(state)
        saveAndSet(state, "HasFlag", function(_, flag)
            return normalize(flag) == "customizing" and state.open or false
        end)
        saveAndSet(state, "GetSight", function()
            return nil
        end)
        saveAndSet(state, "GetUnderbarrel", function()
            return nil
        end)
        saveAndSet(state, "GetFlashlightAttachment", function()
            return nil
        end)
        saveAndSet(state, "DrawTrackingHUD", function() end)
        saveAndSet(state, "DrawCommands", function() end)
    end,
    Open = function(state, call)
        local previousPanel = rawget(_G, "MW_CUSTOMIZEMENU")

        if valid(previousPanel) and previousPanel.Remove then
            pcall(previousPanel.Remove, previousPanel)
        end

        setGlobal(state, _G, "MW_CUSTOMIZEMENU", nil)

        local ok, result = call(state, "CustomizationMenu")
        local panel = rawget(_G, "MW_CUSTOMIZEMENU")

        if not ok or not valid(panel) or panel == previousPanel then
            return false, result or "MW customize menu was not created"
        end

        state.mwPanel = panel
        return true, result
    end,
    Close = function(state, call)
        state.open = false
        local panel = state.mwPanel

        if not valid(panel) then
            panel = rawget(_G, "MW_CUSTOMIZEMENU")
        end

        if valid(panel) and panel.Remove then
            state.panelRemoving = true
            pcall(panel.Remove, panel)
            state.panelRemoving = false
        end

        state.mwPanel = nil
    end,
    Refresh = function(state, call)
        local previousPanel = state.mwPanel

        if not valid(previousPanel) then
            previousPanel = rawget(_G, "MW_CUSTOMIZEMENU")
        end

        if valid(previousPanel) and previousPanel.Remove then
            state.panelRemoving = true
            pcall(previousPanel.Remove, previousPanel)
            state.panelRemoving = false
        end

        if rawget(_G, "MW_CUSTOMIZEMENU") == previousPanel then
            setGlobal(state, _G, "MW_CUSTOMIZEMENU", nil)
        end

        local ok, result = call(state, "CustomizationMenu")
        local panel = rawget(_G, "MW_CUSTOMIZEMENU")

        if not ok or not valid(panel) or panel == previousPanel then
            return false, result or "MW customize menu was not refreshed"
        end

        state.mwPanel = panel
        return true, result
    end,
    DrawHUD = function(state, call)
        return call(state, "DrawHUD")
    end
})

UIBridge.Register("tacrp", {
    sampleClass = "tacrp_eo_masada",
    baseClass = "tacrp_base",
    uiMethods = {
        "CreateCustomizeHUD",
        "RemoveCustomizeHUD",
        "DrawCustomizeHUD",
        "ShouldDrawCrosshair",
        "DoDrawCrosshair",
        "GetBinding",
        "ShouldDrawBottomBar",
        "DrawBottomBar",
        "DrawBreathBar",
        "DrawHUDBackground",
        "DrawWeaponSelection",
        "CustomAmmoDisplay"
    },
    overlayMethods = {
        "CreateCustomizeHUD",
        "RemoveCustomizeHUD",
        "DrawCustomizeHUD",
        "ShouldDrawCrosshair",
        "DoDrawCrosshair",
        "GetBinding",
        "ShouldDrawBottomBar",
        "DrawBottomBar",
        "DrawBreathBar",
        "DrawWeaponSelection",
        "CustomAmmoDisplay"
    },
    stateFields = {
        "Attachments",
        "CustomizeHUD",
        "StaticStats"
    },
    globalFields = {
        {target = "TacRP", key = "CursorEnabled"}
    },
    blockNetMessages = {
        "TacRP_attach",
        "TacRP_receivepreset",
        "tacrp_drop",
        "tacrp_updateslot"
    },
    GetRegistry = function()
        return TacRP and TacRP.Attachments
    end,
    BuildDefinition = function(_, slot, option, definition, syntheticId)
        return {
            Category = slot.category,
            Cons = {},
            Description = option.description or definition.description or "",
            Free = true,
            Icon = iconMaterial(definition),
            PrintName = option.name or definition.name or option.id,
            Pros = {},
            ShortName = syntheticId,
            SortOrder = 0
        }
    end,
    ApplySlots = function(state, slots)
        local projected = {}

        for _, slot in ipairs(slots) do
            projected[#projected + 1] = {
                Category = slot.category,
                Installed = slot.installed and state.ftToSynthetic[slot.installed] or nil,
                PrintName = slot.name
            }
        end

        saveAndSet(state, "Attachments", projected)
        saveAndSet(state, "Detach", function(_, slot, _, suppress)
            if suppress then
                state.pendingTacRPDetach = slot
                return true
            end

            return requestAttachment(state, slot, "")
        end)
        saveAndSet(state, "Attach", function(_, slot, attachment)
            state.pendingTacRPDetach = nil
            return requestAttachment(state, slot, attachment)
        end)
    end,
    Prepare = function(state)
        saveAndSet(state, "SavePreset", function() end)
        saveAndSet(state, "GetTactical", function()
            return false
        end)
        saveAndSet(state, "DrawScope", function() end)
        saveAndSet(state, "DrawThermal", function() end)
        saveAndSet(state, "DrawLockOnHUD", function() end)
        saveAndSet(state, "DrawGrenadeHUD", function() end)
        saveAndSet(state, "DrawBlindFireHUD", function() end)
    end,
    Open = function(state, call)
        local ok, result = call(state, "CreateCustomizeHUD")
        return ok and valid(state.swep.CustomizeHUD), result
    end,
    Close = function(state, call)
        call(state, "RemoveCustomizeHUD")
        local panel = state.swep.CustomizeHUD

        if valid(panel) and panel.Remove then
            panel:Remove()
        end
    end,
    Refresh = function(state, call)
        return call(state, "CreateCustomizeHUD")
    end,
    DrawHUD = function(state, call)
        local okBackground, resultBackground = call(state, "DrawHUDBackground")
        local okCrosshair, resultCrosshair = call(state, "DoDrawCrosshair", ScrW() / 2, ScrH() / 2)

        if not okBackground then
            return false, resultBackground
        end

        return okCrosshair, resultCrosshair
    end
})

UIBridge.Register("swb", {
    sampleClass = "swb_base",
    baseClass = "swb_base",
    uiMethods = {
        "DrawHUD"
    },
    blockNetMessages = {
        "SWB_FIREMODE"
    },
    GetRegistry = function()
        return nil
    end,
    BuildDefinition = defaultDefinition,
    ApplySlots = function() end,
    DrawHUD = function(state)
        local method = state.vendorMethods.DrawHUD

        if type(method) ~= "function" then
            return false, "missing SWB DrawHUD"
        end

        local runtime = type(state.swep.FTRuntime) == "table"
            and state.swep.FTRuntime or {}
        local ir = effectiveIR(state.swep)

        if type(ir) ~= "table" then
            ir = {}
        end

        local ui = type(ir.ui) == "table" and ir.ui or {}
        local spread = type(ir.spread) == "table" and ir.spread or {}
        local fire = type(ir.fire) == "table" and ir.fire or {}
        local owner = state.swep.GetOwner and state.swep:GetOwner()
        local facade = {
            AimTime = 0,
            BulletDisplay = math.max(0, state.swep.Clip1 and state.swep:Clip1() or 0),
            CrossAlpha = 255,
            CrossAmount = 0,
            CrosshairEnabled = ui.crosshair ~= false,
            CrosshairParts = {left = true, right = true, upper = true, lower = true},
            CurCone = tonumber(runtime.aiming and spread.ads or spread.hip) or 0,
            CurFOVMod = 0,
            Cycle = 1,
            FadeAlpha = 0,
            FireModeDisplay = fire.automatic and "AUTO" or "SEMI",
            IsFiddlingWithSuppressor = false,
            IsReloading = runtime.reloading,
            Owner = owner,
            dt = {
                Safe = false,
                State = runtime.aiming and (rawget(_G, "SWB_AIMING") or 2) or (rawget(_G, "SWB_IDLE") or 0)
            }
        }

        return pcall(method, facade)
    end
})

FTBase.Runtime.UIBridge = UIBridge
