local TestRunner = require("tests.TestRunner")
local Communication = require("Communication")
local ScorePacket = require("Game.ScorePacket")

local function encodedScore(overrides)
    local score = {
        accountId = "remote0000000001",
        sessionId = "session000000001",
        sequence = 1,
        name = "Jaina-Proudmoore",
        guid = "Player-1-ABCDEF01",
        score = 725,
        level = 3,
    }

    for key, value in pairs(overrides or {}) do
        score[key] = value
    end

    return ScorePacket.Encode(score), score
end

local function createApi(overrides)
    local api = {
        registerPrefix = function()
            return 0
        end,
        send = function()
            return 0
        end,
        isInGroup = function()
            return false
        end,
        isInRaid = function()
            return false
        end,
        isInInstanceGroup = function()
            return false
        end,
        playerName = function()
            return "Vadim-Silvermoon"
        end,
        now = function()
            return 100
        end,
        isPublicChannel = function(target)
            return target == "7. BetterBejeweled"
        end,
        decodeScore = ScorePacket.Decode,
        accountId = "local00000000001",
    }

    for key, value in pairs(overrides or {}) do
        api[key] = value
    end

    return api
end

TestRunner.describe("Communication", function()
    TestRunner.it("sends a versioned score to the party", function()
        -- Given
        local sent
        local communication = Communication.New(createApi({
            isInGroup = function()
                return true
            end,
            send = function(prefix, message, channel)
                sent = {
                    prefix = prefix,
                    message = message,
                    channel = channel,
                }

                return 0
            end,
        }))
        communication:Register()

        -- When
        local succeeded = communication:BroadcastScore(1250, 4)

        -- Then
        TestRunner.assertTrue(succeeded)
        TestRunner.assertEqual("BetterBejeweled", sent.prefix)
        TestRunner.assertEqual("S:1:1250:4", sent.message)
        TestRunner.assertEqual("PARTY", sent.channel)
    end)

    TestRunner.it("prefers the instance-chat channel", function()
        -- Given
        local channel
        local communication = Communication.New(createApi({
            isInGroup = function()
                return true
            end,
            isInRaid = function()
                return true
            end,
            isInInstanceGroup = function()
                return true
            end,
            send = function(_, _, sentChannel)
                channel = sentChannel

                return 0
            end,
        }))
        communication:Register()

        -- When
        communication:BroadcastScore(100, 2)

        -- Then
        TestRunner.assertEqual("INSTANCE_CHAT", channel)
    end)

    TestRunner.it("does not send when prefix registration is blocked", function()
        -- Given
        local sendWasCalled = false
        local communication = Communication.New(createApi({
            registerPrefix = function()
                return 2
            end,
            isInGroup = function()
                return true
            end,
            send = function()
                sendWasCalled = true
            end,
        }))
        communication:Register()

        -- When
        local succeeded = communication:BroadcastScore(100, 2)

        -- Then
        TestRunner.assertFalse(succeeded)
        TestRunner.assertFalse(sendWasCalled)
    end)

    TestRunner.it("reports a blocked send result", function()
        -- Given
        local communication = Communication.New(createApi({
            isInGroup = function()
                return true
            end,
            send = function()
                return 3
            end,
        }))
        communication:Register()

        -- When
        local succeeded = communication:BroadcastScore(100, 2)

        -- Then
        TestRunner.assertFalse(succeeded)
    end)

    TestRunner.it("stores valid scores received from group members", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        local accepted = communication:HandleMessage(
            "BetterBejeweled",
            "S:1:725:3",
            "RAID",
            "Jaina-Proudmoore"
        )

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual(
            725,
            communication.peerScores["Jaina-Proudmoore"].score
        )
        TestRunner.assertEqual(
            3,
            communication.peerScores["Jaina-Proudmoore"].level
        )
    end)

    TestRunner.it("rejects malformed score messages", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        local accepted = communication:HandleMessage(
            "BetterBejeweled",
            "S:1:not-a-score:3",
            "PARTY",
            "Thrall-Draenor"
        )

        -- Then
        TestRunner.assertFalse(accepted)
        TestRunner.assertEqual(nil, communication.peerScores["Thrall-Draenor"])
    end)

    TestRunner.it("ignores an echoed score from the local player", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        local accepted = communication:HandleMessage(
            "BetterBejeweled",
            "S:1:725:3",
            "PARTY",
            "Vadim-Silvermoon"
        )

        -- Then
        TestRunner.assertFalse(accepted)
        TestRunner.assertEqual(nil, communication.peerScores["Vadim-Silvermoon"])
    end)

    TestRunner.it("accepts the same character name from another realm", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        local accepted = communication:HandleMessage(
            "BetterBejeweled",
            "S:1:725:3",
            "PARTY",
            "Vadim-Draenor"
        )

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual(
            725,
            communication.peerScores["Vadim-Draenor"].score
        )
    end)

    TestRunner.it("clears cached scores after the group roster changes", function()
        -- Given
        local communication = Communication.New(createApi())
        communication.peerScores["Jaina-Proudmoore"] = {
            score = 725,
            level = 3,
        }

        -- When
        communication:ClearPeerScores()

        -- Then
        TestRunner.assertEqual(
            nil,
            communication.peerScores["Jaina-Proudmoore"]
        )
    end)
end)

