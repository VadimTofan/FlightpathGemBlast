local TestRunner = require("tests.TestRunner")
local loaded, SpecialEffects = pcall(require, "Animation.SpecialEffects")

-- Special-effect animation calculations
TestRunner.describe("SpecialEffects animation module", function()
    TestRunner.it("is available to the animation system", function()
        -- Given
        local moduleWasLoaded = loaded

        -- When
        local moduleType = type(SpecialEffects)

        -- Then
        TestRunner.assertTrue(moduleWasLoaded)
        TestRunner.assertEqual("table", moduleType)
    end)

    TestRunner.it("keeps the normal clear duration", function()
        -- Given
        local effects = {}

        -- When
        local duration = SpecialEffects.GetClearDuration(effects)

        -- Then
        TestRunner.assertEqual(0.18, duration)
    end)

    TestRunner.it("selects the longest triggered effect duration", function()
        -- Given
        local bomb = { { effectType = "bomb" } }
        local spark = { { effectType = "spark" } }
        local combination = {
            { effectType = "bomb" },
            { effectType = "bombCombo" },
        }

        -- When
        local bombDuration = SpecialEffects.GetClearDuration(bomb)
        local sparkDuration = SpecialEffects.GetClearDuration(spark)
        local combinationDuration = SpecialEffects.GetClearDuration(combination)

        -- Then
        TestRunner.assertEqual(0.28, bombDuration)
        TestRunner.assertEqual(0.34, sparkDuration)
        TestRunner.assertEqual(0.38, combinationDuration)
    end)

    TestRunner.it("returns primitive visual values for a normal clear", function()
        -- Given
        local effects = {}

        -- When
        local gemScale,
            gemAlpha,
            effectScale,
            effectAlpha,
            rotation,
            red,
            green,
            blue = SpecialEffects.GetCellVisual(effects, 4, 4, 0.5)

        -- Then
        TestRunner.assertEqual("number", type(gemScale))
        TestRunner.assertEqual("number", type(gemAlpha))
        TestRunner.assertEqual("number", type(effectScale))
        TestRunner.assertEqual(0, effectAlpha)
        TestRunner.assertEqual("number", type(rotation))
        TestRunner.assertEqual("number", type(red))
        TestRunner.assertEqual("number", type(green))
        TestRunner.assertEqual("number", type(blue))
    end)

    TestRunner.it("starts a bomb wave near the source before distant cells", function()
        -- Given
        local effects = {
            {
                effectType = "bombCombo",
                row = 4,
                column = 4,
                radius = 2,
            },
        }

        -- When
        local _, _, _, sourceAlpha = SpecialEffects.GetCellVisual(
            effects,
            4,
            4,
            0.10
        )
        local _, _, _, distantAlpha = SpecialEffects.GetCellVisual(
            effects,
            6,
            6,
            0.10
        )

        -- Then
        TestRunner.assertTrue(sourceAlpha > distantAlpha)
        TestRunner.assertEqual(0, distantAlpha)
    end)

    TestRunner.it("animates a cyan line along a directional blast", function()
        -- Given
        local effects = {
            {
                effectType = "lineBomb",
                row = 4,
                column = 4,
                direction = "horizontal",
            },
        }

        -- When
        local _, _, _, alpha, _, red, green, blue =
            SpecialEffects.GetCellVisual(effects, 4, 8, 0.5)

        -- Then
        TestRunner.assertTrue(alpha > 0)
        TestRunner.assertTrue(blue > red)
        TestRunner.assertTrue(green > red)
    end)

    TestRunner.it("uses a blue double pulse for a spark", function()
        -- Given
        local effects = {
            {
                effectType = "spark",
                row = 1,
                column = 1,
                gemType = 1,
            },
        }

        -- When
        local _, _, _, firstPulse = SpecialEffects.GetCellVisual(
            effects,
            1,
            1,
            0.25
        )
        local _, _, _, middleFade = SpecialEffects.GetCellVisual(
            effects,
            1,
            1,
            0.50
        )
        local _, _, _, secondPulse = SpecialEffects.GetCellVisual(
            effects,
            1,
            1,
            0.75
        )
        local _, _, _, targetAlpha, _, red, _, blue =
            SpecialEffects.GetCellVisual(effects, 1, 3, 0.50)

        -- Then
        TestRunner.assertTrue(firstPulse > middleFade)
        TestRunner.assertTrue(secondPulse > middleFade)
        TestRunner.assertTrue(targetAlpha > 0)
        TestRunner.assertTrue(blue > red)
    end)

    TestRunner.it("keeps a converted bomb visible through the spark wave", function()
        -- Given
        local effects = {
            {
                effectType = "spark",
                row = 1,
                column = 1,
                gemType = 1,
            },
            {
                effectType = "bomb",
                row = 4,
                column = 4,
                radius = 1,
            },
        }

        -- When
        local _, _, _, alpha, _, red, _, blue =
            SpecialEffects.GetCellVisual(effects, 4, 4, 0.65)

        -- Then
        TestRunner.assertTrue(alpha > 0)
        TestRunner.assertTrue(red > blue)
    end)
end)

if not loaded then
    return
end
