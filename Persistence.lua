local _, addon = ...
local Board = type(addon) == "table" and addon.Board
    or require("Game.Board")
local ScorePacket = type(addon) == "table" and addon.ScorePacket
    or require("Game.ScorePacket")
local LeaderboardStore = type(addon) == "table" and addon.LeaderboardStore
    or require("Game.LeaderboardStore")
local PublicLeaderboardSeeds = type(addon) == "table"
        and addon.PublicLeaderboardSeeds
    or require("Game.PublicLeaderboardSeeds")
local Persistence = {}

function Persistence.SelectSavedData(currentData, legacyData)
    if type(currentData) == "table" then
        return currentData
    end

    return legacyData
end

local function recordEncoded(store, savedEntry)
    if type(savedEntry) ~= "table"
        or type(savedEntry.encoded) ~= "string" then
        return
    end

    local scoreData = ScorePacket.Decode(savedEntry.encoded)
    if scoreData then
        store:Record(
            scoreData,
            savedEntry.encoded,
            tonumber(savedEntry.updatedAt) or 0
        )
    end
end

local function normalizeTopScores(savedEntries, seedEntries)
    local entries = {}
    local store = LeaderboardStore.New(entries, 10)

    if type(savedEntries) == "table" then
        for _, savedEntry in pairs(savedEntries) do
            recordEncoded(store, savedEntry)
        end
    end

    if type(seedEntries) == "table" then
        for _, seedEntry in ipairs(seedEntries) do
            recordEncoded(store, seedEntry)
        end
    end

    return entries
end

local function isValidBoard(board)
    if type(board) ~= "table" or #board ~= 8 then
        return false
    end

    for row = 1, 8 do
        if type(board[row]) ~= "table" or #board[row] ~= 8 then
            return false
        end

        for column = 1, 8 do
            local cell = board[row][column]
            if type(cell) ~= "table"
                or type(cell.gemType) ~= "number"
                or cell.gemType < 1
                or cell.gemType > 7 then
                return false
            end

            if cell.special ~= nil
                and cell.special ~= "explosive"
                and cell.special ~= "color" then
                return false
            end
        end
    end

    return true
end

local function defaults()
    return {
        board = Board.Create(),
        score = 0,
        soundEnabled = true,
        leaderboardShown = true,
        publicLeaderboardEnabled = false,
        leaderboardMode = "party",
        partyTopScores = {},
        publicTopScores = normalizeTopScores(
            nil,
            PublicLeaderboardSeeds.GetEntries()
        ),
        scoreSequence = 0,
        autoToggleEnabled = false,
        closeInCombatEnabled = false,
        window = { point = "CENTER", x = 0, y = 0, scale = 1 },
        minimapAngle = 225,
    }
end

function Persistence.Normalize(savedData)
    if type(savedData) ~= "table" or not isValidBoard(savedData.board) then
        return defaults()
    end

    local normalized = defaults()
    normalized.board = savedData.board
    normalized.score = math.max(0, tonumber(savedData.score) or 0)
    normalized.soundEnabled = savedData.soundEnabled ~= false
    normalized.leaderboardShown = savedData.leaderboardShown ~= false
    normalized.publicLeaderboardEnabled =
        savedData.publicLeaderboardEnabled == true
    normalized.leaderboardMode = savedData.leaderboardMode == "public"
        and "public"
        or "party"
    normalized.partyTopScores = normalizeTopScores(savedData.partyTopScores)
    normalized.publicTopScores = normalizeTopScores(
        savedData.publicTopScores,
        PublicLeaderboardSeeds.GetEntries()
    )
    normalized.publicAccountId = type(savedData.publicAccountId) == "string"
        and savedData.publicAccountId
        or nil
    normalized.scoreSessionId = type(savedData.scoreSessionId) == "string"
        and savedData.scoreSessionId
        or nil
    normalized.scoreSequence = math.max(
        0,
        math.floor(tonumber(savedData.scoreSequence) or 0)
    )
    normalized.autoToggleEnabled = savedData.autoToggleEnabled == true
    normalized.closeInCombatEnabled =
        savedData.closeInCombatEnabled == true

    if type(savedData.window) == "table" then
        normalized.window.point = savedData.window.point or "CENTER"
        normalized.window.x = tonumber(savedData.window.x) or 0
        normalized.window.y = tonumber(savedData.window.y) or 0
        normalized.window.scale = tonumber(savedData.window.scale) or 1
    end

    normalized.minimapAngle = tonumber(savedData.minimapAngle) or 225

    return normalized
end

if type(addon) == "table" then
    addon.Persistence = Persistence
end

return Persistence
