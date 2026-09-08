local Input = {}
local _, addon = ...

function Input.GetSelectionAction(
    selectedRow,
    selectedColumn,
    row,
    column
)
    if not selectedRow then
        return "select"
    end

    local rowDistance = math.abs(selectedRow - row)
    local columnDistance = math.abs(selectedColumn - column)

    if rowDistance + columnDistance == 1 then
        return "swap"
    end

    return "deselect"
end

function Input.GetDragTarget(row, column, deltaX, deltaY, boardSize)
    local targetRow = row
    local targetColumn = column

    if math.abs(deltaX) > math.abs(deltaY) then
        targetColumn = column + (deltaX > 0 and 1 or -1)
    else
        targetRow = row + (deltaY > 0 and -1 or 1)
    end

    if targetRow < 1 or targetRow > boardSize
        or targetColumn < 1 or targetColumn > boardSize then
        return nil, nil
    end

    return targetRow, targetColumn
end

if type(addon) == "table" then
    addon.Input = Input
end

return Input
