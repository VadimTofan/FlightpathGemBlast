local TestRunner = require("tests.TestRunner")

TestRunner.describe("UI leaderboard", function()
    TestRunner.it("creates a collapsible panel on the left", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local hasPanel = source:find(
            '"GemBlastLeaderboard"',
            1,
            true
        ) ~= nil
        local anchorsLeft = source:find(
            'leaderboard:SetPoint("TOPRIGHT", frame, "TOPLEFT"',
            1,
            true
        ) ~= nil
        local hasToggle = source:find(
            '"GemBlastLeaderboardToggle"',
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

    TestRunner.it("reserves space for maximum leaderboard values", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesWidePanel = source:find(
            "local LEADERBOARD_WIDTH = 252",
            1,
            true
        ) ~= nil
        local usesWideContent = source:find(
            "local LEADERBOARD_CONTENT_WIDTH = 224",
            1,
            true
        ) ~= nil
        local reservesNameWidth = source:find(
            "local LEADERBOARD_NAME_WIDTH = 90",
            1,
            true
        ) ~= nil
        local reservesLevelWidth = source:find(
            "local LEADERBOARD_LEVEL_WIDTH = 38",
            1,
            true
        ) ~= nil
        local reservesScoreWidth = source:find(
            "local LEADERBOARD_SCORE_WIDTH = 64",
            1,
            true
        ) ~= nil
        local appliesNameWidth = source:find(
            "row.name:SetSize(LEADERBOARD_NAME_WIDTH, 20)",
            1,
            true
        ) ~= nil
        local appliesLevelWidth = source:find(
            "row.level:SetSize(LEADERBOARD_LEVEL_WIDTH, 20)",
            1,
            true
        ) ~= nil
        local appliesScoreWidth = source:find(
            "row.score:SetSize(LEADERBOARD_SCORE_WIDTH, 20)",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesWidePanel)
        TestRunner.assertTrue(usesWideContent)
        TestRunner.assertTrue(reservesNameWidth)
        TestRunner.assertTrue(reservesLevelWidth)
        TestRunner.assertTrue(reservesScoreWidth)
        TestRunner.assertTrue(appliesNameWidth)
        TestRunner.assertTrue(appliesLevelWidth)
        TestRunner.assertTrue(appliesScoreWidth)
    end)

    TestRunner.it("groups level and score digits for display", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local formatsLevel = source:find(
            'row.level:SetText("L" .. addon.Leaderboard.FormatNumber(',
            1,
            true
        ) ~= nil
        local formatsScore = source:find(
            "row.score:SetText(addon.Leaderboard.FormatNumber(",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(formatsLevel)
        TestRunner.assertTrue(formatsScore)
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
            '"GemBlastPublicLeaderboardButton"',
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
            "GemBlastDB.publicLeaderboardEnabled",
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
            '"GemBlastPartyLeaderboardTab"',
            1,
            true
        ) ~= nil
        local hasPublicTab = source:find(
            '"GemBlastPublicLeaderboardTab"',
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
