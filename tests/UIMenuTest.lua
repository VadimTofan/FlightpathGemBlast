local TestRunner = require("tests.TestRunner")

TestRunner.describe("UI menu", function()
    TestRunner.it("fills the game window as a modal", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local coversGame = source:find(
            "menu:SetAllPoints(self.frame)",
            1,
            true
        ) ~= nil
        local fillsGame = source:find(
            "menuPanel:SetAllPoints(menu)",
            1,
            true
        ) ~= nil
        local blocksBoardInput = source:find(
            "menu:EnableMouse(true)",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(coversGame)
        TestRunner.assertTrue(fillsGame)
        TestRunner.assertTrue(blocksBoardInput)
    end)

    TestRunner.it("closes the menu before closing the game", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local checksMenuFirst = source:find(
            "if self.menu:IsShown() then",
            1,
            true
        ) ~= nil
        local hidesMenuAndReturns = source:find(
            "self.menu:Hide()\n            return\n        end\n\n        frame:Hide()",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(checksMenuFirst)
        TestRunner.assertTrue(hidesMenuAndReturns)
    end)

    TestRunner.it("omits redundant new-game and close-game actions", function()
        -- Given
        local uiFile = assert(io.open("UI.lua", "r"))
        local uiSource = uiFile:read("*a")
        uiFile:close()

        local coreFile = assert(io.open("Core.lua", "r"))
        local coreSource = coreFile:read("*a")
        coreFile:close()

        -- When
        local hasNewGameButton = uiSource:find(
            'createMenuButton(menuPanel, "New Game"',
            1,
            true
        ) ~= nil
        local hasCloseGameButton = uiSource:find(
            'createMenuButton(menuPanel, "Close Game"',
            1,
            true
        ) ~= nil
        local hasNewGamePopup = uiSource:find(
            "FLIGHTPATHGEMBLAST_NEW_GAME",
            1,
            true
        ) ~= nil
        local exposesNewGameSession = coreSource:find(
            "StartNewScoreSession",
            1,
            true
        ) ~= nil
        local keepsMainCloseButton = uiSource:find(
            '"FlightpathGemBlastCloseButton"',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertFalse(hasNewGameButton)
        TestRunner.assertFalse(hasCloseGameButton)
        TestRunner.assertFalse(hasNewGamePopup)
        TestRunner.assertFalse(exposesNewGameSession)
        TestRunner.assertTrue(keepsMainCloseButton)
    end)
end)

TestRunner.describe("UI auto-toggle option", function()
    TestRunner.it("provides an auto-toggle menu button", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local hasAutoToggle = source:find(
            '"Auto Open During Flight: On"',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasAutoToggle)
    end)
end)

TestRunner.describe("UI close-in-combat option", function()
    TestRunner.it("provides a separate close-in-combat button", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local hasCloseInCombat = source:find(
            '"Close in Combat: On"',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasCloseInCombat)
    end)
end)
