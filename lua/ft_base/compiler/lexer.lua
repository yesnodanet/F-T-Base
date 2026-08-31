FTBase = FTBase or {}
FTBase.Compiler = FTBase.Compiler or {}

-- Keep parser/compiler limits in one place.  The values are deliberately
-- conservative because compiler input can come from workshop content.
FTBase.Compiler.Limits = FTBase.Compiler.Limits or {
    maxSourceBytes = 256 * 1024,
    maxTokens = 20000,
    maxASTNodes = 10000,
    maxDepth = 64,
    maxAttachmentSlots = 64,
    maxAttachmentDefinitions = 256
}

local Lexer = {}
Lexer.__index = Lexer

local function isWhitespace(char)
    return char == " " or char == "\t" or char == "\r" or char == "\n"
end

local function isDigit(char)
    return char and string.match(char, "%d") ~= nil
end

local function isHexDigit(char)
    return char and string.match(char, "[%da-fA-F]") ~= nil
end

local function isIdentifierStart(char)
    return char and string.match(char, "[A-Za-z_]") ~= nil
end

local function isIdentifierPart(char)
    return char and string.match(char, "[A-Za-z0-9_]") ~= nil
end

function Lexer.New(source, name)
    local sourceType = type(source)

    return setmetatable({
        source = sourceType == "string" and source or "",
        name = name or "<source>",
        index = 1,
        line = 1,
        column = 1,
        tokens = {},
        tokenLimitReported = false,
        sourceLimitReported = false,
        invalidSource = source ~= nil and sourceType ~= "string"
    }, Lexer)
end

function Lexer:Char(offset)
    offset = offset or 0
    return string.sub(self.source, self.index + offset, self.index + offset)
end

function Lexer:Advance()
    local char = self:Char()
    self.index = self.index + 1

    if char == "\n" then
        self.line = self.line + 1
        self.column = 1
    else
        self.column = self.column + 1
    end

    return char
end

function Lexer:Add(typeName, value, line, column)
    -- EOF must always be emitted, even when the input reached the token cap;
    -- Parser:Token relies on it for a bounded recovery loop.
    if typeName == "eof" then
        self.tokens[#self.tokens + 1] = {
            type = typeName,
            value = value,
            line = line or self.line,
            column = column or self.column,
            source = self.name
        }
        return true
    end

    if #self.tokens >= FTBase.Compiler.Limits.maxTokens then
        if not self.tokenLimitReported then
            self.tokenLimitReported = true
            self.tokens[#self.tokens + 1] = {
                type = "error",
                value = "Token limit exceeded (maximum " .. tostring(FTBase.Compiler.Limits.maxTokens) .. ")",
                line = line or self.line,
                column = column or self.column,
                source = self.name
            }
        end

        return false
    end

    self.tokens[#self.tokens + 1] = {
        type = typeName,
        value = value,
        line = line or self.line,
        column = column or self.column,
        source = self.name
    }
end

function Lexer:SkipWhitespace()
    while self.index <= #self.source and isWhitespace(self:Char()) do
        self:Advance()
    end
end

function Lexer:SkipComment()
    if self:Char() ~= "-" or self:Char(1) ~= "-" then
        return false
    end

    while self.index <= #self.source and self:Char() ~= "\n" do
        self:Advance()
    end

    return true
end

