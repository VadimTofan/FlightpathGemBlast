local Board = {}
local _, addon = ...

local BOARD_SIZE = 8
local GEM_TYPE_COUNT = 7

local function getGemType(cell)
    return cell and cell.gemType
end

local function createsMatchAt(board, row, column, gemType)
    local horizontalMatch = column >= 3
        and getGemType(board[row][column - 1]) == gemType
        and getGemType(board[row][column - 2]) == gemType
    local verticalMatch = row >= 3
        and getGemType(board[row - 1][column]) == gemType
        and getGemType(board[row - 2][column]) == gemType

    return horizontalMatch or verticalMatch
end

local function defaultRandom(minimum, maximum)
    return math.random(minimum, maximum)
end

function Board.FindMatches(board)
    local matches = {}

    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            local gemType = getGemType(board[row][column])
            local horizontalStart = column == 1
                or getGemType(board[row][column - 1]) ~= gemType
            local verticalStart = row == 1
                or getGemType(board[row - 1][column]) ~= gemType

            if gemType and horizontalStart then
                local runLength = 1
                while column + runLength <= BOARD_SIZE
                    and getGemType(board[row][column + runLength]) == gemType do
                    runLength = runLength + 1
                end

                if runLength >= 3 then
                    for offset = 0, runLength - 1 do
                        matches[row .. ":" .. (column + offset)] = true
                    end
                end
            end

            if gemType and verticalStart then
                local runLength = 1
                while row + runLength <= BOARD_SIZE
                    and getGemType(board[row + runLength][column]) == gemType do
                    runLength = runLength + 1
                end

                if runLength >= 3 then
                    for offset = 0, runLength - 1 do
                        matches[(row + offset) .. ":" .. column] = true
                    end
                end
            end
        end
    end

    return matches
end

function Board.HasMatch(board)
    return next(Board.FindMatches(board)) ~= nil
end

function Board.AreAdjacent(firstRow, firstColumn, secondRow, secondColumn)
    local rowDistance = math.abs(firstRow - secondRow)
    local columnDistance = math.abs(firstColumn - secondColumn)

    return rowDistance + columnDistance == 1
end

local function swap(board, firstRow, firstColumn, secondRow, secondColumn)
    board[firstRow][firstColumn], board[secondRow][secondColumn] =
        board[secondRow][secondColumn], board[firstRow][firstColumn]
end

local function getCombinedBombBlastCells(centerRow, centerColumn)
    local cells = {}
    local firstRow = math.max(1, centerRow - 2)
    local lastRow = math.min(BOARD_SIZE, centerRow + 2)
    local firstColumn = math.max(1, centerColumn - 2)
    local lastColumn = math.min(BOARD_SIZE, centerColumn + 2)

    for row = firstRow, lastRow do
        for column = firstColumn, lastColumn do
            cells[row .. ":" .. column] = true
        end
    end

    return cells
end

local function turnMatchedColorIntoBombs(board, matches, gemType)
    for position in pairs(matches) do
        local row, column = string.match(position, "^(%d+):(%d+)$")
        local cell = board[tonumber(row)][tonumber(column)]

        if cell
            and cell.gemType == gemType
            and cell.special ~= "color" then
            cell.special = "explosive"
        end
    end
end

function Board.TrySwap(board, firstRow, firstColumn, secondRow, secondColumn)
    if not Board.AreAdjacent(
        firstRow,
        firstColumn,
        secondRow,
        secondColumn
    ) then
        return false
    end


    local firstCell = board[firstRow][firstColumn]
    local secondCell = board[secondRow][secondColumn]
    local firstIsColor = firstCell.special == "color"
    local secondIsColor = secondCell.special == "color"
    local firstIsExplosive = firstCell.special == "explosive"
    local secondIsExplosive = secondCell.special == "explosive"
    local isColorBombSwap = firstIsColor and secondIsExplosive
        or secondIsColor and firstIsExplosive

    if firstIsExplosive and secondIsExplosive then
        swap(board, firstRow, firstColumn, secondRow, secondColumn)

        return true, getCombinedBombBlastCells(secondRow, secondColumn), {
            {
                effectType = "bombCombo",
                row = secondRow,
                column = secondColumn,
                radius = 2,
                excludedBombs = {
                    [firstRow .. ":" .. firstColumn] = true,
                    [secondRow .. ":" .. secondColumn] = true,
                },
            },
        }
    end

    if firstIsColor or secondIsColor then
        local clearedGemType = firstIsColor
            and secondCell.gemType
            or firstCell.gemType

        swap(board, firstRow, firstColumn, secondRow, secondColumn)

        local matches = Board.ColorClearCells(board, clearedGemType)
        local colorRow = firstIsColor and secondRow or firstRow
        local colorColumn = firstIsColor and secondColumn or firstColumn
        matches[colorRow .. ":" .. colorColumn] = true

        if isColorBombSwap then
            turnMatchedColorIntoBombs(board, matches, clearedGemType)
        end

        return true, matches, {
            {
                effectType = "spark",
                row = colorRow,
                column = colorColumn,
                gemType = clearedGemType,
            },
        }
    end

    swap(board, firstRow, firstColumn, secondRow, secondColumn)

    if Board.HasMatch(board) then
        return true
    end

    swap(board, firstRow, firstColumn, secondRow, secondColumn)

    return false
