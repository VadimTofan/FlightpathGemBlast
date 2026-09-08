local TestRunner = require("tests.TestRunner")

local function sample(overrides)
    local data = {
        accountId = "a1b2c3d4e5f60718",
        sessionId = "1029384756abcdef",
        sequence = 12,
        name = "Vadim-Silvermoon",
        guid = "Player-3391-0ABCDEF1",
        score = 1250,
        level = 4,
    }

    for key, value in pairs(overrides or {}) do
        data[key] = value
    end

    return data
end

TestRunner.describe("ScorePacket", function()
    TestRunner.it("encodes every score field into an opaque packet", function()
        -- Given
        local ScorePacket = require("Game.ScorePacket")
        local score = sample()

        -- When
        local encoded = ScorePacket.Encode(score)

        -- Then
        TestRunner.assertTrue(type(encoded) == "string")
        TestRunner.assertTrue(string.sub(encoded, 1, 3) == "B1:")
        TestRunner.assertTrue(#encoded <= 255)
        TestRunner.assertFalse(encoded:find(score.name, 1, true) ~= nil)
        TestRunner.assertFalse(encoded:find(tostring(score.score), 1, true) ~= nil)
    end)

    TestRunner.it("decodes a valid packet without losing fields", function()
        -- Given
        local ScorePacket = require("Game.ScorePacket")
        local expected = sample()
        local encoded = ScorePacket.Encode(expected)

        -- When
        local decoded = ScorePacket.Decode(encoded)

        -- Then
        TestRunner.assertEqual(expected.accountId, decoded.accountId)
        TestRunner.assertEqual(expected.sessionId, decoded.sessionId)
        TestRunner.assertEqual(expected.sequence, decoded.sequence)
        TestRunner.assertEqual(expected.name, decoded.name)
        TestRunner.assertEqual(expected.guid, decoded.guid)
        TestRunner.assertEqual(expected.score, decoded.score)
        TestRunner.assertEqual(expected.level, decoded.level)
    end)

    TestRunner.it("rejects a packet changed after encoding", function()
        -- Given
        local ScorePacket = require("Game.ScorePacket")
        local encoded = ScorePacket.Encode(sample())
        local lastCharacter = string.sub(encoded, -1)
        local replacement = lastCharacter == "A" and "B" or "A"
        local changed = string.sub(encoded, 1, -2) .. replacement

        -- When
        local decoded = ScorePacket.Decode(changed)

        -- Then
        TestRunner.assertEqual(nil, decoded)
    end)

    TestRunner.it("rejects unreasonable score values", function()
        -- Given
        local ScorePacket = require("Game.ScorePacket")
        local invalid = sample({ score = 1000000000 })

        -- When
        local encoded = ScorePacket.Encode(invalid)

        -- Then
        TestRunner.assertEqual(nil, encoded)
    end)

    TestRunner.it("rejects a packet larger than WoW's message limit", function()
        -- Given
        local ScorePacket = require("Game.ScorePacket")
        local oversized = sample({
            accountId = string.rep("a", 32),
            sessionId = string.rep("b", 32),
            name = string.rep("N", 64),
            guid = "Player-" .. string.rep("1", 20)
                .. "-" .. string.rep("A", 20),
        })

        -- When
        local encoded = ScorePacket.Encode(oversized)

        -- Then
        TestRunner.assertEqual(nil, encoded)
    end)
end)
