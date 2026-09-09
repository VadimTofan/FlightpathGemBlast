local Announcement = {}
local _, addon = ...

function Announcement.LevelMessage(level)
    return "I just reached level " .. level .. " in Flightpath Gem Blast!"
end

function Announcement.SendReachedLevels(previousLevel, currentLevel, send)
    for level = previousLevel + 1, currentLevel do
        send(Announcement.LevelMessage(level), "EMOTE")
    end
end

function Announcement.NotifyNoMoves(show, log)
    local message = "No moves left. Reshuffling the board..."

    show(message)
    log("Flightpath Gem Blast: " .. message)
end

if type(addon) == "table" then
    addon.Announcement = Announcement
end

return Announcement
