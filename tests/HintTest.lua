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

    TestRunner.it("returns a small out-and-back bounce", function()
        -- Given
        local hint = Hint.New(10, 0.4, 3)
        local function findMove()
            return move
        end
        hint:Update(10, true, findMove)

        -- When
        local activeMove, middleOffset = hint:Update(0.2, true, findMove)
        local finishedMove, finalOffset, finished =
            hint:Update(0.2, true, findMove)

        -- Then
        TestRunner.assertEqual(move, activeMove)
        TestRunner.assertEqual(3, middleOffset)
        TestRunner.assertEqual(move, finishedMove)
        TestRunner.assertEqual(0, finalOffset)
        TestRunner.assertTrue(finished)
    end)
end)
