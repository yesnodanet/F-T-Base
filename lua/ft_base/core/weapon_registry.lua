FTBase = FTBase or {}

local Registry = {
    weapons = {}
}

function Registry.Register(className, ir, report)
    Registry.weapons[className] = {
        ir = FTBase.IR.Clone(ir),
        report = report
    }

    return Registry.weapons[className]
end

function Registry.Get(className)
    return Registry.weapons[className]
end

function Registry.GetAll()
    return Registry.weapons
end

FTBase.WeaponRegistry = Registry
