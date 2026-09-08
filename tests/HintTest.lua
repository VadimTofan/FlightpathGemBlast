local TestRunner = require("tests.TestRunner")
local Hint = require("Game.Hint")

-- Inactivity hint timing
TestRunner.describe("Hint", function()
    local move = {
        fromRow = 4,
        fromColumn = 4,
        toRow = 4,
        toColumn = 5,
    }

    TestRunner.it("starts a hint after ten active seconds", function()
        -- Given
        local hint = Hint.New(10, 0.4, 3)
        local findCalls = 0
        local function findMove()
            findCalls = findCalls + 1
            return move
        end

        -- When
        local earlyMove = hint:Update(9.9, true, findMove)
        local hintedMove = hint:Update(0.1, true, findMove)

        -- Then
        TestRunner.assertEqual(nil, earlyMove)
        TestRunner.assertEqual(move, hintedMove)
        TestRunner.assertEqual(1, findCalls)
    end)

    TestRunner.it("pauses while hints cannot run", function()
        -- Given
        local hint = Hint.New(10, 0.4, 3)
        local function findMove()
            return move
        end

        -- When
        hint:Update(9, true, findMove)
        local pausedMove = hint:Update(30, false, findMove)
        local resumedMove = hint:Update(1, true, findMove)

        -- Then
        TestRunner.assertEqual(nil, pausedMove)
        TestRunner.assertEqual(move, resumedMove)
    end)

    TestRunner.it("resets the inactivity timer", function()
        -- Given
        local hint = Hint.New(10, 0.4, 3)
        local function findMove()
            return move
        end
        hint:Update(9, true, findMove)

        -- When
        hint:Reset()
        local hintedMove = hint:Update(1, true, findMove)

        -- Then
        TestRunner.assertEqual(nil, hintedMove)
    end)

    TestRunner.it("keeps bouncing until the hint is reset", function()
        -- Given
        local hint = Hint.New(10, 0.4, 3)
        local findCalls = 0
        local function findMove()
            findCalls = findCalls + 1
            return move
        end
        hint:Update(10, true, findMove)

        -- When
        local firstMove, firstOffset = hint:Update(0.2, true, findMove)
        local restingMove, restingOffset, finished =
            hint:Update(0.2, true, findMove)
        local repeatedMove, repeatedOffset =
            hint:Update(0.2, true, findMove)

        -- Then
        TestRunner.assertEqual(move, firstMove)
        TestRunner.assertEqual(3, firstOffset)
        TestRunner.assertEqual(move, restingMove)
        TestRunner.assertEqual(0, restingOffset)
        TestRunner.assertFalse(finished)
        TestRunner.assertEqual(move, repeatedMove)
        TestRunner.assertEqual(3, repeatedOffset)
        TestRunner.assertEqual(1, findCalls)
    end)
end)