TestRunner.describe("Communication encoded scores", function()
    TestRunner.it("broadcasts an encoded packet unchanged to the group", function()
        -- Given
        local sentMessage
        local encoded = encodedScore()
        local communication = Communication.New(createApi({
            isInGroup = function()
                return true
            end,
            send = function(_, message)
                sentMessage = message

                return 0
            end,
        }))
        communication:Register()

        -- When
        local succeeded = communication:BroadcastEncodedScore(encoded)

        -- Then
        TestRunner.assertTrue(succeeded)
        TestRunner.assertEqual(encoded, sentMessage)
    end)

    TestRunner.it("returns a decoded score with its group source", function()
        -- Given
        local encoded, expected = encodedScore()
        local communication = Communication.New(createApi())

        -- When
        local accepted, messageType, scoreData, source =
            communication:HandleMessage(
                "BetterBejeweled",
                encoded,
                "PARTY",
                "Jaina-Proudmoore"
            )

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual("score", messageType)
        TestRunner.assertEqual("group", source)
        TestRunner.assertEqual(expected.accountId, scoreData.accountId)
        TestRunner.assertEqual(expected.score, scoreData.score)
    end)

    TestRunner.it("rejects a packet whose character name differs from sender", function()
        -- Given
        local encoded = encodedScore({ name = "Thrall-Draenor" })
        local communication = Communication.New(createApi())

        -- When
        local accepted = communication:HandleMessage(
            "BetterBejeweled",
            encoded,
            "PARTY",
            "Jaina-Proudmoore"
        )

        -- Then
        TestRunner.assertFalse(accepted)
    end)

    TestRunner.it("accepts an encoded score only once", function()
        -- Given
        local encoded = encodedScore()
        local communication = Communication.New(createApi())
        communication:HandleMessage(
            "BetterBejeweled",
            encoded,
            "PARTY",
            "Jaina-Proudmoore"
        )

        -- When
        local accepted = communication:HandleMessage(
            "BetterBejeweled",
            encoded,
            "CHANNEL",
            "Jaina-Proudmoore",
            "7. BetterBejeweled"
        )

        -- Then
        TestRunner.assertFalse(accepted)
    end)

    TestRunner.it("accepts an original packet relayed by another public user", function()
        -- Given
        local encoded, expected = encodedScore({
            name = "Thrall-Draenor",
        })
        local communication = Communication.New(createApi())

        -- When
        local accepted, _, scoreData, source = communication:HandleMessage(
            "BetterBejeweled",
            encoded,
            "CHANNEL",
            "Jaina-Proudmoore",
            "7. BetterBejeweled"
        )

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual("public", source)
        TestRunner.assertEqual(expected.name, scoreData.name)
    end)

    TestRunner.it("queues and forwards the exact packet publicly", function()
        -- Given
        local sent
        local encoded = encodedScore()
        local communication = Communication.New(createApi({
            send = function(_, message, channel, target)
                sent = {
                    message = message,
                    channel = channel,
                    target = target,
                }

                return 0
            end,
        }))
        communication:Register()
        communication:QueuePublicPacket(encoded)

        -- When
        local succeeded = communication:FlushPublicQueue(7)

        -- Then
        TestRunner.assertTrue(succeeded)
        TestRunner.assertEqual(encoded, sent.message)
        TestRunner.assertEqual("CHANNEL", sent.channel)
        TestRunner.assertEqual(7, sent.target)
    end)

    TestRunner.it("limits queued packets when public sends cannot drain", function()
        -- Given
        local communication = Communication.New(createApi())
        local firstEncoded = encodedScore({
            accountId = "remote0000000001",
        })

        -- When
        communication:QueuePublicPacket(firstEncoded)
        for index = 2, 60 do
            local encoded = encodedScore({
                accountId = string.format("remote%010d", index),
            })
            communication:QueuePublicPacket(encoded)
        end

        -- Then
        TestRunner.assertEqual(50, #communication.publicQueue)
        TestRunner.assertEqual(nil, communication.queuedPublicPackets[firstEncoded])
    end)
end)

TestRunner.describe("Communication public leaderboard", function()
    TestRunner.it("sends a public score to the custom channel", function()
        -- Given
        local sent
        local communication = Communication.New(createApi({
            send = function(prefix, message, channel, target)
                sent = {
                    prefix = prefix,
                    message = message,
                    channel = channel,
                    target = target,
                }

                return 0
            end,
        }))
        communication:Register()

        -- When
        local succeeded = communication:BroadcastPublicScore(1250, 4, 7)

        -- Then
        TestRunner.assertTrue(succeeded)
        TestRunner.assertEqual("P:1:S:1250:4", sent.message)
        TestRunner.assertEqual("CHANNEL", sent.channel)
        TestRunner.assertEqual(7, sent.target)
    end)

    TestRunner.it("rate limits repeated public score broadcasts", function()
        -- Given
        local sendCount = 0
        local now = 100
        local communication = Communication.New(createApi({
            now = function()
                return now
            end,
            send = function()
                sendCount = sendCount + 1

                return 0
            end,
        }))
        communication:Register()
        communication:BroadcastPublicScore(100, 2, 7)

        -- When
        now = 102
        local succeeded = communication:BroadcastPublicScore(200, 2, 7)

        -- Then
        TestRunner.assertFalse(succeeded)
        TestRunner.assertEqual(1, sendCount)
    end)

    TestRunner.it("stores scores received from the public channel", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        local accepted, messageType = communication:HandleMessage(
            "BetterBejeweled",
            "P:1:S:725:3",
            "CHANNEL",
            "Jaina-Proudmoore",
            "7. BetterBejeweled"
        )

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual("score", messageType)
        TestRunner.assertEqual(
            725,
            communication.publicScores["Jaina-Proudmoore"].score
        )
        TestRunner.assertEqual(
            100,
            communication.publicScores["Jaina-Proudmoore"].updatedAt
        )
    end)

    TestRunner.it("limits cached public senders", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        for index = 1, 120 do
            communication:HandleMessage(
                "BetterBejeweled",
                "P:1:S:1250:4",
                "CHANNEL",
                "Player" .. index,
                "7. BetterBejeweled"
            )
        end

        -- Then
        local cachedSenders = 0
        for _ in pairs(communication.publicScores) do
            cachedSenders = cachedSenders + 1
        end
        TestRunner.assertEqual(100, cachedSenders)
    end)

    TestRunner.it("accepts score requests only from the public channel", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        local accepted, messageType = communication:HandleMessage(
            "BetterBejeweled",
            "P:1:Q",
            "CHANNEL",
            "Thrall-Draenor",
            "7. BetterBejeweled"
        )

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual("request", messageType)
    end)

    TestRunner.it("rejects public messages from a different channel", function()
        -- Given
        local communication = Communication.New(createApi())

        -- When
        local accepted = communication:HandleMessage(
            "BetterBejeweled",
            "P:1:S:725:3",
            "CHANNEL",
            "Jaina-Proudmoore",
            "8. AnotherChannel"
        )

        -- Then
        TestRunner.assertFalse(accepted)
        TestRunner.assertEqual(
            nil,
            communication.publicScores["Jaina-Proudmoore"]
        )
    end)

    TestRunner.it("broadcasts a public score request", function()
        -- Given
        local message
        local communication = Communication.New(createApi({
            send = function(_, sentMessage)
                message = sentMessage

                return 0
            end,
        }))
        communication:Register()

        -- When
        local succeeded = communication:BroadcastPublicRequest(7)

        -- Then
        TestRunner.assertTrue(succeeded)
        TestRunner.assertEqual("P:1:Q", message)
    end)

    TestRunner.it("expires stale public scores", function()
        -- Given
        local communication = Communication.New(createApi())
        communication.publicScores["Jaina-Proudmoore"] = {
            score = 725,
            level = 3,
            updatedAt = 20,
        }
        communication.publicScores["Thrall-Draenor"] = {
            score = 500,
            level = 2,
            updatedAt = 90,
        }

        -- When
        local changed = communication:ExpirePublicScores(100, 60)

        -- Then
        TestRunner.assertTrue(changed)
        TestRunner.assertEqual(
            nil,
            communication.publicScores["Jaina-Proudmoore"]
        )
        TestRunner.assertEqual(
            500,
            communication.publicScores["Thrall-Draenor"].score
        )
    end)

    TestRunner.it("clears public scores after leaving", function()
        -- Given
        local communication = Communication.New(createApi())
        communication.publicScores["Jaina-Proudmoore"] = {
            score = 725,
            level = 3,
            updatedAt = 100,
        }

        -- When
        communication:ClearPublicScores()

        -- Then
        TestRunner.assertEqual(
            nil,
            communication.publicScores["Jaina-Proudmoore"]
        )
    end)
end)
