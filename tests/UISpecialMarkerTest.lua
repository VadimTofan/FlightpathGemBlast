local TestRunner = require("tests.TestRunner")

TestRunner.describe("UI special-gem marker", function()
    TestRunner.it("replaces a color gem with a centered sparkle", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesWarningIcon = source:find(
            "services%-icon%-warning"
        ) ~= nil
        local usesLargeGlow = source:find(
            "UI%-ActionButton%-Border"
        ) ~= nil
        local usesSparkle = source:find("Cooldown\\\\star4") ~= nil
        local hidesColorGem = source:find(
            "button.gem:SetShown(not isColorSpecial)",
            1,
            true
        ) ~= nil
        local centersSparkle = source:find(
            'button.specialMarker:SetPoint("CENTER")',
            1,
            true
        ) ~= nil
        local outlinesSpecials = source:find(
            "border:SetShown(hasSpecial)",
            1,
            true
        ) ~= nil
        local usesSparkBorderColor = source:find(
            "local borderRed = isColorSpecial and 0.55 or 1",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertFalse(usesWarningIcon)
        TestRunner.assertFalse(usesLargeGlow)
        TestRunner.assertTrue(usesSparkle)
        TestRunner.assertTrue(hidesColorGem)
        TestRunner.assertTrue(centersSparkle)
        TestRunner.assertTrue(outlinesSpecials)
        TestRunner.assertTrue(usesSparkBorderColor)
    end)
end)

TestRunner.describe("UI special-gem movement", function()
    TestRunner.it("moves special borders with swaps falls and hints", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local hasUnifiedOffset = source:find(
            "setCellVisualOffset = function(button, x, y)",
            1,
            true
        ) ~= nil
        local movesTopBorder = source:find(
            'button.specialBorders.top:SetPoint("TOPLEFT", 1 + x, -1 + y)',
            1,
            true
        ) ~= nil
        local swapMovesVisual = source:find(
            "setCellVisualOffset(self.cells[step.fromRow][step.fromColumn], x, y)",
            1,
            true
        ) ~= nil
        local settleMovesVisual = source:find(
            "setCellVisualOffset(button, 0, y)",
            1,
            true
        ) ~= nil
        local hintMovesVisual = source:find(
            "setCellVisualOffset(self.cells[move.fromRow][move.fromColumn], x, y)",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasUnifiedOffset)
        TestRunner.assertTrue(movesTopBorder)
        TestRunner.assertTrue(swapMovesVisual)
        TestRunner.assertTrue(settleMovesVisual)
        TestRunner.assertTrue(hintMovesVisual)
    end)
end)

TestRunner.describe("UI special-effect animation", function()
    TestRunner.it("reuses one Blizzard effect texture per cell", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local createsPooledMarker = source:find(
            'button.effectMarker = button:CreateTexture(nil, "OVERLAY")',
            1,
            true
        ) ~= nil
        local usesBlizzardStar = source:find(
            'button.effectMarker:SetTexture("Interface\\\\Cooldown\\\\star4")',
            1,
            true
        ) ~= nil
        local usesVisualCalculator = source:find(
            "addon.SpecialEffects.GetCellVisual(",
            1,
            true
        ) ~= nil
        local updateStart = assert(source:find(
            "function UI:UpdateAnimationStep",
            1,
            true
        ))
        local updateEnd = assert(source:find(
            "function UI:FinishAnimationStep",
            updateStart,
            true
        ))
        local updateSource = source:sub(updateStart, updateEnd - 1)
        local allocatesDuringUpdate = updateSource:find(
            "CreateTexture",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(createsPooledMarker)
        TestRunner.assertTrue(usesBlizzardStar)
        TestRunner.assertTrue(usesVisualCalculator)
        TestRunner.assertFalse(allocatesDuringUpdate)
    end)
end)

TestRunner.describe("UI explosive-gem marker", function()
    TestRunner.it("uses a corner badge and cell outline", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesCornerBadge = source:find(
            'button.bombMarker:SetPoint("TOPRIGHT"',
            1,
            true
        ) ~= nil
        local usesCellOutline = source:find(
            "button.specialBorders",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesCornerBadge)
        TestRunner.assertTrue(usesCellOutline)
    end)
end)

TestRunner.describe("UI explosive-gem bomb badge", function()
    TestRunner.it("shows a dedicated bomb image for explosive gems", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local referencesBomb = source:find(
            "Media\\\\Bomb64.png",
            1,
            false
        ) ~= nil
        local limitsBombToExplosives = source:find(
            'cell.special == "explosive"',
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(referencesBomb)
        TestRunner.assertTrue(limitsBombToExplosives)
    end)
end)

TestRunner.describe("UI inactivity hint", function()
    TestRunner.it("updates a ten-second directional gem bounce", function()
        -- Given
        local file = assert(io.open("UI.lua", "r"))
        local source = file:read("*a")
        file:close()

        -- When
        local usesTenSeconds = source:find(
            "local HINT_DELAY = 10",
            1,
            true
        ) ~= nil
        local usesVisibleDistance = source:find(
            "local HINT_DISTANCE = 5",
            1,
            true
        ) ~= nil
        local findsMove = source:find(
            "addon.Board.FindValidMove",
            1,
            true
        ) ~= nil
        local updatesHint = source:find(
            "self.hint:Update",
            1,
            true
        ) ~= nil
        local resetsHint = source:find(
            "UI:ResetHint()",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesTenSeconds)
        TestRunner.assertTrue(usesVisibleDistance)
        TestRunner.assertTrue(findsMove)
        TestRunner.assertTrue(updatesHint)
        TestRunner.assertTrue(resetsHint)
    end)
end)
