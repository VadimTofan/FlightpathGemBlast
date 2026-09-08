local MinimapPosition = {}
local _, addon = ...

local ROUND_QUADRANTS = {
    ROUND = { true, true, true, true },
    SQUARE = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
}

function MinimapPosition.Calculate(
    angle,
    width,
    height,
    shape,
    padding
)
    local radians = math.rad(angle)
    local directionX = math.cos(radians)
    local directionY = math.sin(radians)
    local halfWidth = width / 2 + padding
    local halfHeight = height / 2 + padding

    local quadrant = 1
    if directionX < 0 then
        quadrant = quadrant + 1
    end
    if directionY > 0 then
        quadrant = quadrant + 2
    end

    local roundQuadrants = ROUND_QUADRANTS[shape]
        or ROUND_QUADRANTS.ROUND
    if roundQuadrants[quadrant] then
        return directionX * halfWidth, directionY * halfHeight
    end

    local diagonalWidth = math.sqrt(2 * halfWidth * halfWidth) - 10
    local diagonalHeight = math.sqrt(2 * halfHeight * halfHeight) - 10
    local x = math.max(
        -halfWidth,
        math.min(directionX * diagonalWidth, halfWidth)
    )
    local y = math.max(
        -halfHeight,
        math.min(directionY * diagonalHeight, halfHeight)
    )

    return x, y
end

if type(addon) == "table" then
    addon.MinimapPosition = MinimapPosition
end

return MinimapPosition
