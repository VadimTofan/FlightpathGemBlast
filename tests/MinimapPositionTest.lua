local TestRunner = require("tests.TestRunner")
local MinimapPosition = require("Game.MinimapPosition")

TestRunner.describe("MinimapPosition.Calculate", function()
    TestRunner.it("places an icon on the edge of a round minimap", function()
        -- Given
        local angle = 0

        -- When
        local x, y = MinimapPosition.Calculate(
            angle,
            200,
            200,
            "ROUND",
            5
        )

        -- Then
        TestRunner.assertEqual(105, x)
        TestRunner.assertEqual(0, y)
    end)

    TestRunner.it("places a diagonal icon on a square minimap edge", function()
        -- Given
        local angle = 45

        -- When
        local x, y = MinimapPosition.Calculate(
            angle,
            200,
            200,
            "SQUARE",
            5
        )

        -- Then
        local expected = (math.sqrt(2 * 105 * 105) - 10)
            * math.sqrt(0.5)

        TestRunner.assertTrue(math.abs(x - expected) < 0.001)
        TestRunner.assertTrue(math.abs(y - expected) < 0.001)
    end)
end)

TestRunner.describe("Minimap launcher appearance", function()
    TestRunner.it("uses Blizzard's standard gold minimap border", function()
        -- Given
        local file = assert(io.open("Launcher.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesBackdrop = source:find("BackdropTemplate", 1, true)
            ~= nil
        local usesTrackingBorder = source:find(
            "SetTexture(136430)",
            1,
            true
        ) ~= nil
        local usesMinimapBackground = source:find(
            "SetTexture(136467)",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertFalse(usesBackdrop)
        TestRunner.assertTrue(usesTrackingBorder)
        TestRunner.assertTrue(usesMinimapBackground)
    end)
end)
