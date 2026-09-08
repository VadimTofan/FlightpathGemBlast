local TestRunner = require("tests.TestRunner")
local Board = require("Game.Board")

local function cell(gemType)
    return { gemType = gemType }
end

local function patternedBoard()
    local board = {}

    for row = 1, 8 do
        board[row] = {}
        for column = 1, 8 do
            board[row][column] = cell(((row * 2 + column) % 7) + 1)
        end
    end

    return board
end

-- Swap validation
TestRunner.describe("Board.TrySwap", function()
    TestRunner.it("rejects non-adjacent cells", function()
        -- Given
        local board = patternedBoard()

        -- When
        local accepted = Board.TrySwap(board, 1, 1, 3, 1)

        -- Then
        TestRunner.assertFalse(accepted)
    end)

    TestRunner.it("accepts an adjacent swap that creates a match", function()
        -- Given
        local board = patternedBoard()
        board[1][1] = cell(1)
        board[1][2] = cell(2)
        board[1][3] = cell(1)
        board[2][2] = cell(1)

        -- When
        local accepted = Board.TrySwap(board, 1, 2, 2, 2)

        -- Then
        TestRunner.assertTrue(accepted)
        TestRunner.assertTrue(Board.HasMatch(board))
    end)

    TestRunner.it("restores an adjacent swap that creates no match", function()
        -- Given
        local board = patternedBoard()
        local firstGem = board[1][1].gemType
        local secondGem = board[1][2].gemType

        -- When
        local accepted = Board.TrySwap(board, 1, 1, 1, 2)

        -- Then
        TestRunner.assertFalse(accepted)
        TestRunner.assertEqual(firstGem, board[1][1].gemType)
        TestRunner.assertEqual(secondGem, board[1][2].gemType)
    end)
end)

-- Board settling
TestRunner.describe("Board settling", function()
    TestRunner.it("clears matched cells and moves gems downward", function()
        -- Given
        local board = patternedBoard()
        board[6][1] = cell(1)
        board[7][1] = cell(1)
        board[8][1] = cell(1)
        local matches = Board.FindMatches(board)

        -- When
        local cleared = Board.ClearCells(board, matches)
        Board.ApplyGravity(board)

        -- Then
        TestRunner.assertEqual(3, cleared)
        TestRunner.assertEqual(nil, board[1][1])
        TestRunner.assertEqual(nil, board[2][1])
        TestRunner.assertEqual(nil, board[3][1])
    end)

    TestRunner.it("refills every empty cell", function()
        -- Given
        local board = patternedBoard()
        board[1][1] = nil
        board[2][1] = nil
        local random = function()
            return 7
        end

        -- When
        local added = Board.Refill(board, random)

        -- Then
        TestRunner.assertEqual(2, added)
        TestRunner.assertEqual(7, board[1][1].gemType)
        TestRunner.assertEqual(7, board[2][1].gemType)
    end)
end)
