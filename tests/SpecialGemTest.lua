local TestRunner = require("tests.TestRunner")
local Board = require("Game.Board")

local function cell(gemType, special)
    return { gemType = gemType, special = special }
end

-- Special gem effects
TestRunner.describe("Board.ExpandSpecialEffects", function()
    TestRunner.it("expands an explosive gem to its surrounding area", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(1)
            end
        end
        board[4][4] = cell(1, "explosive")
        local matches = { ["4:4"] = true }

        -- When
        local expanded, effects = Board.ExpandSpecialEffects(board, matches)

        -- Then
        local count = 0
        for _ in pairs(expanded) do
            count = count + 1
        end
        TestRunner.assertEqual(9, count)
        TestRunner.assertEqual(1, #effects)
        TestRunner.assertEqual("bomb", effects[1].effectType)
        TestRunner.assertEqual(4, effects[1].row)
        TestRunner.assertEqual(4, effects[1].column)
        TestRunner.assertEqual(1, effects[1].radius)
    end)

    TestRunner.it("reports every bomb in a chain reaction", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(1)
            end
        end
        board[4][4] = cell(1, "explosive")
        board[4][5] = cell(2, "explosive")

        -- When
        local _, effects = Board.ExpandSpecialEffects(
            board,
            { ["4:4"] = true }
        )

        -- Then
        TestRunner.assertEqual(2, #effects)
        TestRunner.assertEqual(4, effects[1].row)
        TestRunner.assertEqual(4, effects[1].column)
        TestRunner.assertEqual(4, effects[2].row)
        TestRunner.assertEqual(5, effects[2].column)
    end)

    TestRunner.it("clears a selected color with a color gem", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(((row + column) % 2) + 1)
            end
        end

        -- When
        local matches = Board.ColorClearCells(board, 2)

        -- Then
        local count = 0
        for _ in pairs(matches) do
            count = count + 1
        end
        TestRunner.assertEqual(32, count)
    end)
end)

TestRunner.describe("Board.DetermineSpecial", function()
    TestRunner.it("creates an explosive gem from four in a row", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(((row + column) % 7) + 1)
            end
        end
        for column = 2, 5 do
            board[4][column] = cell(3)
        end
        local matches = Board.FindMatches(board)

        -- When
        local row, column, special = Board.DetermineSpecial(
            board,
            matches,
            4,
            5
        )

        -- Then
        TestRunner.assertEqual(4, row)
        TestRunner.assertEqual(5, column)
        TestRunner.assertEqual("explosive", special)
    end)

    TestRunner.it("creates a color gem from five in a row", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(((row + column) % 7) + 1)
            end
        end
        for row = 2, 6 do
            board[row][3] = cell(4)
        end
        local matches = Board.FindMatches(board)

        -- When
        local _, _, special = Board.DetermineSpecial(board, matches, 6, 3)

        -- Then
        TestRunner.assertEqual("color", special)
    end)
end)

TestRunner.describe("Board.TrySwap color gem", function()
    TestRunner.it("accepts the swap and selects the other gem color", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(((row + column) % 7) + 1)
            end
        end
        board[1][1] = cell(1, "color")
        board[1][2] = cell(6)

        -- When
        local accepted, colorMatches, effects = Board.TrySwap(
            board,
            1,
            1,
            1,
            2
        )

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertTrue(colorMatches["1:2"])
        TestRunner.assertTrue(colorMatches["1:1"])
        TestRunner.assertEqual(1, #effects)
        TestRunner.assertEqual("spark", effects[1].effectType)
        TestRunner.assertEqual(1, effects[1].row)
        TestRunner.assertEqual(2, effects[1].column)
        TestRunner.assertEqual(6, effects[1].gemType)
    end)

    TestRunner.it("turns matching gems into bombs when crossed with a bomb", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(1)
            end
        end
        board[4][4] = cell(7, "color")
        board[4][5] = cell(2, "explosive")
        board[2][2] = cell(2)
        board[7][7] = cell(2)

        -- When
        local accepted, matches = Board.TrySwap(board, 4, 4, 4, 5)
        local expanded, effects = Board.ExpandSpecialEffects(board, matches)

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual("explosive", board[4][4].special)
        TestRunner.assertEqual("explosive", board[2][2].special)
        TestRunner.assertEqual("explosive", board[7][7].special)
        TestRunner.assertEqual("color", board[4][5].special)
        TestRunner.assertEqual(3, #effects)
        TestRunner.assertTrue(expanded["1:1"])
        TestRunner.assertTrue(expanded["8:8"])
    end)
end)

TestRunner.describe("Board.TrySwap explosive gems", function()
    TestRunner.it("centers a five by five blast on the destination", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(((row + column) % 7) + 1)
            end
        end
        board[4][4] = cell(1, "explosive")
        board[4][5] = cell(2, "explosive")

        -- When
        local accepted, blastCells, effects = Board.TrySwap(
            board,
            4,
            4,
            4,
            5
        )

        -- Then
        local clearedCount = 0
        for _ in pairs(blastCells) do
            clearedCount = clearedCount + 1
        end

        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual(25, clearedCount)
        TestRunner.assertTrue(blastCells["2:3"])
        TestRunner.assertTrue(blastCells["6:7"])
        TestRunner.assertEqual(nil, blastCells["1:3"])
        TestRunner.assertEqual(nil, blastCells["6:8"])
        TestRunner.assertEqual(2, board[4][4].gemType)
        TestRunner.assertEqual(1, board[4][5].gemType)
        TestRunner.assertEqual(1, #effects)
        TestRunner.assertEqual("bombCombo", effects[1].effectType)
        TestRunner.assertEqual(4, effects[1].row)
        TestRunner.assertEqual(5, effects[1].column)
        TestRunner.assertEqual(2, effects[1].radius)
    end)

    TestRunner.it("centers a vertical blast on the destination", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = cell(((row + column) % 7) + 1)
            end
        end
        board[4][4] = cell(1, "explosive")
        board[5][4] = cell(2, "explosive")

        -- When
        local accepted, blastCells = Board.TrySwap(board, 4, 4, 5, 4)

        -- Then
        local clearedCount = 0
        for _ in pairs(blastCells) do
            clearedCount = clearedCount + 1
        end

        TestRunner.assertTrue(accepted)
        TestRunner.assertEqual(25, clearedCount)
        TestRunner.assertTrue(blastCells["3:2"])
        TestRunner.assertTrue(blastCells["7:6"])
        TestRunner.assertEqual(nil, blastCells["2:2"])
        TestRunner.assertEqual(nil, blastCells["7:7"])
    end)
end)
