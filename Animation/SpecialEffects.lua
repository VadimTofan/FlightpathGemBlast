local _, addon = ...

local SpecialEffects = {}

local CLEAR_DURATIONS = {
    bomb = 0.28,
    lineBomb = 0.34,
    crossBomb = 0.38,
    wideLineBomb = 0.38,
    spark = 0.34,
    bombCombo = 0.38,
}

local GEM_EFFECT_COLORS = {
    [1] = { 0.25, 0.65, 1.00 },
    [2] = { 1.00, 0.25, 0.30 },
    [3] = { 0.35, 1.00, 0.45 },
    [4] = { 0.85, 0.35, 1.00 },
    [5] = { 1.00, 0.85, 0.20 },
    [6] = { 0.35, 0.90, 1.00 },
    [7] = { 1.00, 0.50, 0.20 },
}

local function clamp(value)
    return math.max(0, math.min(1, value))
end

local function getEffectProgress(effect, row, column, progress)
    local rowDistance = math.abs(row - effect.row)
    local columnDistance = math.abs(column - effect.column)
    local delay

    if effect.effectType == "spark" then
        delay = math.min(0.30, (rowDistance + columnDistance) * 0.025)
    elseif effect.effectType == "lineBomb"
        or effect.effectType == "crossBomb"
        or effect.effectType == "wideLineBomb" then
        local isHorizontal = rowDistance == 0
        local isVertical = columnDistance == 0
        local isWideHorizontal = effect.direction == "horizontal"
            and rowDistance <= 1
        local isWideVertical = effect.direction == "vertical"
            and columnDistance <= 1
        local isAffected = effect.effectType == "crossBomb"
            and (isHorizontal or isVertical)
            or effect.effectType == "lineBomb"
                and ((effect.direction == "horizontal" and isHorizontal)
                    or (effect.direction == "vertical" and isVertical))
            or effect.effectType == "wideLineBomb"
                and (isWideHorizontal or isWideVertical)

        if not isAffected then
            return nil
        end

        delay = math.min(0.28, math.max(rowDistance, columnDistance) * 0.04)
    else
        local distance = math.max(rowDistance, columnDistance)

        if distance > (effect.radius or 0) then
            return nil
        end

        delay = distance * 0.08
    end

    if progress <= delay then
        return 0
    end

    return clamp((progress - delay) / (1 - delay))
end

local function getEffectColor(effect, isSource)
    if effect.effectType == "spark" then
        if isSource then
            return 0.75, 0.90, 1.00
        end

        local color = GEM_EFFECT_COLORS[effect.gemType]
            or GEM_EFFECT_COLORS[6]

        return color[1], color[2], color[3]
    end

    if effect.effectType == "bombCombo" then
        return 1.00, 0.68, 0.12
    end

    if effect.effectType == "lineBomb"
        or effect.effectType == "crossBomb"
        or effect.effectType == "wideLineBomb" then
        return 0.25, 0.85, 1.00
    end

    return 1.00, 0.48, 0.08
end

function SpecialEffects.GetClearDuration(effects)
    local duration = 0.18

    for _, effect in ipairs(effects or {}) do
        duration = math.max(
            duration,
            CLEAR_DURATIONS[effect.effectType] or 0
        )
    end

    return duration
end

function SpecialEffects.GetCellVisual(effects, row, column, progress)
    local clampedProgress = clamp(progress)

    if not effects or #effects == 0 then
        return 1 - clampedProgress * 0.65,
            1 - clampedProgress,
            1,
            0,
            0,
            1,
            1,
            1
    end

    local selectedEffect
    local selectedProgress
    local selectedAlpha = -1
    local selectedIsSource = false

    for _, effect in ipairs(effects) do
        local effectProgress = getEffectProgress(
            effect,
            row,
            column,
            clampedProgress
        )

        if effectProgress then
            local isSource = row == effect.row and column == effect.column
            local alpha

            if effect.effectType == "spark" and isSource then
                alpha = math.abs(math.sin(effectProgress * math.pi * 2))
            else
                alpha = math.sin(effectProgress * math.pi)
            end

            local shouldSelect = isSource and not selectedIsSource
                or isSource == selectedIsSource and alpha > selectedAlpha

            if shouldSelect then
                selectedEffect = effect
                selectedProgress = effectProgress
                selectedAlpha = alpha
                selectedIsSource = isSource
            end
        end
    end

    if not selectedEffect then
        return 1 - clampedProgress * 0.65,
            1 - clampedProgress,
            1,
            0,
            0,
            1,
            1,
            1
    end

    local pulse = math.sin(selectedProgress * math.pi)
    local gemScale = 1 + pulse * 0.12 - selectedProgress * 0.65
    local gemAlpha = 1 - selectedProgress
    local isSource = row == selectedEffect.row
        and column == selectedEffect.column
    local effectScale
    local rotation

    if selectedEffect.effectType == "bombCombo" and isSource then
        effectScale = 0.60 + selectedProgress * 5.20
        rotation = selectedProgress * math.pi * 0.75
    elseif selectedEffect.effectType == "bomb" and isSource then
        effectScale = 0.45 + selectedProgress * 2.60
        rotation = selectedProgress * math.pi / 3
    elseif selectedEffect.effectType == "spark" and isSource then
        effectScale = 0.70 + selectedProgress * 1.80
        rotation = selectedProgress * math.pi
    elseif selectedEffect.effectType == "spark" then
        effectScale = 0.65 + pulse * 1.10
        rotation = selectedProgress * math.pi / 2
    else
        effectScale = 0.65 + pulse * 0.90
        rotation = selectedProgress * math.pi / 3
    end

    local red, green, blue = getEffectColor(selectedEffect, isSource)

    return gemScale,
        gemAlpha,
        effectScale,
        math.max(0, selectedAlpha),
        rotation,
        red,
        green,
        blue
end

if type(addon) == "table" then
    addon.SpecialEffects = SpecialEffects
end

return SpecialEffects
