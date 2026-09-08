local TestRunner = require("tests.TestRunner")
local ScorePacket = require("Game.ScorePacket")
local Scoring = require("Game.Scoring")
local PublicLeaderboardSeeds = require("Game.PublicLeaderboardSeeds")

-- Version 1 public leaderboard seeds
TestRunner.describe("PublicLeaderboardSeeds", function()
    TestRunner.it("provides the nine requested players", function()
        -- Given
        local expectedNames = {
            Fortytwo = true,
            Misteni = true,
            Redfer = true,
            Loukoumaki = true,
            Azzor = true,
            Pagomouno = true,
            Velainor = true,
            Palioxamoura = true,
            Zarlas = true,
        }

        -- When
        local entries = PublicLeaderboardSeeds.GetEntries()

        -- Then
        TestRunner.assertEqual(9, #entries)
        for _, entry in ipairs(entries) do
            TestRunner.assertTrue(expectedNames[entry.name])
            expectedNames[entry.name] = nil
        end
    end)

    TestRunner.it("uses stable valid packets and reachable levels", function()
        -- Given
        local firstRead = PublicLeaderboardSeeds.GetEntries()

        -- When
        local secondRead = PublicLeaderboardSeeds.GetEntries()

        -- Then
        for index, entry in ipairs(firstRead) do
            local decoded = ScorePacket.Decode(entry.encoded)
            local expectedLevel = Scoring.GetLevel(entry.score)

            TestRunner.assertEqual(entry.encoded, secondRead[index].encoded)
            TestRunner.assertEqual(entry.name, decoded.name)
            TestRunner.assertEqual(entry.score, decoded.score)
            TestRunner.assertEqual(expectedLevel, decoded.level)
        end
    end)
end)
