local TestRunner = require("tests.TestRunner")
local AnimationDirector = require("Animation.Director")

-- Animation sequencing
TestRunner.describe("AnimationDirector", function()
    TestRunner.it("runs plan steps in order and finishes once", function()
        -- Given
        local started = {}
        local finished = 0
        local director = AnimationDirector.New({
            startStep = function(step)
                started[#started + 1] = step.kind
            end,
            finishPlan = function()
                finished = finished + 1
            end,
        })
        local plan = {
            steps = {
                { kind = "swap", valid = true },
                { kind = "clear", positions = {} },
                { kind = "settle", falls = {}, refills = {} },
            },
        }

        -- When
        director:Start(plan)
        director:Update(1)

        -- Then
        TestRunner.assertEqual("swap", started[1])
        TestRunner.assertEqual("clear", started[2])
        TestRunner.assertEqual("settle", started[3])
        TestRunner.assertEqual(1, finished)
        TestRunner.assertFalse(director:IsRunning())
    end)

    TestRunner.it("gives invalid swaps time to move out and return", function()
        -- Given
        local duration
        local director = AnimationDirector.New({
            startStep = function(_, stepDuration)
                duration = stepDuration
            end,
        })
        local plan = {
            steps = { { kind = "swap", valid = false } },
        }

        -- When
        director:Start(plan)

        -- Then
        TestRunner.assertEqual(0.28, duration)
    end)
end)
