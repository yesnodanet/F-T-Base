FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Parser = {}
Parser.__index = Parser

function Parser.New(tokens, report)
    return setmetatable({
        tokens = tokens,
        index = 1,
        report = report or FTBase.Report.New("parse")
    }, Parser)
end

function Parser:Token(offset)
    return self.tokens[self.index + (offset or 0)] or self.tokens[#self.tokens]
end

function Parser:Advance()
    local token = self:Token()
    self.index = self.index + 1
    return token
end

function Parser:Check(typeName, value)
    local token = self:Token()

    if token.type ~= typeName then
        return false
    end

    if value ~= nil and token.value ~= value then
        return false
    end

    return true
end

function Parser:Match(typeName, value)
    if self:Check(typeName, value) then
        return self:Advance()
    end

    return nil
end

function Parser:Error(message, token)
    token = token or self:Token()
    self.report:AddError(message .. " at " .. tostring(token.line) .. ":" .. tostring(token.column), token)
end

function Parser:Synchronize()
    while not self:Check("eof") do
        if self:Match("symbol", ";") or self:Match("symbol", "\n") then
            return
        end

        if self:Check("identifier") and self:Token(1).value == "." then
            return
        end

        self:Advance()
    end
end

function Parser:ParsePath()
    local token = self:Match("identifier")

    if not token then
        self:Error("Expected identifier")
        return nil
    end

    local path = { token.value }

    while self:Match("symbol", ".") do
        local segment = self:Match("identifier")

        if not segment then
            self:Error("Expected path segment")
            return path
        end

        path[#path + 1] = segment.value
    end

    return path, token
end

function Parser:ParseCall(name)
    local args = {}

    self:Match("symbol", "(")

    while not self:Check("eof") and not self:Check("symbol", ")") do
        args[#args + 1] = self:ParseValue()

        if not self:Match("symbol", ",") then
            break
        end
    end

    if not self:Match("symbol", ")") then
        self:Error("Expected ')' after call")
    end

    if name == "Vector" then
        return {
            __type = "Vector",
            x = tonumber(args[1]) or 0,
            y = tonumber(args[2]) or 0,
            z = tonumber(args[3]) or 0
        }
    end

    if name == "Angle" then
        return {
            __type = "Angle",
            p = tonumber(args[1]) or 0,
            y = tonumber(args[2]) or 0,
            r = tonumber(args[3]) or 0
        }
    end

    return {
        __type = "Call",
        name = name,
        args = args
    }
end

function Parser:ParseTableKey()
    if self:Match("symbol", "[") then
        local key = self:ParseValue()

        if not self:Match("symbol", "]") then
            self:Error("Expected ']' after table key")
        end

        if not self:Match("symbol", "=") then
            self:Error("Expected '=' after table key")
        end

        return key, true
    end

    if self:Check("identifier") and self:Token(1).type == "symbol" and self:Token(1).value == "=" then
        local key = self:Advance().value
        self:Match("symbol", "=")
        return key, true
    end

    return nil, false
end

function Parser:ParseTable()
    local result = {}
    local arrayIndex = 1

    self:Match("symbol", "{")

    while not self:Check("eof") and not self:Check("symbol", "}") do
        local key, hasKey = self:ParseTableKey()
        local value = self:ParseValue()

        if hasKey then
            result[key] = value
        else
            result[arrayIndex] = value
            arrayIndex = arrayIndex + 1
        end

        if not (self:Match("symbol", ",") or self:Match("symbol", ";")) then
            if not self:Check("symbol", "}") then
                self:Error("Expected ',' or '}' in table")
                self:Synchronize()
                break
            end
        end
    end

    if not self:Match("symbol", "}") then
        self:Error("Expected '}' after table")
    end

    return result
end

function Parser:ParseValue()
    if self:Match("symbol", "-") then
        if self:Check("number") then
            return -self:Advance().value
        end

        self:Error("Expected number after '-'")
        return 0
    end

    if self:Check("string") or self:Check("number") then
        return self:Advance().value
    end

    if self:Match("symbol", "{") then
        self.index = self.index - 1
        return self:ParseTable()
    end

    if self:Check("identifier") then
        local token = self:Advance()

        if token.value == "true" then
            return true
        end

        if token.value == "false" then
            return false
        end

        if token.value == "nil" then
            return nil
        end

        if self:Check("symbol", "(") then
            return self:ParseCall(token.value)
        end

        return {
            __type = "Symbol",
            name = token.value
        }
    end

    self:Error("Expected value")
    self:Advance()
    return nil
end

function Parser:ParseUsing(token)
    local stringToken = self:Match("string")

    if not stringToken then
        self:Error("Expected namespace string after using", token)
        return nil
    end

    return {
        type = "using",
        namespace = stringToken.value,
        token = token
    }
end

function Parser:ParseAssignment()
    local path, token = self:ParsePath()

    if not path then
        return nil
    end

    if not self:Match("symbol", "=") then
        self:Error("Expected '=' after path", token)
        return nil
    end

    return {
        type = "assign",
        path = path,
        value = self:ParseValue(),
        token = token
    }
end

function Parser:Parse()
    local ast = {
        type = "weapon",
        body = {}
    }

    while not self:Check("eof") do
        local node = nil

        if self:Check("identifier", "using") then
            node = self:ParseUsing(self:Advance())
        elseif self:Check("identifier") then
            node = self:ParseAssignment()
        else
            self.report:AddIgnored("Ignored token '" .. tostring(self:Token().value) .. "'", self:Token())
            self:Advance()
        end

        if node then
            ast.body[#ast.body + 1] = node
        else
            self:Synchronize()
        end

        self:Match("symbol", ";")
    end

    return ast, self.report
end

function FTBase.Compiler.Parse(source, name, report)
    local tokens = FTBase.Compiler.Lex(source, name)
    return Parser.New(tokens, report):Parse()
end

FTBase.Compiler.Parser = Parser
