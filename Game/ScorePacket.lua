local ScorePacket = {}
local _, addon = ...

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local CHECKSUM_SALT = "BetterBejeweled:score:v1"
local MAX_SCORE = 999999999
local MAX_LEVEL = 99999

local decodeValues = {}
for index = 1, #ALPHABET do
    decodeValues[string.sub(ALPHABET, index, index)] = index - 1
end

local function isInteger(value)
    return type(value) == "number"
        and value >= 0
        and value == math.floor(value)
end

local function isValidId(value)
    return type(value) == "string"
        and #value >= 8
        and #value <= 32
        and string.match(value, "^[%w]+$") ~= nil
end

local function isValidData(data)
    return type(data) == "table"
        and isValidId(data.accountId)
        and isValidId(data.sessionId)
        and isInteger(data.sequence)
        and data.sequence >= 1
        and data.sequence <= 2147483647
        and isInteger(data.score)
        and data.score <= MAX_SCORE
        and isInteger(data.level)
        and data.level >= 1
        and data.level <= MAX_LEVEL
        and type(data.name) == "string"
        and #data.name >= 1
        and #data.name <= 64
        and not string.find(data.name, "|", 1, true)
        and type(data.guid) == "string"
        and #data.guid <= 64
        and string.match(data.guid, "^Player%-%w+%-%w+$") ~= nil
end

local function checksum(value)
    local hash = 5381
    local salted = CHECKSUM_SALT .. value

    for index = 1, #salted do
        hash = (hash * 33 + string.byte(salted, index)) % 2147483647
    end

    return math.floor(hash)
end

local function base64Encode(value)
    local encoded = {}

    for index = 1, #value, 3 do
        local first = string.byte(value, index)
        local second = string.byte(value, index + 1)
        local third = string.byte(value, index + 2)
        local combined = first * 65536
            + (second or 0) * 256
            + (third or 0)

        local firstIndex = math.floor(combined / 262144) % 64 + 1
        local secondIndex = math.floor(combined / 4096) % 64 + 1
        local thirdIndex = math.floor(combined / 64) % 64 + 1
        local fourthIndex = combined % 64 + 1

        encoded[#encoded + 1] = string.sub(ALPHABET, firstIndex, firstIndex)
        encoded[#encoded + 1] = string.sub(ALPHABET, secondIndex, secondIndex)
        encoded[#encoded + 1] = second
            and string.sub(ALPHABET, thirdIndex, thirdIndex)
            or "="
        encoded[#encoded + 1] = third
            and string.sub(ALPHABET, fourthIndex, fourthIndex)
            or "="
    end

    return table.concat(encoded)
end

local function base64Decode(value)
    if type(value) ~= "string" or #value % 4 ~= 0 then
        return nil
    end

    local decoded = {}

    for index = 1, #value, 4 do
        local firstCharacter = string.sub(value, index, index)
        local secondCharacter = string.sub(value, index + 1, index + 1)
        local thirdCharacter = string.sub(value, index + 2, index + 2)
        local fourthCharacter = string.sub(value, index + 3, index + 3)
        local first = decodeValues[firstCharacter]
        local second = decodeValues[secondCharacter]
        local third = thirdCharacter == "=" and 0 or decodeValues[thirdCharacter]
        local fourth = fourthCharacter == "=" and 0 or decodeValues[fourthCharacter]

        if first == nil or second == nil or third == nil or fourth == nil then
            return nil
        end

        local combined = first * 262144 + second * 4096 + third * 64 + fourth
        decoded[#decoded + 1] = string.char(math.floor(combined / 65536) % 256)

        if thirdCharacter ~= "=" then
            decoded[#decoded + 1] = string.char(math.floor(combined / 256) % 256)
        end

        if fourthCharacter ~= "=" then
            decoded[#decoded + 1] = string.char(combined % 256)
        end
    end

    return table.concat(decoded)
end

function ScorePacket.Encode(data)
    if not isValidData(data) then
        return nil
    end

    local body = table.concat({
        "1",
        data.accountId,
        data.sessionId,
        data.sequence,
        data.score,
        data.level,
        data.guid,
        data.name,
    }, "|")
    local serialized = body .. "|" .. checksum(body)

    local encoded = "B1:" .. base64Encode(serialized)
    if #encoded > 255 then
        return nil
    end

    return encoded
end

function ScorePacket.Decode(encoded)
    if type(encoded) ~= "string" or string.sub(encoded, 1, 3) ~= "B1:" then
        return nil
    end

    local serialized = base64Decode(string.sub(encoded, 4))
    if not serialized then
        return nil
    end

    local version, accountId, sessionId, sequence, score, level, guid,
        name, sentChecksum = string.match(
            serialized,
            "^(%d+)|([^|]+)|([^|]+)|(%d+)|(%d+)|(%d+)|([^|]+)|([^|]+)|(%d+)$"
        )
    if version ~= "1" then
        return nil
    end

    local body = table.concat({
        version,
        accountId,
        sessionId,
        sequence,
        score,
        level,
        guid,
        name,
    }, "|")
    if tostring(checksum(body)) ~= sentChecksum then
        return nil
    end

    local data = {
        accountId = accountId,
        sessionId = sessionId,
        sequence = tonumber(sequence),
        score = tonumber(score),
        level = tonumber(level),
        guid = guid,
        name = name,
    }

    return isValidData(data) and data or nil
end

if type(addon) == "table" then
    addon.ScorePacket = ScorePacket
end

return ScorePacket
