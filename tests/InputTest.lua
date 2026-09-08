local TestRunner = require("tests.TestRunner")
local Input = require("Game.Input")

TestRunner.describe("Input.GetDragTarget", function()
    TestRunner.it("selects the adjacent cell in the strongest drag direction", function()
        -- Given
        local row = 4
        local column = 4

        -- When
        local targetRow, targetColumn = Input.GetDragTarget(
            row,
            column,
            24,
            7,
            8
        )

        -- Then
        TestRunner.assertEqual(4, targetRow)
        TestRunner.assertEqual(5, targetColumn)
    end)

    TestRunner.it("rejects a drag that points outside the board", function()
        -- Given
        local row = 1
        local column = 3

        -- When
        local targetRow, targetColumn = Input.GetDragTarget(
            row,
            column,
            2,
            20,
            8
        )

        -- Then
        TestRunner.assertEqual(nil, targetRow)
        TestRunner.assertEqual(nil, targetColumn)
    end)
end)

TestRunner.describe("Input.GetSelectionAction", function()
    TestRunner.it("deselects when the second gem is not adjacent", function()
        -- Given
        local selectedRow = 2
        local selectedColumn = 2

        -- When
        local action = Input.GetSelectionAction(
            selectedRow,
            selectedColumn,
            7,
            7
        )

        -- Then
        TestRunner.assertEqual("deselect", action)
    end)


    TestRunner.it("swaps when the second gem is adjacent", function()
        -- Given
        local selectedRow = 2
        local selectedColumn = 2

        -- When
        local action = Input.GetSelectionAction(
            selectedRow,
            selectedColumn,
            2,
            3
        )

        -- Then
        TestRunner.assertEqual("swap", action)
    end)
end)
