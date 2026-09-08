local TestRunner = require("tests.TestRunner")
local Controller = require("Game.Controller")

-- Input phases
TestRunner.describe("Controller", function()
    TestRunner.it("rejects swaps while the board is resolving", function()
        -- Given
        local controller = Controller.New()
        controller.phase = "RESOLVING"

        -- When
        local accepted = controller:Swap(1, 1, 1, 2)

        -- Then
        TestRunner.assertFalse(accepted)
    end)

    TestRunner.it("starts ready for input", function()
        -- Given
        local savedData = nil

        -- When
        local controller = Controller.New(savedData)

        -- Then
        TestRunner.assertEqual("READY", controller.phase)
        TestRunner.assertEqual(0, controller.score)
    end)

    TestRunner.it("commits a planned move only after animation finishes", function()
        -- Given
        local controller = Controller.New()
        local originalBoard = controller.board

        -- When
        local plan = controller:BeginSwap(1, 1, 1, 2)

        -- Then
        TestRunner.assertEqual("ANIMATING", controller.phase)
        TestRunner.assertEqual(originalBoard, controller.board)

        -- When
        controller:FinishSwap(plan)

        -- Then
        TestRunner.assertEqual("READY", controller.phase)
    end)

    TestRunner.it("does not plan an animation for distant gems", function()
        -- Given
        local controller = Controller.New()

        -- When
        local plan = controller:BeginSwap(1, 1, 8, 8)

        -- Then
        TestRunner.assertEqual(nil, plan)
        TestRunner.assertEqual("READY", controller.phase)
    end)
end)
