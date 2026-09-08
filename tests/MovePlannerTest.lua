local TestRunner = require("tests.TestRunner")
local MovePlanner = require("Game.MovePlanner")

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

local function validSwapBoard()
    local board = patternedBoard()
    board[1][1] = cell(1)
    board[1][2] = cell(2)
    board[1][3] = cell(1)
    board[2][2] = cell(1)

    return board
end

-- Move planning
TestRunner.describe("MovePlanner.Plan", function()
    TestRunner.it("plans a valid move without changing the live board", function()
        -- Given
        local board = validSwapBoard()
        local originalGem = board[1][2].gemType

        -- When
        local plan = MovePlanner.Plan(board, 0, 1, 2, 2, 2)

        -- Then
        TestRunner.assertTrue(plan.accepted)
        TestRunner.assertEqual(originalGem, board[1][2].gemType)
        TestRunner.assertEqual("swap", plan.steps[1].kind)
        TestRunner.assertEqual("clear", plan.steps[2].kind)
        TestRunner.assertEqual("settle", plan.steps[3].kind)
    end)

    TestRunner.it("plans an invalid swap that returns to its origin", function()
        -- Given
        local board = patternedBoard()

        -- When
        local plan = MovePlanner.Plan(board, 0, 1, 1, 1, 2)

        -- Then
        TestRunner.assertFalse(plan.accepted)
        TestRunner.assertEqual(1, #plan.steps)
        TestRunner.assertFalse(plan.steps[1].valid)
        TestRunner.assertEqual(0, plan.finalScore)
    end)

    TestRunner.it("animates a double-bomb swap before its larger clear", function()
        -- Given
        local board = {
            {
                { gemType = 1 }, { gemType = 2 }, { gemType = 3 },
                { gemType = 4 }, { gemType = 5 }, { gemType = 6 },
                { gemType = 7 }, { gemType = 1 },
            },
        }
        for row = 2, 8 do
            board[row] = {}
            for column = 1, 8 do
                board[row][column] = {
                    gemType = ((row * 2 + column) % 7) + 1,
                }
            end
        end
        board[4][4] = { gemType = 1, special = "explosive" }
        board[4][5] = { gemType = 2, special = "explosive" }
        math.randomseed(24680)

        -- When
        local plan = MovePlanner.Plan(board, 0, 4, 4, 4, 5)

        -- Then
        local clearedCount = 0
        for _ in pairs(plan.steps[2].positions) do
            clearedCount = clearedCount + 1
        end

        TestRunner.assertTrue(plan.accepted)
        TestRunner.assertEqual("swap", plan.steps[1].kind)
        TestRunner.assertEqual("clear", plan.steps[2].kind)
        TestRunner.assertEqual(16, clearedCount)
    end)

    TestRunner.it("uses the special-preserving reshuffle path", function()
        -- Given
        local file = assert(io.open("Game/MovePlanner.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local preservesSpecials = source:find(
            "Board.Reshuffle(board, random)",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(preservesSpecials)
    end)
end)
