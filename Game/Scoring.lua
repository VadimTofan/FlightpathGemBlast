local Scoring = {}
local _, addon = ...

function Scoring.PointsForClear(clearedGems, cascadeDepth)
    return clearedGems * 10 * cascadeDepth
end

function Scoring.GetLevel(score)
    local level = 1
    local progress = score
    local required = 1000

    while progress >= required do
        progress = progress - required
        level = level + 1
        required = required + 500
    end

    return level, progress, required
end

if type(addon) == "table" then
    addon.Scoring = Scoring
end

return Scoring
