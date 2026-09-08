local _, addon = ...
local Board = type(addon) == "table" and addon.Board
    or require("Game.Board")
local Scoring = type(addon) == "table" and addon.Scoring
    or require("Game.Scoring")

local MovePlanner = {}

local function cloneBoard(board)
    local clone = {}

    for row = 1, 8 do
        clone[row] = {}

        for column = 1, 8 do
            local cell = board[row][column]
            clone[row][column] = {
                gemType = cell.gemType,
                special = cell.special,
            }
        end
    end

    return clone
end

local function copyPositions(positions)
    local copy = {}

    for position in pairs(positions) do
        copy[position] = true
    end

    return copy
end

local function appendBombEffects(target, bombEffects, initialEffects)
    local excludedBombs

    for _, effect in ipairs(initialEffects) do
        if effect.effectType == "bombCombo" then
            excludedBombs = effect.excludedBombs
            break
        end
    end

    for _, effect in ipairs(bombEffects) do
        local position = effect.row .. ":" .. effect.column
        if not excludedBombs or not excludedBombs[position] then
            target[#target + 1] = effect
        end
    end
end

local function recordFalls(board)
    local falls = {}

    for column = 1, 8 do
        local destinationRow = 8

        for row = 8, 1, -1 do
            if board[row][column] then
                if row ~= destinationRow then
                    falls[#falls + 1] = {
                        fromRow = row,
                        toRow = destinationRow,
                        column = column,
                    }
                end

                destinationRow = destinationRow - 1
            end
        end
    end

    return falls
end

local function recordRefills(board)
    local refills = {}

    for column = 1, 8 do
        local spawnIndex = 0

        for row = 8, 1, -1 do
            if not board[row][column] then
                spawnIndex = spawnIndex + 1
                refills[#refills + 1] = {
                    row = row,
                    column = column,
                    startRow = -spawnIndex,
                }
            end
        end
    end

    return refills
end

local function addResolutionSteps(
    plan,
    board,
    score,
    initialMatches,
    initialEffects,
    random
)
    local cascadeDepth = 1
    local matches = initialMatches
    local effects = initialEffects or {}

    while matches or Board.HasMatch(board) do
        matches = matches or Board.FindMatches(board)
        local specialRow
        local specialColumn
        local specialType
        local specialGemType

        if not initialMatches then
            specialRow, specialColumn, specialType = Board.DetermineSpecial(
                board,
                matches,
                plan.toRow,
                plan.toColumn
            )

            if specialRow then
                specialGemType = board[specialRow][specialColumn].gemType
                matches[specialRow .. ":" .. specialColumn] = nil
            end
        end

        local bombEffects
        matches, bombEffects = Board.ExpandSpecialEffects(
            board,
            matches,
            random
        )
        appendBombEffects(effects, bombEffects, effects)
        local clearPositions = copyPositions(matches)
        local cleared = Board.ClearCells(board, matches)
        score = score + Scoring.PointsForClear(cleared, cascadeDepth)

        if specialRow then
            board[specialRow][specialColumn] = {
                gemType = specialGemType,
                special = specialType,
            }
        end

        plan.steps[#plan.steps + 1] = {
            kind = "clear",
            positions = clearPositions,
            effects = effects,
            score = score,
            special = specialRow and {
                row = specialRow,
                column = specialColumn,
                specialType = specialType,
            } or nil,
        }

        local falls = recordFalls(board)
        Board.ApplyGravity(board)
        local refills = recordRefills(board)
        Board.Refill(board, random)

        plan.steps[#plan.steps + 1] = {
            kind = "settle",
            board = cloneBoard(board),
            falls = falls,
            refills = refills,
            cascadeDepth = cascadeDepth,
        }

        cascadeDepth = cascadeDepth + 1
        initialMatches = nil
        effects = {}
        matches = nil
    end

    return score
end

function MovePlanner.Plan(
    liveBoard,
    score,
    fromRow,
    fromColumn,
    toRow,
    toColumn,
    random
)
    local board = cloneBoard(liveBoard)
    local accepted, specialMatches, specialEffects = Board.TrySwap(
        board,
        fromRow,
        fromColumn,
        toRow,
        toColumn
    )
    local plan = {
        accepted = accepted,
        fromRow = fromRow,
        fromColumn = fromColumn,
        toRow = toRow,
        toColumn = toColumn,
        steps = {
            {
                kind = "swap",
                valid = accepted,
                fromRow = fromRow,
                fromColumn = fromColumn,
                toRow = toRow,
                toColumn = toColumn,
            },
        },
        finalBoard = liveBoard,
        finalScore = score,
    }

    if not accepted then
        return plan
    end

    plan.steps[1].board = cloneBoard(board)
    plan.finalScore = addResolutionSteps(
        plan,
        board,
        score,
        specialMatches,
        specialEffects,
        random
    )

    if not Board.HasValidMove(board) then
        board = Board.Reshuffle(board, random)
        plan.steps[#plan.steps + 1] = {
            kind = "reshuffle",
            board = cloneBoard(board),
        }
    end

    plan.finalBoard = board

    return plan
end

if type(addon) == "table" then
    addon.MovePlanner = MovePlanner
end

return MovePlanner
