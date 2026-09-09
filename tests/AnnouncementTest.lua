local TestRunner = require("tests.TestRunner")
local Announcement = require("Game.Announcement")

TestRunner.describe("Announcement.LevelMessage", function()
    TestRunner.it("formats a reached-level emote message", function()
        -- Given
        local level = 7

        -- When
        local message = Announcement.LevelMessage(level)

        -- Then
        TestRunner.assertEqual(
            "I just reached level 7 in Gem Blast!",
            message
        )
    end)
end)

TestRunner.describe("Announcement.SendReachedLevels", function()
    TestRunner.it("sends an emote for every crossed level", function()
        -- Given
        local sent = {}
        local function send(message, chatType)
            sent[#sent + 1] = {
                message = message,
                chatType = chatType,
            }
        end

        -- When
        Announcement.SendReachedLevels(3, 5, send)

        -- Then
        TestRunner.assertEqual(2, #sent)
        TestRunner.assertEqual(
            "I just reached level 4 in Gem Blast!",
            sent[1].message
        )
        TestRunner.assertEqual("EMOTE", sent[1].chatType)
        TestRunner.assertEqual(
            "I just reached level 5 in Gem Blast!",
            sent[2].message
        )
        TestRunner.assertEqual("EMOTE", sent[2].chatType)
    end)
end)

TestRunner.describe("Announcement.NotifyNoMoves", function()
    TestRunner.it("shows and logs the reshuffle message", function()
        -- Given
        local shownMessage
        local loggedMessage

        -- When
        Announcement.NotifyNoMoves(
            function(message)
                shownMessage = message
            end,
            function(message)
                loggedMessage = message
            end
        )

        -- Then
        TestRunner.assertEqual(
            "No moves left. Reshuffling the board...",
            shownMessage
        )
        TestRunner.assertEqual(
            "Gem Blast: No moves left. Reshuffling the board...",
            loggedMessage
        )
    end)
end)
