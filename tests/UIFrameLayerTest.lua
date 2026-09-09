local TestRunner = require("tests.TestRunner")

TestRunner.describe("UI window layering", function()
    TestRunner.it("places the game above ordinary UI panels", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesTopDialogStrata = source:find(
            'frame:SetFrameStrata("FULLSCREEN_DIALOG")',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesTopDialogStrata)
    end)
end)

TestRunner.describe("UI window controls", function()
    TestRunner.it("provides a close button on the main window", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesCloseButton = source:find(
            '"GemBlastCloseButton"',
            1,
            true
        ) ~= nil
        local usesCloseTemplate = source:find(
            '"UIPanelCloseButton"',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesCloseButton)
        TestRunner.assertTrue(usesCloseTemplate)
    end)
end)
