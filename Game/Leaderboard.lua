local Leaderboard = {}
local _, addon = ...

function Leaderboard.FormatNumber(value)
    local formatted = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    local replacements

    repeat
        formatted, replacements = string.gsub(
            formatted,
            "^(%d+)(%d%d%d)",
            "%1,%2"
        )
    until replacements == 0

    return formatted
end

function Leaderboard.Build(
    localName,
    localScore,
    localLevel,
    peerScores,
    maximumEntries,
    localAccountId
)
    local entries = {
        {
            name = localName,
            score = localScore,
            level = localLevel,
            isLocal = true,
        },
    }

    for accountId, peer in pairs(peerScores) do
        if accountId ~= localAccountId then
            entries[#entries + 1] = {
                name = peer.name or accountId,
                score = peer.score,
                level = peer.level,
                isLocal = false,
            }
        end
    end

    table.sort(entries, function(first, second)
        if first.score ~= second.score then
            return first.score > second.score
        end

        if first.level ~= second.level then
            return first.level > second.level
        end

        return first.name < second.name
    end)

    for rank, entry in ipairs(entries) do
        entry.rank = rank
    end

    while #entries > maximumEntries do
        table.remove(entries)
    end

    return entries
end

if type(addon) == "table" then
    addon.Leaderboard = Leaderboard
end

return Leaderboard
