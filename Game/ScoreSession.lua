local ScoreSession = {}
ScoreSession.__index = ScoreSession

local _, addon = ...

local function hasId(value)
    return type(value) == "string"
        and #value >= 8
        and #value <= 32
        and string.match(value, "^[%w]+$") ~= nil
end

function ScoreSession.New(savedData, api)
    if not hasId(savedData.publicAccountId) then
        savedData.publicAccountId = api.generateId()
    end

    if not hasId(savedData.scoreSessionId) then
        savedData.scoreSessionId = api.generateId()
    end

    savedData.scoreSequence = math.max(
        0,
        math.floor(tonumber(savedData.scoreSequence) or 0)
    )

    return setmetatable({
        savedData = savedData,
        api = api,
        accountId = savedData.publicAccountId,
        sessionId = savedData.scoreSessionId,
        sequence = savedData.scoreSequence,
    }, ScoreSession)
end

function ScoreSession:CreateScoreData(name, guid, score, level)
    self.sequence = self.sequence + 1
    self.savedData.scoreSequence = self.sequence

    return {
        accountId = self.accountId,
        sessionId = self.sessionId,
        sequence = self.sequence,
        name = name,
        guid = guid,
        score = score,
        level = level,
    }
end

function ScoreSession:StartNewGame()
    self.sessionId = self.api.generateId()
    self.sequence = 0
    self.savedData.scoreSessionId = self.sessionId
    self.savedData.scoreSequence = 0
end

if type(addon) == "table" then
    addon.ScoreSession = ScoreSession
end

return ScoreSession
