-- GMod Lua smoke test. Run after F&T Base is loaded.

local source = [[
using "TFA"
using "ARC9"
using "MW"

FT.Priority = { "ARC9", "MW", "TFA" }
TFA.Primary.Damage = 35
TFA.Primary.ClipSize = 30
TFA.Primary.Sound = "Weapon_AR2.Single"
ARC9.Recoil.Up = 0.8
MW.Camera.Shake = 0.35
FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1}
}
]]

local result = FTBase.Compiler.CompileSource(source, {
    name = "ft_smoke_test"
})

print(result.report:ToString())

if result.report:HasErrors() then
    error("F&T smoke test failed")
end

print("F&T smoke test damage:", result.ir.damage.base)
print("F&T smoke test recoil entries:", #result.ir.recoil.pattern)

return result
