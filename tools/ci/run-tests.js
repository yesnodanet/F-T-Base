"use strict";

const fs = require("fs");
const path = require("path");
const luaparse = require("luaparse");
const {
    lua,
    lauxlib,
    lualib,
    to_luastring: toLuaString,
    to_jsstring: toJsString
} = require("fengari");

const root = path.resolve(__dirname, "..", "..");

function findLuaFiles(directory, output = []) {
    for (const entry of fs.readdirSync(directory, {withFileTypes: true}).sort((left, right) => left.name.localeCompare(right.name))) {
        if (entry.name === ".git" || entry.name === "node_modules" || entry.name === "third_party") {
            continue;
        }

        const target = path.join(directory, entry.name);

        if (entry.isDirectory()) {
            findLuaFiles(target, output);
        } else if (entry.isFile() && entry.name.endsWith(".lua")) {
            output.push(target);
        }
    }

    return output;
}

function checkSyntax(files) {
    const failures = [];

    for (const file of files) {
        try {
            luaparse.parse(fs.readFileSync(file, "utf8"), {
                comments: false,
                luaVersion: "5.1"
            });
        } catch (error) {
            failures.push(`${path.relative(root, file)}: ${error.message}`);
        }
    }

    if (failures.length > 0) {
        throw new Error(`Lua syntax check failed:\n${failures.join("\n")}`);
    }

    process.stdout.write(`Lua syntax OK: ${files.length} files\n`);
}

function runHeadlessTests() {
    const state = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(state);

    function topMessage() {
        const value = lua.lua_tostring(state, -1);
        return value ? toJsString(value) : "<non-string Lua error>";
    }

    function runCode(source, name) {
        let status = lauxlib.luaL_loadbuffer(
            state,
            toLuaString(source),
            null,
            toLuaString(`@${name}`)
        );

        if (status !== lua.LUA_OK) {
            throw new Error(`Unable to load ${name}: ${topMessage()}`);
        }

        status = lua.lua_pcall(state, 0, 0, 0);

        if (status !== lua.LUA_OK) {
            throw new Error(`Lua test failed in ${name}: ${topMessage()}`);
        }
    }

    function runFile(file) {
        runCode(fs.readFileSync(file, "utf8"), path.relative(root, file).replaceAll("\\", "/"));
    }

    lua.lua_pushjsfunction(state, currentState => {
        const requested = toJsString(lua.lua_tostring(currentState, 1));
        const candidates = [
            path.join(root, "lua", requested),
            path.join(root, requested)
        ];
        const included = candidates.find(candidate => fs.existsSync(candidate));

        if (!included) {
            return lauxlib.luaL_error(currentState, toLuaString(`include not found: ${requested}`));
        }

        try {
            runFile(included);
            return 0;
        } catch (error) {
            return lauxlib.luaL_error(currentState, toLuaString(error.message));
        }
    });
    lua.lua_setglobal(state, toLuaString("include"));

    runCode(`
SERVER = false
CLIENT = false

function IsValid(value)
    return value ~= nil and value ~= false and not value.__invalid
end

local builtinType = type
local vectorMeta = {}
local angleMeta = {}

function Vector(x, y, z)
    return setmetatable({x = x or 0, y = y or 0, z = z or 0}, vectorMeta)
end

function Angle(p, y, r)
    return setmetatable({p = p or 0, y = y or 0, r = r or 0}, angleMeta)
end

function isvector(value)
    return builtinType(value) == "table" and getmetatable(value) == vectorMeta
end

function isangle(value)
    return builtinType(value) == "table" and getmetatable(value) == angleMeta
end

function type(value)
    if isvector(value) then
        return "Vector"
    end

    if isangle(value) then
        return "Angle"
    end

    return builtinType(value)
end

function Color(r, g, b, a)
    return {r = r, g = g, b = b, a = a or 255}
end

vectorMeta.__add = function(left, right)
    return Vector(left.x + right.x, left.y + right.y, left.z + right.z)
end

vectorMeta.__sub = function(left, right)
    return Vector(left.x - right.x, left.y - right.y, left.z - right.z)
end

vectorMeta.__mul = function(left, right)
    if builtinType(left) == "number" then
        return Vector(left * right.x, left * right.y, left * right.z)
    end

    return Vector(left.x * right, left.y * right, left.z * right)
end

vectorMeta.__index = {
    Distance = function(left, right)
        local x = left.x - right.x
        local y = left.y - right.y
        local z = left.z - right.z
        return math.sqrt(x * x + y * y + z * z)
    end,
    LengthSqr = function(value)
        return value.x * value.x + value.y * value.y + value.z * value.z
    end,
    GetNormalized = function(value)
        local length = math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)

        if length == 0 then
            return Vector()
        end

        return Vector(value.x / length, value.y / length, value.z / length)
    end,
    Angle = function()
        return Angle()
    end
}

angleMeta.__add = function(left, right)
    return Angle(left.p + right.p, left.y + right.y, left.r + right.r)
end
`, "tools/ci/headless-gmod-stubs.lua");

    runFile(path.join(root, "lua", "ft_base", "bootstrap.lua"));

    for (const test of [
        "lua/ft_base/tests/smoke.lua",
        "lua/ft_base/tests/core_regression.lua",
        "lua/ft_base/tests/runtime_regression.lua",
        "lua/ft_base/tests/templates.lua",
        "tools/ft_smoke_test.lua"
    ]) {
        runFile(path.join(root, test));
    }
}

try {
    checkSyntax(findLuaFiles(root));
    runHeadlessTests();
    process.stdout.write("F&T headless test suite passed\n");
} catch (error) {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exitCode = 1;
}
