local TestRunner = require("tests.TestRunner")

local function score(accountId, value, name)
    return {
        accountId = accountId,
        sessionId = "session-" .. accountId,
        sequence = value,
        name = name or accountId,
        guid = "Player-1-" .. accountId,
        score = value,
        level = math.max(1, math.floor(value / 100)),
    }
end

TestRunner.describe("LeaderboardStore", function()
    TestRunner.it("keeps one personal best per account identity", function()
        -- Given
        local LeaderboardStore = require("Game.LeaderboardStore")
        local entries = {}
        local store = LeaderboardStore.New(entries, 10)
        store:Record(score("account1", 900, "Mage-Realm"), "packet-one", 10)

        -- When
        store:Record(score("account1", 200, "Warrior-Realm"), "packet-two", 20)

        -- Then
        TestRunner.assertEqual(1, store:Count())
        TestRunner.assertEqual(900, entries.account1.score)
        TestRunner.assertEqual("Mage-Realm", entries.account1.name)
    end)

    TestRunner.it("updates the character when the account beats its best", function()
        -- Given
        local LeaderboardStore = require("Game.LeaderboardStore")
        local entries = {}
        local store = LeaderboardStore.New(entries, 10)
        store:Record(score("account1", 200, "Mage-Realm"), "packet-one", 10)

        -- When
        store:Record(score("account1", 900, "Warrior-Realm"), "packet-two", 20)

        -- Then
        TestRunner.assertEqual(900, entries.account1.score)
        TestRunner.assertEqual("Warrior-Realm", entries.account1.name)
        TestRunner.assertEqual("packet-two", entries.account1.encoded)
    end)

    TestRunner.it("retains only the ten highest accounts", function()
        -- Given
        local LeaderboardStore = require("Game.LeaderboardStore")
        local entries = {}
        local store = LeaderboardStore.New(entries, 10)

        -- When
        for index = 1, 12 do
            store:Record(score("account" .. index, index * 100), "packet" .. index, index)
        end

        -- Then
        TestRunner.assertEqual(10, store:Count())
        TestRunner.assertEqual(nil, entries.account1)
        TestRunner.assertEqual(nil, entries.account2)
        TestRunner.assertEqual(1200, entries.account12.score)
    end)

    TestRunner.it("returns original encoded packets for synchronization", function()
        -- Given
        local LeaderboardStore = require("Game.LeaderboardStore")
        local entries = {}
        local store = LeaderboardStore.New(entries, 10)
        store:Record(score("account1", 900), "encoded-score", 10)

        -- When
        local packets = store:GetEncodedPackets()

        -- Then
        TestRunner.assertEqual(1, #packets)
        TestRunner.assertEqual("encoded-score", packets[1])
    end)
end)