end

function Board.ClearCells(board, matches)
    local cleared = 0

    for position in pairs(matches) do
        local row, column = string.match(position, "^(%d+):(%d+)$")
        row = tonumber(row)
        column = tonumber(column)

        if board[row][column] then
            board[row][column] = nil
            cleared = cleared + 1
        end
    end

    return cleared
end


function Board.ApplyGravity(board)
    for column = 1, BOARD_SIZE do
        local destinationRow = BOARD_SIZE

        for row = BOARD_SIZE, 1, -1 do
            if board[row][column] then
                board[destinationRow][column] = board[row][column]

                if destinationRow ~= row then
                    board[row][column] = nil
                end

                destinationRow = destinationRow - 1
            end
        end

        for row = destinationRow, 1, -1 do
            board[row][column] = nil
        end
    end
end

function Board.Refill(board, random)
    local randomFunction = random or defaultRandom
    local added = 0

    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            if not board[row][column] then
                board[row][column] = {
                    gemType = randomFunction(1, GEM_TYPE_COUNT),
                    special = nil,
                }
                added = added + 1
            end
        end
    end

    return added
end

local function getRandomPresentGemType(board, randomFunction)
    local presentGemTypes = {}
    local choices = {}

    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            local cell = board[row][column]
            if cell and cell.special ~= "color" then
                presentGemTypes[cell.gemType] = true
            end
        end
    end

    for gemType = 1, GEM_TYPE_COUNT do
        if presentGemTypes[gemType] then
            choices[#choices + 1] = gemType
        end
    end

    if #choices == 0 then
        return nil
    end

    return choices[randomFunction(1, #choices)]
end

function Board.ExpandSpecialEffects(board, matches, random)
    local randomFunction = random or defaultRandom
    local expanded = {}
    local pending = {}
    local pendingBombTriggers = {}
    local effects = {}
    local triggeredBombs = {}
    local triggeredSparks = {}

    for position in pairs(matches) do
        expanded[position] = true
        pending[#pending + 1] = position
        pendingBombTriggers[#pendingBombTriggers + 1] = false
    end

    local index = 1
    while index <= #pending do
        local position = pending[index]
        local wasHitByBomb = pendingBombTriggers[index]
        local row, column = string.match(position, "^(%d+):(%d+)$")
        row = tonumber(row)
        column = tonumber(column)
        local cell = board[row][column]

        if cell
            and cell.special == "explosive"
            and not triggeredBombs[position] then
            triggeredBombs[position] = true
            effects[#effects + 1] = {
                effectType = "bomb",
                row = row,
                column = column,
                radius = 1,
            }

            for targetRow = math.max(1, row - 1),
                math.min(BOARD_SIZE, row + 1) do
                for targetColumn = math.max(1, column - 1),
                    math.min(BOARD_SIZE, column + 1) do
                    local target = targetRow .. ":" .. targetColumn
                    local targetCell = board[targetRow][targetColumn]

                    if not expanded[target] then
                        expanded[target] = true
                        pending[#pending + 1] = target
                        pendingBombTriggers[#pendingBombTriggers + 1] = true
                    elseif targetCell
                        and targetCell.special == "color"
                        and not triggeredSparks[target] then
                        pending[#pending + 1] = target
                        pendingBombTriggers[#pendingBombTriggers + 1] = true
                    end
                end
            end
        elseif cell
            and cell.special == "color"
            and wasHitByBomb
            and not triggeredSparks[position] then
            triggeredSparks[position] = true

            local gemType = getRandomPresentGemType(board, randomFunction)
            if gemType then
                effects[#effects + 1] = {
                    effectType = "spark",
                    row = row,
                    column = column,
                    gemType = gemType,
                }

                for target in pairs(Board.ColorClearCells(board, gemType)) do
                    if not expanded[target] then
                        expanded[target] = true
                        pending[#pending + 1] = target
                        pendingBombTriggers[#pendingBombTriggers + 1] = false
                    end
                end
            end
        end

        index = index + 1
    end

    return expanded, effects
end

function Board.ColorClearCells(board, gemType)
    local matches = {}

    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            local cell = board[row][column]
            if cell and cell.gemType == gemType then
                matches[row .. ":" .. column] = true
            end
        end
    end

    return matches
end

local function countMatchedDirection(matches, row, column, rowStep, columnStep)
    local count = 1
    local targetRow = row + rowStep
    local targetColumn = column + columnStep

    while matches[targetRow .. ":" .. targetColumn] do
        count = count + 1
        targetRow = targetRow + rowStep
        targetColumn = targetColumn + columnStep
    end

    targetRow = row - rowStep
    targetColumn = column - columnStep

    while matches[targetRow .. ":" .. targetColumn] do
        count = count + 1
        targetRow = targetRow - rowStep
        targetColumn = targetColumn - columnStep
    end

    return count
end

function Board.DetermineSpecial(board, matches, preferredRow, preferredColumn)
    local candidates = {}
    local preferredPosition = preferredRow .. ":" .. preferredColumn

    if matches[preferredPosition] then
        candidates[1] = preferredPosition
    end

    for position in pairs(matches) do
        if position ~= preferredPosition then
            candidates[#candidates + 1] = position
        end
    end

    local explosiveCandidate

    for _, position in ipairs(candidates) do
        local row, column = string.match(position, "^(%d+):(%d+)$")
        row = tonumber(row)
        column = tonumber(column)
        local horizontal = countMatchedDirection(matches, row, column, 0, 1)
        local vertical = countMatchedDirection(matches, row, column, 1, 0)

        if horizontal >= 5 or vertical >= 5 then
            return row, column, "color"
        end

        if horizontal >= 4 or vertical >= 4
            or (horizontal >= 3 and vertical >= 3) then
            explosiveCandidate = explosiveCandidate or { row, column }
        end
    end

    if explosiveCandidate then
        return explosiveCandidate[1], explosiveCandidate[2], "explosive"
    end

    return nil
end

function Board.FindValidMove(board)
    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            local neighbours = {
                { row = row, column = column + 1 },
                { row = row + 1, column = column },
            }

            for _, neighbour in ipairs(neighbours) do
                if neighbour.row <= BOARD_SIZE
                    and neighbour.column <= BOARD_SIZE then
                    local firstCell = board[row][column]
                    local secondCell = board[neighbour.row][neighbour.column]
                    local hasColorSpecial = firstCell and secondCell
                        and (firstCell.special == "color"
                            or secondCell.special == "color")
                    local hasTwoBombs = firstCell and secondCell
                        and firstCell.special == "explosive"
                        and secondCell.special == "explosive"

                    if hasColorSpecial or hasTwoBombs then
                        return row,
                            column,
                            neighbour.row,
                            neighbour.column
                    end

                    swap(
                        board,
                        row,
                        column,
                        neighbour.row,
                        neighbour.column
                    )
                    local createsMatch = Board.HasMatch(board)
                    swap(
                        board,
                        row,
                        column,
                        neighbour.row,
                        neighbour.column
                    )

                    if createsMatch then
                        return row,
                            column,
                            neighbour.row,
                            neighbour.column
                    end
                end
            end
        end
    end

    return nil
end

function Board.HasValidMove(board)
    return Board.FindValidMove(board) ~= nil
end

local function createCandidateBoard(random)
    local board = {}

    for row = 1, BOARD_SIZE do
        board[row] = {}

        for column = 1, BOARD_SIZE do
            local gemType = random(1, GEM_TYPE_COUNT)

            while createsMatchAt(board, row, column, gemType) do
                gemType = (gemType % GEM_TYPE_COUNT) + 1
            end

            board[row][column] = {
                gemType = gemType,
                special = nil,
            }
        end
    end

    return board
end

function Board.Create(random)
    local randomFunction = random or defaultRandom

    for _ = 1, 100 do
        local board = createCandidateBoard(randomFunction)
        if Board.HasValidMove(board) then
            return board
        end
    end

    error("Unable to create a playable board")
end

function Board.Reshuffle(board, random)
    local randomFunction = random or defaultRandom
    local specials = {}

    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            local cell = board[row][column]
            if cell and cell.special then
                specials[#specials + 1] = cell.special
            end
        end
    end

    local reshuffled = Board.Create(randomFunction)
    local availablePositions = {}

    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            availablePositions[#availablePositions + 1] = {
                row = row,
                column = column,
            }
        end
    end

    for _, special in ipairs(specials) do
        local positionIndex = randomFunction(1, #availablePositions)
        local position = table.remove(availablePositions, positionIndex)
        reshuffled[position.row][position.column].special = special
    end

    return reshuffled
end

if type(addon) == "table" then
    addon.Board = Board
end

return Board
