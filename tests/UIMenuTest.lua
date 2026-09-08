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
