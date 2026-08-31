FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

local Parser = {}
Parser.__index = Parser

local function hasThreeFiniteNumbers(args)
    if #args ~= 3 then
        return false
    end

    for index = 1, 3 do
        local value = args[index]

        if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
            return false
        end
    end

    return true
end

function Parser.New(tokens, report)
    local parser = setmetatable({
        tokens = tokens,
        index = 1,
        report = report or FTBase.Report.New("parse"),
        nodeCount = 1,
        tableDepth = 0,
        aborted = false,
        lexerErrorsReported = false,
        nodeLimitReported = false
    }, Parser)

    return parser
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
    self.report:AddError(
        message .. " at " .. tostring(token.source or "<source>") .. ":"
            .. tostring(token.line) .. ":" .. tostring(token.column),
        token
    )
end

function Parser:CountNode(token)
    if self.aborted then
        return false
    end

    if self.nodeCount >= FTBase.Compiler.Limits.maxASTNodes then
        if not self.nodeLimitReported then
            self.nodeLimitReported = true
            self:Error(
                "AST node limit exceeded (maximum " .. tostring(FTBase.Compiler.Limits.maxASTNodes) .. ")",
                token
            )
        end

        self.aborted = true
        return false
    end

    self.nodeCount = self.nodeCount + 1
    return true
end

function Parser:ReportLexerErrors()
    if self.lexerErrorsReported then
        return
    end

    self.lexerErrorsReported = true

    for _, token in ipairs(self.tokens or {}) do
        if token.type == "error" then
            self:Error(tostring(token.value or "Lexer error"), token)
        end
    end
end

function Parser:SkipBalanced(openValue, closeValue)
    local depth = 1

    while not self:Check("eof") and depth > 0 do
        local token = self:Advance()

        if token.type == "symbol" and token.value == openValue then
            depth = depth + 1
        elseif token.type == "symbol" and token.value == closeValue then
            depth = depth - 1
        end
    end
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
        local segment = self:Match("identifier") or self:Match("number")

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
        if not hasThreeFiniteNumbers(args) then
            self:Error("Vector expects exactly 3 finite numeric arguments")
        end

        return {
            __type = "Vector",
            x = args[1],
            y = args[2],
            z = args[3]
        }
    end

    if name == "Angle" then
        if not hasThreeFiniteNumbers(args) then
            self:Error("Angle expects exactly 3 finite numeric arguments")
        end

        return {
            __type = "Angle",
            p = args[1],
            y = args[2],
            r = args[3]
        }
    end

    self:Error("Unknown call '" .. tostring(name) .. "'")

    return {
        __type = "Call",
        name = name,
        args = args
    }
end

function Parser:ParseValue()
    if not self:CountNode(self:Token()) then
        return nil
    end

    if self:Match("symbol", "-") then
        if self:Check("number") then
            return -self:Advance().value
        end

        self:Error("Expected number after '-'")
        return 0
    end

    if self:Match("symbol", "+") then
        if self:Check("number") then
            return self:Advance().value
        end

        self:Error("Expected number after '+'")
        return 0
    end

    if self:Check("string") or self:Check("number") then
        return self:Advance().value
    end

    if self:Check("symbol", "{") then
        if self.tableDepth >= FTBase.Compiler.Limits.maxDepth then
            local token = self:Advance()
            self:Error(
                "Maximum table nesting depth exceeded (maximum " .. tostring(FTBase.Compiler.Limits.maxDepth) .. ")",
                token
            )
            self:SkipBalanced("{", "}")
            return {}
        end

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
            return {
                __type = "Nil"
            }
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
    self.tableDepth = self.tableDepth + 1

    while not self.aborted and not self:Check("eof") and not self:Check("symbol", "}") do
        local key, hasKey = self:ParseTableKey()
        local value = self:ParseValue()

        if hasKey then
            if key == nil then
                self:Error("Table key cannot be nil")
            else
                result[key] = value
            end
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
        if not self.aborted then
            self:Error("Expected '}' after table")
        end
    end

    self.tableDepth = math.max(0, self.tableDepth - 1)

    return result
end

function Parser:ParseUsing(token)
    if not self:CountNode(token) then
        return nil
    end

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

    if not self:CountNode(token) then
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
    self:ReportLexerErrors()

    local ast = {
        type = "weapon",
        body = {}
    }

    if self.report:HasErrors() then
        return ast, self.report
    end

    while not self.aborted and not self:Check("eof") do
        local node = nil

        if self:Check("identifier", "using") then
            node = self:ParseUsing(self:Advance())
        elseif self:Check("identifier") then
            node = self:ParseAssignment()
        elseif self:Check("error") then
            -- Lexer errors are reported once up front.  Consume the token so
            -- parser recovery cannot turn it into an ignored statement.
            self:Advance()
        elseif self:Check("symbol", ";") then
            -- Semicolons are a supported legacy statement separator.
            self:Advance()
        else
            self:Error("Unexpected token '" .. tostring(self:Token().value) .. "'")
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
