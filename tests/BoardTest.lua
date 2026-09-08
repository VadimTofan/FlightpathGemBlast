local TestRunner = require("tests.TestRunner")
local Board = require("Game.Board")

-- Board creation
TestRunner.describe("Board.Create", function()
    TestRunner.it("creates an eight by eight board", function()
        -- Given
        local random = function()
            return 1
        end

        -- When
        local board = Board.Create(random)

        -- Then
        TestRunner.assertEqual(8, #board)
        for row = 1, 8 do
            TestRunner.assertEqual(8, #board[row])
        end
    end)

    TestRunner.it("creates only known gem types", function()
        -- Given
        math.randomseed(12345)

        -- When
        local board = Board.Create()

        -- Then
        for row = 1, 8 do
            for column = 1, 8 do
                local gemType = board[row][column].gemType
                TestRunner.assertTrue(gemType >= 1 and gemType <= 7)
            end
        end
    end)

    TestRunner.it("starts without existing matches", function()
        -- Given
        local random = nil

        -- When
        local board = Board.Create(random)

        -- Then
        TestRunner.assertFalse(Board.HasMatch(board))
    end)

    TestRunner.it("starts with at least one valid move", function()
        -- Given
        local random = nil

        -- When
        local board = Board.Create(random)

        -- Then
        TestRunner.assertTrue(Board.HasValidMove(board))
    end)
end)

-- Board reshuffling
TestRunner.describe("Board.Reshuffle", function()
    TestRunner.it("preserves every bomb and spark on a playable board", function()
        -- Given
        math.randomseed(13579)
        local board = Board.Create()
        board[1][1].special = "explosive"
        board[2][2].special = "explosive"
        board[3][3].special = "color"
        board[4][4].special = "color"

        -- When
        math.randomseed(97531)
        local reshuffled = Board.Reshuffle(board)

        -- Then
        local bombs = 0
        local sparks = 0
        for row = 1, 8 do
            for column = 1, 8 do
                local special = reshuffled[row][column].special
                bombs = bombs + (special == "explosive" and 1 or 0)
                sparks = sparks + (special == "color" and 1 or 0)
            end
        end

        TestRunner.assertEqual(2, bombs)
        TestRunner.assertEqual(2, sparks)
        TestRunner.assertFalse(Board.HasMatch(reshuffled))
        TestRunner.assertTrue(Board.HasValidMove(reshuffled))
    end)
end)

-- Special moves remain available
TestRunner.describe("Board.HasValidMove special gems", function()
    local function sparseBoard()
        local board = {}

        for row = 1, 8 do
            board[row] = {}
        end

        return board
    end

    TestRunner.it("recognizes a spark beside a normal gem", function()
        -- Given
        local board = sparseBoard()
        board[4][4] = { gemType = 1, special = "color" }
        board[4][5] = { gemType = 2 }

        -- When
        local hasMove = Board.HasValidMove(board)

        -- Then
        TestRunner.assertTrue(hasMove)
    end)

    TestRunner.it("recognizes two adjacent bombs", function()
        -- Given
        local board = sparseBoard()
        board[4][4] = { gemType = 1, special = "explosive" }
        board[4][5] = { gemType = 2, special = "explosive" }

        -- When
        local hasMove = Board.HasValidMove(board)

        -- Then
        TestRunner.assertTrue(hasMove)
    end)
end)

-- Hint move selection
TestRunner.describe("Board.FindValidMove", function()
    TestRunner.it("returns the coordinates of a spark move", function()
        -- Given
        local board = {}
        for row = 1, 8 do
            board[row] = {}
        end
        board[4][4] = { gemType = 1, special = "color" }
        board[4][5] = { gemType = 2 }

        -- When
        local fromRow, fromColumn, toRow, toColumn =
            Board.FindValidMove(board)

        -- Then
        TestRunner.assertEqual(4, fromRow)
        TestRunner.assertEqual(4, fromColumn)
        TestRunner.assertEqual(4, toRow)
        TestRunner.assertEqual(5, toColumn)
    end)
end)
