local TestRunner = require("tests.TestRunner")

TestRunner.describe("ScoreSession", function()
    TestRunner.it("shares one persisted account identity", function()
        -- Given
        local ScoreSession = require("Game.ScoreSession")
        local savedData = {}
        local generated = 0
        local api = {
            generateId = function()
                generated = generated + 1

                return generated == 1 and "account000000001" or "session000000001"
            end,
        }

        -- When
        local first = ScoreSession.New(savedData, api)
        local second = ScoreSession.New(savedData, api)

        -- Then
        TestRunner.assertEqual(first.accountId, second.accountId)
        TestRunner.assertEqual("account000000001", savedData.publicAccountId)
    end)

    TestRunner.it("creates packets with increasing sequence numbers", function()
        -- Given
        local ScoreSession = require("Game.ScoreSession")
        local savedData = {
            publicAccountId = "account000000001",
            scoreSessionId = "session000000001",
            scoreSequence = 0,
        }
        local session = ScoreSession.New(savedData, {
            generateId = function()
                return "unused0000000001"
            end,
        })

        -- When
        local first = session:CreateScoreData(
            "Vadim-Silvermoon",
            "Player-3391-0ABCDEF1",
            100,
            2
        )
        local second = session:CreateScoreData(
            "Vadim-Silvermoon",
            "Player-3391-0ABCDEF1",
            200,
            2
        )

        -- Then
        TestRunner.assertEqual(1, first.sequence)
        TestRunner.assertEqual(2, second.sequence)
        TestRunner.assertEqual(2, savedData.scoreSequence)
    end)

    TestRunner.it("starts a new sequence for a new game", function()
        -- Given
        local ScoreSession = require("Game.ScoreSession")
        local savedData = {
            publicAccountId = "account000000001",
            scoreSessionId = "oldsession000001",
            scoreSequence = 20,
        }
        local session = ScoreSession.New(savedData, {
            generateId = function()
                return "newsession000001"
            end,
        })

        -- When
        session:StartNewGame()

        -- Then
        TestRunner.assertEqual("newsession000001", savedData.scoreSessionId)
        TestRunner.assertEqual(0, savedData.scoreSequence)
    end)

    TestRunner.it("replaces malformed persisted identifiers", function()
        -- Given
        local ScoreSession = require("Game.ScoreSession")
        local savedData = {
            publicAccountId = "bad|account",
            scoreSessionId = "short",
        }
        local generated = 0

        -- When
        ScoreSession.New(savedData, {
            generateId = function()
                generated = generated + 1

                return generated == 1
                    and "account000000001"
                    or "session000000001"
            end,
        })

        -- Then
        TestRunner.assertEqual("account000000001", savedData.publicAccountId)
        TestRunner.assertEqual("session000000001", savedData.scoreSessionId)
    end)
end)
