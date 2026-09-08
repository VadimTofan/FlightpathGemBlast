local TestRunner = require("tests.TestRunner")

TestRunner.describe("UI leaderboard", function()
    TestRunner.it("creates a collapsible panel on the left", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local hasPanel = source:find(
            '"BetterBejeweledLeaderboard"',
            1,
            true
        ) ~= nil
        local anchorsLeft = source:find(
            'leaderboard:SetPoint("TOPRIGHT", frame, "TOPLEFT"',
            1,
            true
        ) ~= nil
        local hasToggle = source:find(
            '"BetterBejeweledLeaderboardToggle"',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasPanel)
        TestRunner.assertTrue(anchorsLeft)
        TestRunner.assertTrue(hasToggle)
    end)
end)

TestRunner.describe("UI leaderboard columns", function()
    TestRunner.it("keeps the score heading inside the panel", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local anchorsScoreInside = source:find(
            'scoreHeading:SetPoint("RIGHT", -14, 0)',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(anchorsScoreInside)
    end)
end)

TestRunner.describe("UI leaderboard local player", function()
    TestRunner.it("labels the local entry as You", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesYouLabel = source:find(
            'addon.Leaderboard.Build(\n        "You",',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesYouLabel)
    end)
end)

TestRunner.describe("UI public leaderboard", function()
    TestRunner.it("places a join button below the leaderboard rows", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local hasButton = source:find(
            '"BetterBejeweledPublicLeaderboardButton"',
            1,
            true
        ) ~= nil
        local anchorsAtBottom = source:find(
            'publicButton:SetPoint("BOTTOM", 0, 10)',
            1,
            true
        ) ~= nil
        local usesChannelLabel = source:find(
            "publicLeaderboard:GetButtonLabel()",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasButton)
        TestRunner.assertTrue(anchorsAtBottom)
        TestRunner.assertTrue(usesChannelLabel)
    end)

    TestRunner.it("uses the persistent public score store in public mode", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local selectsPublicScores = source:find(
            "addon.publicLeaderboardStore",
            1,
            true
        ) ~= nil
        local persistsChoice = source:find(
            "BetterBejeweledDB.publicLeaderboardEnabled",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(selectsPublicScores)
        TestRunner.assertTrue(persistsChoice)
    end)

    TestRunner.it("provides separate party and public tabs", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local hasPartyTab = source:find(
            '"BetterBejeweledPartyLeaderboardTab"',
            1,
            true
        ) ~= nil
        local hasPublicTab = source:find(
            '"BetterBejeweledPublicLeaderboardTab"',
            1,
            true
        ) ~= nil
        local switchesMode = source:find(
            "UI:SetLeaderboardMode",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasPartyTab)
        TestRunner.assertTrue(hasPublicTab)
        TestRunner.assertTrue(switchesMode)
    end)

    TestRunner.it("disables the public tab until the player opts in", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesOptInState = source:find(
            "publicLeaderboard.enabled and mode ~= \"public\"",
            1,
            true
        ) ~= nil
        local guardsPublicMode = source:find(
            'mode == "public" and not publicLeaderboard.enabled',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesOptInState)
        TestRunner.assertTrue(guardsPublicMode)
    end)
end)
