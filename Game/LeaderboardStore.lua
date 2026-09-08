local LeaderboardStore = {}
LeaderboardStore.__index = LeaderboardStore

local _, addon = ...

local function countEntries(entries)
    local count = 0

    for _ in pairs(entries) do
        count = count + 1
    end

    return count
end

local function isLower(first, second)
    if first.score ~= second.score then
        return first.score < second.score
    end

    if first.level ~= second.level then
        return first.level < second.level
    end

    return first.name > second.name
end

function LeaderboardStore.New(entries, maximumEntries)
    return setmetatable({
        entries = entries,
        maximumEntries = maximumEntries,
    }, LeaderboardStore)
end

function LeaderboardStore:Count()
    return countEntries(self.entries)
end

function LeaderboardStore:Trim()
    while self:Count() > self.maximumEntries do
        local lowestAccountId
        local lowestEntry

        for accountId, entry in pairs(self.entries) do
            if not lowestEntry or isLower(entry, lowestEntry) then
                lowestAccountId = accountId
                lowestEntry = entry
            end
        end

        self.entries[lowestAccountId] = nil
    end
end

function LeaderboardStore:Record(scoreData, encoded, updatedAt)
    local current = self.entries[scoreData.accountId]
    if current and current.score > scoreData.score then
        return false
    end

    if current and current.score == scoreData.score
        and current.sequence >= scoreData.sequence then
        return false
    end

    self.entries[scoreData.accountId] = {
        accountId = scoreData.accountId,
        sessionId = scoreData.sessionId,
        sequence = scoreData.sequence,
        name = scoreData.name,
        guid = scoreData.guid,
        score = scoreData.score,
        level = scoreData.level,
        encoded = encoded,
        updatedAt = updatedAt,
    }
    self:Trim()

    return self.entries[scoreData.accountId] ~= nil
end

function LeaderboardStore:GetEncodedPackets()
    local packets = {}

    for _, entry in pairs(self.entries) do
        if type(entry.encoded) == "string" then
            packets[#packets + 1] = entry.encoded
        end
    end

    return packets
end

if type(addon) == "table" then
    addon.LeaderboardStore = LeaderboardStore
end

return LeaderboardStore
