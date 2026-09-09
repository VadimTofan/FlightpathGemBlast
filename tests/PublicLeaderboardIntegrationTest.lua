local TestRunner = require("tests.TestRunner")

TestRunner.describe("Public leaderboard integration", function()
    TestRunner.it("uses a temporary channel without assigning a chat frame", function()
        -- Given
        local file = assert(io.open("Core.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesTemporaryChannel = source:find(
            "JoinTemporaryChannel",
            1,
            true
        ) ~= nil
        local assignsChatFrame = source:find(
            "ChatFrame1:GetID()",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesTemporaryChannel)
        TestRunner.assertFalse(assignsChatFrame)
    end)

    TestRunner.it("listens for asynchronous channel updates", function()
        -- Given
        local file = assert(io.open("Core.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local registersUpdate = source:find(
            'events:RegisterEvent("CHANNEL_UI_UPDATE")',
            1,
            true
        ) ~= nil
        local refreshesConnection = source:find(
            "publicLeaderboard:RefreshConnection(",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(registersUpdate)
        TestRunner.assertTrue(refreshesConnection)
    end)

    TestRunner.it("filters its custom-channel notices from chat", function()
        -- Given
        local file = assert(io.open("Core.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local installsFilter = source:find(
            "ChatFrame_AddMessageEventFilter",
            1,
            true
        ) ~= nil
        local limitsFilter = source:find(
            'channelBaseName == "Flightpath Gem Blast"',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(installsFilter)
        TestRunner.assertTrue(limitsFilter)
    end)

    TestRunner.it("removes the public channel from every chat frame", function()
        -- Given
        local file = assert(io.open("Core.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local removesChannel = source:find(
            "ChatFrame_RemoveChannel",
            1,
            true
        ) ~= nil
        local visitsChatFrames = source:find("CHAT_FRAMES", 1, true) ~= nil

        -- Then
        TestRunner.assertTrue(removesChannel)
        TestRunner.assertTrue(visitsChatFrames)
    end)

    TestRunner.it("finishes a pending join check after a delay", function()
        -- Given
        local file = assert(io.open("Core.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local schedulesCheck = source:find(
            "schedulePublicConnectionCheck",
            1,
            true
        ) ~= nil
        local marksFinalCheck = source:find(
            "handlePublicConnection(true)",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(schedulesCheck)
        TestRunner.assertTrue(marksFinalCheck)
    end)

    TestRunner.it("records group scores in both persistent stores", function()
        -- Given
        local file = assert(io.open("Core.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local recordsParty = source:find(
            "partyLeaderboardStore:Record",
            1,
            true
        ) ~= nil
        local recordsPublic = source:find(
            "publicLeaderboardStore:Record",
            1,
            true
        ) ~= nil
        local forwardsOriginal = source:find(
            "QueuePublicPacket(encoded)",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(recordsParty)
        TestRunner.assertTrue(recordsPublic)
        TestRunner.assertTrue(forwardsOriginal)
    end)

    TestRunner.it("broadcasts gameplay scores every thirty seconds", function()
        -- Given
        local coreFile = assert(io.open("Core.lua", "r"))
        local coreSource = coreFile:read("*a")
        coreFile:close()

        local uiFile = assert(io.open("UI.lua", "r"))
        local uiSource = uiFile:read("*a")
        uiFile:close()

        -- When
        local usesThirtySecondInterval = coreSource:find(
            "local SCORE_SYNC_INTERVAL = 30",
            1,
            true
        ) ~= nil
        local schedulesScoreSync = coreSource:find(
            "C_Timer.NewTicker(SCORE_SYNC_INTERVAL",
            1,
            true
        ) ~= nil
        local finishStart = assert(uiSource:find(
            "function UI:FinishAnimationPlan",
            1,
            true
        ))
        local finishEnd = assert(uiSource:find(
            "function UI:SelectCell",
            finishStart,
            true
        ))
        local finishSource = uiSource:sub(finishStart, finishEnd - 1)
        local broadcastsAfterEveryMove = finishSource:find(
            "BroadcastScore",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesThirtySecondInterval)
        TestRunner.assertTrue(schedulesScoreSync)
        TestRunner.assertFalse(broadcastsAfterEveryMove)
    end)
end)