function Lexer:ReadString()
    local quote = self:Advance()
    local line = self.line
    local column = self.column - 1
    local value = {}

    while self.index <= #self.source do
        local char = self:Advance()

        if char == quote then
            self:Add("string", table.concat(value), line, column)
            return
        end

        if char == "\\" then
            local escaped = self:Advance()

            if escaped == "n" then
                value[#value + 1] = "\n"
            elseif escaped == "t" then
                value[#value + 1] = "\t"
            elseif escaped == "r" then
                value[#value + 1] = "\r"
            else
                value[#value + 1] = escaped
            end
        else
            value[#value + 1] = char
        end
    end

    self:Add("error", "Unterminated string", line, column)
end

function Lexer:ReadNumber()
    local line = self.line
    local column = self.column
    local value = {}

    if self:Char() == "0" and (self:Char(1) == "x" or self:Char(1) == "X") then
        value[#value + 1] = self:Advance()
        value[#value + 1] = self:Advance()

        local hexDigits = 0

        while self.index <= #self.source and isHexDigit(self:Char()) do
            value[#value + 1] = self:Advance()
            hexDigits = hexDigits + 1
        end

        if hexDigits == 0 then
            self:Add("error", "Malformed hexadecimal number", line, column)
            return
        end

        if isIdentifierPart(self:Char()) then
            while self.index <= #self.source and isIdentifierPart(self:Char()) do
                self:Advance()
            end

            self:Add("error", "Malformed hexadecimal number", line, column)
            return
        end

        if self:Char() == "." then
            self:Advance()
            self:Add("error", "Malformed hexadecimal number", line, column)
            return
        end

        local number = tonumber(table.concat(value))

        if number == nil or number ~= number or number == math.huge or number == -math.huge then
            self:Add("error", "Malformed hexadecimal number", line, column)
        else
            self:Add("number", number, line, column)
        end
        return
    end

    local hasDigits = false
    local hasDot = false

    while self.index <= #self.source do
        local char = self:Char()

        if isDigit(char) then
            hasDigits = true
        elseif char == "." and not hasDot then
            hasDot = true
        elseif (char == "e" or char == "E") and hasDigits then
            value[#value + 1] = self:Advance()

            if self:Char() == "+" or self:Char() == "-" then
                value[#value + 1] = self:Advance()
            end

            local exponentDigits = 0

            while self.index <= #self.source and isDigit(self:Char()) do
                value[#value + 1] = self:Advance()
                exponentDigits = exponentDigits + 1
            end

            if exponentDigits == 0 then
                self:Add("error", "Malformed number exponent", line, column)
                return
            end

            break
        else
            break
        end

        value[#value + 1] = self:Advance()
    end

    if not hasDigits then
        self:Add("error", "Malformed number", line, column)
        return
    end

    if self:Char() == "." then
        -- A second dot cannot be part of a number.  Consuming it here keeps
        -- the parser from interpreting `1.2.3` as two unrelated statements.
        self:Advance()
        self:Add("error", "Malformed number", line, column)
        return
    end

    if isIdentifierStart(self:Char()) then
        while self.index <= #self.source and isIdentifierPart(self:Char()) do
            self:Advance()
        end

        self:Add("error", "Malformed number", line, column)
        return
    end

    local number = tonumber(table.concat(value))

    if number == nil or number ~= number or number == math.huge or number == -math.huge then
        self:Add("error", "Malformed number", line, column)
    else
        self:Add("number", number, line, column)
    end
end

function Lexer:ReadIdentifier()
    local line = self.line
    local column = self.column
    local value = {}

    while self.index <= #self.source and isIdentifierPart(self:Char()) do
        value[#value + 1] = self:Advance()
    end

    self:Add("identifier", table.concat(value), line, column)
end

function Lexer:Tokenize()
    local previousIndex = 0

    if self.invalidSource then
        self:Add("error", "Source must be a string", 1, 1)
        self:Add("eof", "", 1, 1)
        return self.tokens
    end

    if #self.source > FTBase.Compiler.Limits.maxSourceBytes then
        self.sourceLimitReported = true
        self:Add(
            "error",
            "Source exceeds maximum size of " .. tostring(FTBase.Compiler.Limits.maxSourceBytes) .. " bytes",
            1,
            1
        )
        self:Add("eof", "", 1, 1)
        return self.tokens
    end

    while self.index <= #self.source do
        if self.tokenLimitReported then
            self:Add("eof", "", self.line, self.column)
            return self.tokens
        end

        self:SkipWhitespace()

        if self.index > #self.source then
            break
        end

        if self.index == previousIndex then
            self:Add("error", "Lexer made no progress", self.line, self.column)
            self:Advance()
        end

        previousIndex = self.index

        if self:SkipComment() then
            self:SkipWhitespace()
        end

        if self.index > #self.source then
            break
        end

        local char = self:Char()
        local line = self.line
        local column = self.column

        if char == "\"" or char == "'" then
            self:ReadString()
        elseif isDigit(char) then
            self:ReadNumber()
        elseif isIdentifierStart(char) then
            self:ReadIdentifier()
        else
            self:Add("symbol", self:Advance(), line, column)
        end
    end

    self:Add("eof", "", self.line, self.column)
    return self.tokens
end

function FTBase.Compiler.Lex(source, name)
    return Lexer.New(source, name):Tokenize()
end

FTBase.Compiler.Lexer = Lexer
