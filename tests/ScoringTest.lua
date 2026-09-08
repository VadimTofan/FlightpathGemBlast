local TestRunner = require("tests.TestRunner")
local Scoring = require("Game.Scoring")

-- Scoring
TestRunner.describe("Scoring", function()
    TestRunner.it("multiplies cleared gems by cascade depth", function()
        -- Given
        local clearedGems = 4
        local cascadeDepth = 3

        -- When
        local points = Scoring.PointsForClear(clearedGems, cascadeDepth)

        -- Then
        TestRunner.assertEqual(120, points)
    end)

    TestRunner.it("advances levels at increasing thresholds", function()
        -- Given
        local score = 2500

        -- When
        local level, progress, required = Scoring.GetLevel(score)

        -- Then
        TestRunner.assertEqual(3, level)
        TestRunner.assertEqual(0, progress)
        TestRunner.assertEqual(2000, required)
    end)
end)
