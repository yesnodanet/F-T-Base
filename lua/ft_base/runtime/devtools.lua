FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local DevTools = FTBase.Module.Define("DeveloperTools", {})

function DevTools.PrintReport(className)
    local record = FTBase.WeaponRegistry.Get(className)

    if not record or not record.report then
        print("[F&T] No compile report for " .. tostring(className))
        return
    end

    print(record.report:ToString())
end

function DevTools.GenerateDocumentation(ir)
    local lines = {}

    lines[#lines + 1] = "# " .. tostring(ir.meta.printName or ir.meta.id or "Weapon")
    lines[#lines + 1] = ""
    lines[#lines + 1] = "- Damage: " .. tostring(ir.damage.base)
    lines[#lines + 1] = "- RPM: " .. tostring(ir.fire.rpm)
    lines[#lines + 1] = "- Ballistics: " .. tostring(ir.ballistics.mode)
    lines[#lines + 1] = "- Attachments: " .. tostring(#(ir.attachments.slots or {}))

    return table.concat(lines, "\n")
end

if concommand then
    concommand.Add("ft_report", function(ply, cmd, args)
        if IsValid and IsValid(ply) and not ply:IsAdmin() then
            return
        end

        DevTools.PrintReport(args and args[1] or "")
    end)

    concommand.Add("ft_debug", function(ply, cmd, args)
        if IsValid and IsValid(ply) and not ply:IsAdmin() then
            return
        end

        FTBase.Runtime.Debug.SetEnabled(args and args[1] == "1")
    end)
end

FTBase.Runtime.DevTools = DevTools
