local TestRunner = require("tests.TestRunner")
local Leaderboard = require("Game.Leaderboard")

TestRunner.describe("Leaderboard.Build", function()
    TestRunner.it("ranks local and peer scores from highest to lowest", function()
        -- Given
        local peers = {
            ["Jaina-Proudmoore"] = { score = 900, level = 3 },
            ["Thrall-Draenor"] = { score = 250, level = 2 },
        }

        -- When
        local entries = Leaderboard.Build(
            "Vadim",
            600,
            3,
            peers,
            10
        )

        -- Then
        TestRunner.assertEqual("Jaina-Proudmoore", entries[1].name)
        TestRunner.assertEqual("Vadim", entries[2].name)
        TestRunner.assertTrue(entries[2].isLocal)
        TestRunner.assertEqual("Thrall-Draenor", entries[3].name)
    end)

    TestRunner.it("limits raid-sized results to the requested count", function()
        -- Given
        local peers = {}
        for index = 1, 15 do
            peers["Player" .. index] = {
                score = index * 100,
                level = index,
            }
        end

        -- When
        local entries = Leaderboard.Build(
            "Vadim",
            0,
            1,
            peers,
            10
        )

        -- Then
        TestRunner.assertEqual(10, #entries)
        TestRunner.assertEqual(1500, entries[1].score)
    end)

    TestRunner.it("uses the stored character name for account-keyed scores", function()
        -- Given
        local peers = {
            account000000001 = {
                name = "Jaina-Proudmoore",
                score = 900,
                level = 3,
            },
        }

        -- When
        local entries = Leaderboard.Build("You", 600, 3, peers, 10)

        -- Then
        TestRunner.assertEqual("Jaina-Proudmoore", entries[1].name)
    end)

    TestRunner.it("does not duplicate the local account entry", function()
        -- Given
        local peers = {
            localaccount0001 = {
                name = "Vadim-Silvermoon",
                score = 900,
                level = 3,
            },
        }

        -- When
        local entries = Leaderboard.Build(
            "You",
            900,
            3,
            peers,
            10,
            "localaccount0001"
        )

        -- Then
        TestRunner.assertEqual(1, #entries)
        TestRunner.assertEqual("You", entries[1].name)
    end)
end)
