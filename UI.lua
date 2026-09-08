local addonName, addon = ...

local CELL_SIZE = 42
local BOARD_SIZE = 8
local BOARD_INSET = 18
local LEADERBOARD_MAX_ENTRIES = 10
local HINT_DELAY = 10
local HINT_DURATION = 0.4
local HINT_DISTANCE = 5
local GEM_TEXTURE_PATH = "Interface\\AddOns\\" .. addonName
    .. "\\Media\\Gems64\\"
local BOMB_TEXTURE = "Interface\\AddOns\\" .. addonName
    .. "\\Media\\Bomb64.png"
local GEM_TEXTURES = {
    GEM_TEXTURE_PATH .. "Blue.png",
    GEM_TEXTURE_PATH .. "Red.png",
    GEM_TEXTURE_PATH .. "Green.png",
    GEM_TEXTURE_PATH .. "Yellow.png",
    GEM_TEXTURE_PATH .. "Orange.png",
    GEM_TEXTURE_PATH .. "Purple.png",
    GEM_TEXTURE_PATH .. "White.png",
}

local UI = {}
local setCellVisualOffset

local function easeOutCubic(progress)
    local remaining = 1 - progress

    return 1 - remaining * remaining * remaining
end

local function setGemTexture(texture, gemType)
    texture:SetTexture(GEM_TEXTURES[gemType])
    texture:SetTexCoord(0, 1, 0, 1)
end

local function addBorder(frame, size, red, green, blue)
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -size, size)
    border:SetPoint("BOTTOMRIGHT", size, -size)
    border:SetColorTexture(red, green, blue, 1)

    local background = frame:CreateTexture(nil, "ARTWORK")
    background:SetPoint("TOPLEFT", 0, 0)
    background:SetPoint("BOTTOMRIGHT", 0, 0)
    background:SetColorTexture(0.025, 0.025, 0.035, 0.98)
end

function UI:RenderBoard(board)
    for row = 1, BOARD_SIZE do
        for column = 1, BOARD_SIZE do
            local button = self.cells[row][column]
            local cell = board[row][column]
            local hasSpecial = cell.special ~= nil
            local isColorSpecial = cell.special == "color"
            local isExplosive = cell.special == "explosive"
            local borderRed = isColorSpecial and 0.55 or 1
            local borderGreen = isColorSpecial and 0.82 or 0.48
            local borderBlue = isColorSpecial and 1 or 0.08

            setGemTexture(button.gem, cell.gemType)
            setCellVisualOffset(button, 0, 0)
            button.gem:SetSize(CELL_SIZE - 2, CELL_SIZE - 2)
            button.gem:SetAlpha(1)
            button.gem:SetShown(not isColorSpecial)

            button.specialMarker:SetVertexColor(0.75, 0.9, 1, 1)
            button.specialMarker:SetShown(isColorSpecial)
            button.bombMarker:SetShown(isExplosive)
            for _, border in ipairs(button.specialBorders) do
                border:SetColorTexture(
                    borderRed,
                    borderGreen,
                    borderBlue,
                    0.95
                )
                border:SetShown(hasSpecial)
            end

            button.selection:SetShown(
                self.selectedRow == row and self.selectedColumn == column
            )
        end
    end
end

function UI:RefreshStatus(score)
    local level, progress, required = addon.Scoring.GetLevel(
        score or addon.controller.score
    )

    self.levelText:SetText("LVL " .. level)
    self.scoreText:SetText(tostring(score or addon.controller.score))
    self.progress:SetMinMaxValues(0, required)
    self.progress:SetValue(progress)
end

function UI:RefreshLeaderboard()
    if not self.leaderboardRows then
        return
    end

    local publicLeaderboard = addon.publicLeaderboard
    local mode = self.leaderboardMode or "party"
    local store = mode == "public"
        and addon.publicLeaderboardStore
        or addon.partyLeaderboardStore
    local peerScores = store and store.entries or {}
    local localAccountId = addon.scoreSession
        and addon.scoreSession.accountId
        or nil
    local localBest = localAccountId and peerScores[localAccountId] or nil
    local localScore = addon.controller.score
    local localLevel = addon.controller:GetLevel()
    if localBest and localBest.score > localScore then
        localScore = localBest.score
        localLevel = localBest.level
    end
    local entries = addon.Leaderboard.Build(
        "You",
        localScore,
        localLevel,
        peerScores,
        LEADERBOARD_MAX_ENTRIES,
        localAccountId
    )

    for index, row in ipairs(self.leaderboardRows) do
        local entry = entries[index]
        row:SetShown(entry ~= nil)

        if entry then
            local displayName = Ambiguate
                and Ambiguate(entry.name, "none")
                or entry.name
            local red = entry.isLocal and 1 or 0.9
            local green = entry.isLocal and 0.82 or 0.9
            local blue = entry.isLocal and 0.15 or 0.9

            row.rank:SetText(entry.rank .. ".")
            row.name:SetText(displayName)
            row.level:SetText("L" .. entry.level)
            row.score:SetText(entry.score)
            row.rank:SetTextColor(red, green, blue)
            row.name:SetTextColor(red, green, blue)
            row.level:SetTextColor(red, green, blue)
            row.score:SetTextColor(red, green, blue)
        end
    end

    if self.publicLeaderboardButton and publicLeaderboard then
        self.publicLeaderboardButton:SetText(
            publicLeaderboard:GetButtonLabel()
        )

        if publicLeaderboard.state == "JOINING" then
            self.publicLeaderboardButton:Disable()
        else
            self.publicLeaderboardButton:Enable()
        end
    end


    if self.partyLeaderboardTab and self.publicLeaderboardTab then
        self.partyLeaderboardTab:SetEnabled(mode ~= "party")
        self.publicLeaderboardTab:SetEnabled(
            publicLeaderboard.enabled and mode ~= "public"
        )
    end

    if self.leaderboardTitle then
        self.leaderboardTitle:SetText(
            mode == "public" and "PUBLIC TOP 10" or "PARTY TOP 10"
        )
    end
end

function UI:SetLeaderboardMode(mode)
    if mode ~= "party" and mode ~= "public" then
        return
    end

    local publicLeaderboard = addon.publicLeaderboard
    if mode == "public" and not publicLeaderboard then
        return
    end

    if mode == "public" and not publicLeaderboard.enabled then
        return
    end

    self.leaderboardMode = mode
    BetterBejeweledDB.leaderboardMode = mode
    self:RefreshLeaderboard()
end

function UI:TogglePublicLeaderboard()
    local publicLeaderboard = addon.publicLeaderboard
    if not publicLeaderboard then
        return
    end

    if publicLeaderboard.state == "CONNECTED" then
        publicLeaderboard:Leave()
        BetterBejeweledDB.publicLeaderboardEnabled = false
        self.leaderboardMode = "party"
        BetterBejeweledDB.leaderboardMode = "party"

        if addon.communication then
            addon.communication:ClearPublicScores()
        end
    else
        BetterBejeweledDB.publicLeaderboardEnabled = true
        self.leaderboardMode = "public"
        BetterBejeweledDB.leaderboardMode = "public"
        addon.JoinPublicLeaderboard()
    end

    self:RefreshLeaderboard()
end

function UI:SetLeaderboardShown(shown)
    self.leaderboard:SetShown(shown)
    self.leaderboardToggle:SetText(shown and "<" or ">")
    BetterBejeweledDB.leaderboardShown = shown

    if shown then
        self:RefreshLeaderboard()
    end
end

function UI:Refresh()
    self:RenderBoard(addon.controller.board)
    self:RefreshStatus()
    self:RefreshLeaderboard()
end

function UI:Save()
    if addon.controller.phase ~= "READY" then
        return
    end

    BetterBejeweledDB.board = addon.controller.board
    BetterBejeweledDB.score = addon.controller.score
    BetterBejeweledDB.soundEnabled = addon.controller.soundEnabled
end

function UI:ShowNotice(message)
    self.noticeSequence = (self.noticeSequence or 0) + 1
    local sequence = self.noticeSequence

    self.noticeText:SetText(message)
    self.noticeFrame:Show()

    C_Timer.After(2.5, function()
        if UI.noticeSequence == sequence then
            UI.noticeFrame:Hide()
        end
    end)
end

function UI:AttemptSwap(firstRow, firstColumn, secondRow, secondColumn)
    self:ResetHint()

    if self.animator:IsRunning() then
        return
    end

    local previousLevel = addon.controller:GetLevel()
    local plan = addon.controller:BeginSwap(
        firstRow,
        firstColumn,
        secondRow,
        secondColumn
    )

    if not plan then
        return
    end

    self.selectedRow = nil
    self.selectedColumn = nil
    self.previousLevel = previousLevel
    self.animator:Start(plan)
end

setCellVisualOffset = function(button, x, y)
    button.gem:ClearAllPoints()
    button.gem:SetPoint("CENTER", x, y)
    button.specialMarker:ClearAllPoints()
    button.specialMarker:SetPoint("CENTER", x, y)
    button.bombMarker:ClearAllPoints()
    button.bombMarker:SetPoint("TOPRIGHT", 1 + x, 1 + y)

    button.specialBorders.top:ClearAllPoints()
    button.specialBorders.top:SetPoint("TOPLEFT", 1 + x, -1 + y)
    button.specialBorders.top:SetPoint("TOPRIGHT", -1 + x, -1 + y)
    button.specialBorders.bottom:ClearAllPoints()
    button.specialBorders.bottom:SetPoint("BOTTOMLEFT", 1 + x, 1 + y)
    button.specialBorders.bottom:SetPoint("BOTTOMRIGHT", -1 + x, 1 + y)
    button.specialBorders.left:ClearAllPoints()
    button.specialBorders.left:SetPoint("TOPLEFT", 1 + x, -1 + y)
    button.specialBorders.left:SetPoint("BOTTOMLEFT", 1 + x, 1 + y)
    button.specialBorders.right:ClearAllPoints()
    button.specialBorders.right:SetPoint("TOPRIGHT", -1 + x, -1 + y)
    button.specialBorders.right:SetPoint("BOTTOMRIGHT", -1 + x, 1 + y)
end

function UI:ResetHint()
    if self.hintMove then
        local button = self.cells[self.hintMove.fromRow]
            [self.hintMove.fromColumn]
        setCellVisualOffset(button, 0, 0)
        self.hintMove = nil
    end

    if self.hint then
        self.hint:Reset()
    end
end

function UI:UpdateHint(elapsed)
    local active = self.frame:IsShown()
        and not self.menu:IsShown()
        and not self.animator:IsRunning()
        and addon.controller.phase == "READY"
    local move, offset, finished = self.hint:Update(
        elapsed,
        active,
        function()
            local fromRow, fromColumn, toRow, toColumn =
                addon.Board.FindValidMove(addon.controller.board)
            if not fromRow then
                return nil
            end

            return {
                fromRow = fromRow,
                fromColumn = fromColumn,
                toRow = toRow,
                toColumn = toColumn,
            }
        end
    )
    if not move then
        return
    end

    self.hintMove = move
    local x = (move.toColumn - move.fromColumn) * offset
    local y = (move.fromRow - move.toRow) * offset
    setCellVisualOffset(self.cells[move.fromRow][move.fromColumn], x, y)

    if finished then
        self.hintMove = nil
    end
end

function UI:StartAnimationStep(step)
    self.animationOffsets = {}

    if step.kind == "reshuffle" then
        addon.Announcement.NotifyNoMoves(
            function(message)
                UI:ShowNotice(message)
            end,
            function(message)
                DEFAULT_CHAT_FRAME:AddMessage(message, 1, 0.82, 0.15)
            end
        )
    end

    if step.kind == "settle" then
        self:RenderBoard(step.board)

        for _, fall in ipairs(step.falls) do
            local key = fall.toRow .. ":" .. fall.column
            self.animationOffsets[key] = {
                y = (fall.toRow - fall.fromRow) * CELL_SIZE,
                isNew = false,
            }
        end

        for _, refill in ipairs(step.refills) do
            local key = refill.row .. ":" .. refill.column
            self.animationOffsets[key] = {
                y = (refill.row - refill.startRow) * CELL_SIZE,
                isNew = true,
            }
        end

        for key, offset in pairs(self.animationOffsets) do
            local row, column = string.match(key, "^(%d+):(%d+)$")
            local button = self.cells[tonumber(row)][tonumber(column)]
            setCellVisualOffset(button, 0, offset.y)
            button.gem:SetAlpha(offset.isNew and 0 or 1)
        end
    end
end

function UI:UpdateAnimationStep(step, progress)
    local easedProgress = easeOutCubic(progress)

    if step.kind == "swap" then
        local movementProgress = progress
        if not step.valid then
            movementProgress = progress <= 0.5
                and progress * 2
                or (1 - progress) * 2
            movementProgress = easeOutCubic(movementProgress)
        end

        local x = (step.toColumn - step.fromColumn)
            * CELL_SIZE * movementProgress
        local y = (step.fromRow - step.toRow)
            * CELL_SIZE * movementProgress
        setCellVisualOffset(self.cells[step.fromRow][step.fromColumn], x, y)
        setCellVisualOffset(self.cells[step.toRow][step.toColumn], -x, -y)
        return
    end

    if step.kind == "clear" then
        for position in pairs(step.positions) do
            local row, column = string.match(position, "^(%d+):(%d+)$")
            local gem = self.cells[tonumber(row)][tonumber(column)].gem
            local size = (CELL_SIZE - 2) * (1 - progress * 0.65)

            gem:SetSize(size, size)
            gem:SetAlpha(1 - progress)
        end

        self:RefreshStatus(step.score)
        return
    end

    if step.kind == "settle" then
        for position, offset in pairs(self.animationOffsets) do
            local row, column = string.match(position, "^(%d+):(%d+)$")
            local button = self.cells[tonumber(row)][tonumber(column)]
            local y = offset.y * (1 - easedProgress)

            setCellVisualOffset(button, 0, y)
            if offset.isNew then
                button.gem:SetAlpha(easedProgress)
            end
        end
        return
    end

    if step.kind == "reshuffle" then
        local alpha = progress < 0.5
            and 1 - progress * 2
            or (progress - 0.5) * 2

        for row = 1, BOARD_SIZE do
            for column = 1, BOARD_SIZE do
                self.cells[row][column].gem:SetAlpha(alpha)
            end
        end

        if progress >= 0.5 and not step.rendered then
            step.rendered = true
            self:RenderBoard(step.board)
        end
    end
end

function UI:FinishAnimationStep(step)
    if step.kind == "swap" and step.valid then
        self:RenderBoard(step.board)
    elseif step.kind == "swap" then
        setCellVisualOffset(
            self.cells[step.fromRow][step.fromColumn],
            0,
            0
        )
        setCellVisualOffset(
            self.cells[step.toRow][step.toColumn],
            0,
            0
        )
    elseif step.kind == "settle" or step.kind == "reshuffle" then
        self:RenderBoard(step.board)
    end

    if step.kind == "settle" and addon.controller.soundEnabled then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end

function UI:FinishAnimationPlan(plan)
    addon.controller:FinishSwap(plan)
    self:Refresh()

    local currentLevel = addon.controller:GetLevel()
    if currentLevel > self.previousLevel then
        addon.Announcement.SendReachedLevels(
            self.previousLevel,
            currentLevel,
            SendChatMessage
        )
    end

    if addon.controller.soundEnabled then
        local sound = not plan.accepted
            and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
            or currentLevel > self.previousLevel
                and SOUNDKIT.LEVEL_UP
            or SOUNDKIT.UI_JEWELCRAFTING_FINALIZE
            or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON

        PlaySound(sound)
    end

    self:Save()
    self:ResetHint()
end

function UI:SelectCell(row, column)
    self:ResetHint()

    local action = addon.Input.GetSelectionAction(
        self.selectedRow,
        self.selectedColumn,
        row,
        column
    )

    if action == "select" then
        self.selectedRow = row
        self.selectedColumn = column
        self:Refresh()
        return
    end

    if action == "deselect" then
        self.selectedRow = nil
        self.selectedColumn = nil
        self:Refresh()
        return
    end

    self:AttemptSwap(self.selectedRow, self.selectedColumn, row, column)
end

function UI:HandleDrag(button, row, column)
    self:ResetHint()

    local scale = button:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    local deltaX = (cursorX - button.dragX) / scale
    local deltaY = (cursorY - button.dragY) / scale

    local targetRow, targetColumn = addon.Input.GetDragTarget(
        row,
        column,
        deltaX,
        deltaY,
        BOARD_SIZE
    )

    if targetRow then
        self:AttemptSwap(row, column, targetRow, targetColumn)
    end
end

local function createCell(parent, row, column)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(CELL_SIZE, CELL_SIZE)
    button:SetPoint(
        "TOPLEFT",
        BOARD_INSET + (column - 1) * CELL_SIZE,
        -BOARD_INSET - (row - 1) * CELL_SIZE
    )
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local tile = button:CreateTexture(nil, "BACKGROUND")
    tile:SetAllPoints()
    tile:SetColorTexture(0.015, 0.015, 0.02, 1)

    button.gem = button:CreateTexture(nil, "ARTWORK")
    button.gem:SetPoint("CENTER")
    button.gem:SetSize(CELL_SIZE - 2, CELL_SIZE - 2)

    button.selection = button:CreateTexture(nil, "OVERLAY")
    button.selection:SetAllPoints()
    button.selection:SetColorTexture(1, 0.82, 0.15, 0.22)
    button.selection:Hide()

    button.specialMarker = button:CreateTexture(nil, "OVERLAY")
    button.specialMarker:SetPoint("CENTER")
    button.specialMarker:SetSize(CELL_SIZE - 2, CELL_SIZE - 2)
    button.specialMarker:SetTexture("Interface\\Cooldown\\star4")
    button.specialMarker:SetBlendMode("ADD")
    button.specialMarker:Hide()

    button.bombMarker = button:CreateTexture(nil, "OVERLAY")
    button.bombMarker:SetPoint("TOPRIGHT", 1, 1)
    button.bombMarker:SetSize(24, 24)
    button.bombMarker:SetTexture(BOMB_TEXTURE)
    button.bombMarker:Hide()

    button.specialBorders = {}

    local topBorder = button:CreateTexture(nil, "OVERLAY")
    topBorder:SetPoint("TOPLEFT", 1, -1)
    topBorder:SetPoint("TOPRIGHT", -1, -1)
    topBorder:SetHeight(2)
    button.specialBorders.top = topBorder
    button.specialBorders[#button.specialBorders + 1] = topBorder

    local bottomBorder = button:CreateTexture(nil, "OVERLAY")
    bottomBorder:SetPoint("BOTTOMLEFT", 1, 1)
    bottomBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    bottomBorder:SetHeight(2)
    button.specialBorders.bottom = bottomBorder
    button.specialBorders[#button.specialBorders + 1] = bottomBorder

    local leftBorder = button:CreateTexture(nil, "OVERLAY")
    leftBorder:SetPoint("TOPLEFT", 1, -1)
    leftBorder:SetPoint("BOTTOMLEFT", 1, 1)
    leftBorder:SetWidth(2)
    button.specialBorders.left = leftBorder
    button.specialBorders[#button.specialBorders + 1] = leftBorder

    local rightBorder = button:CreateTexture(nil, "OVERLAY")
    rightBorder:SetPoint("TOPRIGHT", -1, -1)
    rightBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    rightBorder:SetWidth(2)
    button.specialBorders.right = rightBorder
    button.specialBorders[#button.specialBorders + 1] = rightBorder

    button:SetScript("OnMouseDown", function(self)
        self.dragX, self.dragY = GetCursorPosition()
        self.wasDragged = false
    end)
    button:SetScript("OnDragStart", function(self)
        self.wasDragged = true
        UI:HandleDrag(self, row, column)
    end)
    button:SetScript("OnClick", function(self)
        if not self.wasDragged then
            UI:SelectCell(row, column)
        end
    end)

    return button
end

local function createMenuButton(parent, label, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(220, 26)
    button:SetPoint("TOP", 0, y)
    button:SetText(label)
    button:SetScript("OnClick", callback)

    return button
end

function UI:CreateLeaderboard(frame)
    local leaderboard = CreateFrame(
        "Frame",
        "BetterBejeweledLeaderboard",
        frame,
        "BackdropTemplate"
    )
    leaderboard:SetSize(194, 354)
    leaderboard:SetPoint("TOPRIGHT", frame, "TOPLEFT", -6, -52)
    leaderboard:SetFrameLevel(frame:GetFrameLevel() + 10)
    leaderboard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    leaderboard:SetBackdropColor(0.025, 0.025, 0.04, 0.98)

    local title = leaderboard:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )
    title:SetPoint("TOP", 0, -16)
    title:SetText("LEADERBOARD")
    self.leaderboardTitle = title

    local headingRow = CreateFrame("Frame", nil, leaderboard)
    headingRow:SetSize(194, 20)
    headingRow:SetPoint("TOP", 0, -34)

    local rankHeading = headingRow:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    rankHeading:SetSize(20, 20)
    rankHeading:SetPoint("LEFT", 14, 0)
    rankHeading:SetJustifyH("RIGHT")
    rankHeading:SetText("#")

    local nameHeading = headingRow:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    nameHeading:SetSize(66, 20)
    nameHeading:SetPoint("LEFT", rankHeading, "RIGHT", 5, 0)
    nameHeading:SetJustifyH("LEFT")
    nameHeading:SetText("PLAYER")

    local levelHeading = headingRow:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    levelHeading:SetSize(28, 20)
    levelHeading:SetPoint("LEFT", nameHeading, "RIGHT", 2, 0)
    levelHeading:SetJustifyH("RIGHT")
    levelHeading:SetText("LVL")

    local scoreHeading = headingRow:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    scoreHeading:SetSize(45, 20)
    scoreHeading:SetPoint("RIGHT", -14, 0)
    scoreHeading:SetJustifyH("RIGHT")
    scoreHeading:SetText("SCORE")

    for _, heading in ipairs({
        rankHeading,
        nameHeading,
        levelHeading,
        scoreHeading,
    }) do
        heading:SetTextColor(0.62, 0.62, 0.7)
    end

    self.leaderboardRows = {}
    for index = 1, LEADERBOARD_MAX_ENTRIES do
        local row = CreateFrame("Frame", nil, leaderboard)
        row:SetSize(166, 22)
        row:SetPoint("TOPLEFT", 14, -54 - (index - 1) * 24)

        row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.rank:SetSize(20, 20)
        row.rank:SetPoint("LEFT")
        row.rank:SetJustifyH("RIGHT")

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetSize(66, 20)
        row.name:SetPoint("LEFT", row.rank, "RIGHT", 5, 0)
        row.name:SetJustifyH("LEFT")

        row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.level:SetSize(28, 20)
        row.level:SetPoint("LEFT", row.name, "RIGHT", 2, 0)
        row.level:SetJustifyH("RIGHT")

        row.score = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.score:SetSize(45, 20)
        row.score:SetPoint("RIGHT")
        row.score:SetJustifyH("RIGHT")

        self.leaderboardRows[index] = row
    end

    local publicButton = CreateFrame(
        "Button",
        "BetterBejeweledPublicLeaderboardButton",
        leaderboard,
        "UIPanelButtonTemplate"
    )
    publicButton:SetSize(166, 22)
    publicButton:SetPoint("BOTTOM", 0, 10)
    publicButton:SetScript("OnClick", function()
        UI:TogglePublicLeaderboard()
    end)

    local partyTab = CreateFrame(
        "Button",
        "BetterBejeweledPartyLeaderboardTab",
        leaderboard,
        "UIPanelButtonTemplate"
    )
    partyTab:SetSize(80, 20)
    partyTab:SetPoint("BOTTOMLEFT", 14, 34)
    partyTab:SetText("PARTY")
    partyTab:SetScript("OnClick", function()
        UI:SetLeaderboardMode("party")
    end)

    local publicTab = CreateFrame(
        "Button",
        "BetterBejeweledPublicLeaderboardTab",
        leaderboard,
        "UIPanelButtonTemplate"
    )
    publicTab:SetSize(80, 20)
    publicTab:SetPoint("BOTTOMRIGHT", -14, 34)
    publicTab:SetText("PUBLIC")
    publicTab:SetScript("OnClick", function()
        UI:SetLeaderboardMode("public")
    end)

    local toggle = CreateFrame(
        "Button",
        "BetterBejeweledLeaderboardToggle",
        frame,
        "UIPanelButtonTemplate"
    )
    toggle:SetSize(22, 46)
    toggle:SetPoint("RIGHT", frame, "LEFT", 1, 0)
    toggle:SetFrameLevel(frame:GetFrameLevel() + 11)
    toggle:SetScript("OnClick", function()
        UI:SetLeaderboardShown(not leaderboard:IsShown())
    end)

    self.leaderboard = leaderboard
    self.leaderboardToggle = toggle
    self.publicLeaderboardButton = publicButton
    self.partyLeaderboardTab = partyTab
    self.publicLeaderboardTab = publicTab
    self.leaderboardMode = BetterBejeweledDB.leaderboardMode or "party"
    self:SetLeaderboardShown(BetterBejeweledDB.leaderboardShown)
end

function UI:CreateMenu()
    local menu = CreateFrame("Frame", nil, self.frame)
    menu:SetAllPoints(self.frame)
    menu:SetFrameLevel(self.frame:GetFrameLevel() + 30)
    menu:EnableMouse(true)

    local shade = menu:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, 0.72)

    local menuPanel = CreateFrame(
        "Frame",
        nil,
        menu,
        "BackdropTemplate"
    )
    menuPanel:SetAllPoints(menu)
    menuPanel:SetFrameLevel(menu:GetFrameLevel() + 1)
    menuPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    menuPanel:SetBackdropColor(0.025, 0.025, 0.04, 0.99)

    local title = menuPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalHuge"
    )
    title:SetPoint("TOP", 0, -22)
    title:SetText("Menu")

    local description = menuPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )
    description:SetPoint("TOP", title, "BOTTOM", 0, -5)
    description:SetText("Game and interface options")

    local closeButton = CreateFrame(
        "Button",
        nil,
        menuPanel,
        "UIPanelCloseButton"
    )
    closeButton:SetPoint("TOPRIGHT", -6, -6)
    closeButton:SetScript("OnClick", function()
        menu:Hide()
    end)

    local gameLabel = menuPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    gameLabel:SetPoint("TOPLEFT", 40, -78)
    gameLabel:SetText("GAME")

    createMenuButton(menuPanel, "New Game", -96, function()
        local popup = StaticPopup_Show("BETTERBEJEWELED_NEW_GAME")
        if popup then
            popup:SetFrameStrata("FULLSCREEN_DIALOG")
            popup:SetFrameLevel(self.frame:GetFrameLevel() + 100)
        end
    end)

    local automationLabel = menuPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    automationLabel:SetPoint("TOPLEFT", 40, -134)
    automationLabel:SetText("AUTOMATION")

    self.autoToggleButton = createMenuButton(
        menuPanel,
        "Auto Open During Flight: On",
        -152,
        function()
            BetterBejeweledDB.autoToggleEnabled =
                not BetterBejeweledDB.autoToggleEnabled
            self.autoToggleButton:SetText(
                BetterBejeweledDB.autoToggleEnabled
                    and "Auto Open During Flight: On"
                    or "Auto Open During Flight: Off"
            )
            addon.HandleAutoToggle("SETTING_CHANGED")
        end
    )

    self.closeInCombatButton = createMenuButton(
        menuPanel,
        "Close in Combat: On",
        -184,
        function()
            BetterBejeweledDB.closeInCombatEnabled =
                not BetterBejeweledDB.closeInCombatEnabled
            self.closeInCombatButton:SetText(
                BetterBejeweledDB.closeInCombatEnabled
                    and "Close in Combat: On"
                    or "Close in Combat: Off"
            )
        end
    )

    local audioLabel = menuPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    audioLabel:SetPoint("TOPLEFT", 40, -222)
    audioLabel:SetText("AUDIO")

    self.soundButton = createMenuButton(menuPanel, "Sound: On", -240, function()
        addon.controller.soundEnabled = not addon.controller.soundEnabled
        self.soundButton:SetText(
            addon.controller.soundEnabled and "Sound: On" or "Sound: Off"
        )
        self:Save()
    end)

    local interfaceLabel = menuPanel:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
    )
    interfaceLabel:SetPoint("TOPLEFT", 40, -278)
    interfaceLabel:SetText("INTERFACE")

    self.scaleButton = createMenuButton(
        menuPanel,
        "Scale: 100%",
        -296,
        function()
            local scale = self.frame:GetScale() + 0.1
            if scale > 1.21 then
                scale = 0.8
            end

            self.frame:SetScale(scale)
            self.scaleButton:SetText(
                string.format(
                    "Scale: %d%%",
                    math.floor(scale * 100 + 0.5)
                )
            )
            BetterBejeweledDB.window.scale = scale
        end
    )

    createMenuButton(menuPanel, "Reset Position", -328, function()
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER")
        BetterBejeweledDB.window = {
            point = "CENTER",
            x = 0,
            y = 0,
            scale = self.frame:GetScale(),
        }
    end)

    createMenuButton(menuPanel, "Close Game", -374, function()
        self.frame:Hide()
    end)

    self.menu = menu
    self.menuPanel = menuPanel
    menu:Hide()
end

function UI:Create()
    local frame = CreateFrame(
        "Frame",
        "BetterBejeweledFrame",
        UIParent,
        "BackdropTemplate"
    )
    frame:SetSize(372, 472)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        BetterBejeweledDB.window = {
            point = point,
            x = x,
            y = y,
            scale = self:GetScale(),
        }
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    frame:SetBackdropColor(0.035, 0.035, 0.045, 0.98)
    frame:Hide()
    frame:SetScript("OnShow", function()
        UI:ResetHint()
    end)
    frame:SetScript("OnHide", function()
        UI:ResetHint()
    end)

    table.insert(UISpecialFrames, frame:GetName())

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 24, -18)
    title:SetText("|cffed55ffBETTER|r|cff9f70ffBEJEWELED|r")

    local closeButton = CreateFrame(
        "Button",
        "BetterBejeweledCloseButton",
        frame,
        "UIPanelCloseButton"
    )
    closeButton:SetSize(30, 30)
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        if self.menu:IsShown() then
            self.menu:Hide()
            return
        end

        frame:Hide()
    end)

    local menuButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    menuButton:SetSize(58, 24)
    menuButton:SetPoint("TOPRIGHT", -48, -16)
    menuButton:SetText("Menu")
    menuButton:SetScript("OnClick", function()
        self.menu:SetShown(not self.menu:IsShown())
    end)

    self:CreateLeaderboard(frame)

    local boardFrame = CreateFrame("Frame", nil, frame)
    boardFrame:SetSize(BOARD_SIZE * CELL_SIZE + BOARD_INSET * 2,
        BOARD_SIZE * CELL_SIZE + BOARD_INSET * 2)
    boardFrame:SetPoint("TOP", 0, -52)
    addBorder(boardFrame, 3, 0.32, 0.3, 0.35)

    self.cells = {}
    for row = 1, BOARD_SIZE do
        self.cells[row] = {}
        for column = 1, BOARD_SIZE do
            self.cells[row][column] = createCell(boardFrame, row, column)
        end
    end

    local noticeFrame = CreateFrame("Frame", nil, frame)
    noticeFrame:SetSize(310, 58)
    noticeFrame:SetPoint("CENTER", boardFrame, "CENTER")
    noticeFrame:SetFrameLevel(frame:GetFrameLevel() + 25)
    noticeFrame:EnableMouse(false)

    local noticeBackground = noticeFrame:CreateTexture(nil, "BACKGROUND")
    noticeBackground:SetAllPoints()
    noticeBackground:SetColorTexture(0.02, 0.02, 0.03, 0.92)

    local noticeText = noticeFrame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )
    noticeText:SetPoint("CENTER")
    noticeText:SetTextColor(1, 0.82, 0.15)

    self.noticeFrame = noticeFrame
    self.noticeText = noticeText
    noticeFrame:Hide()

    self.levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.levelText:SetPoint("BOTTOMLEFT", 20, 18)

    self.scoreText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.scoreText:SetPoint("LEFT", self.levelText, "RIGHT", 18, 0)

    self.progress = CreateFrame("StatusBar", nil, frame)
    self.progress:SetSize(190, 14)
    self.progress:SetPoint("BOTTOMRIGHT", -20, 20)
    self.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.progress:SetStatusBarColor(0.08, 0.48, 0.95)

    self.frame = frame
    self:CreateMenu()
    self.autoToggleButton:SetText(
        BetterBejeweledDB.autoToggleEnabled
            and "Auto Open During Flight: On"
            or "Auto Open During Flight: Off"
    )
    self.closeInCombatButton:SetText(
        BetterBejeweledDB.closeInCombatEnabled
            and "Close in Combat: On"
            or "Close in Combat: Off"
    )
    self.soundButton:SetText(
        addon.controller.soundEnabled and "Sound: On" or "Sound: Off"
    )
    self.scaleButton:SetText(
        string.format(
            "Scale: %d%%",
            math.floor(BetterBejeweledDB.window.scale * 100 + 0.5)
        )
    )
    self.animator = addon.AnimationDirector.New({
        startStep = function(step)
            UI:StartAnimationStep(step)
        end,
        updateStep = function(step, progress)
            UI:UpdateAnimationStep(step, progress)
        end,
        finishStep = function(step)
            UI:FinishAnimationStep(step)
        end,
        finishPlan = function(plan)
            UI:FinishAnimationPlan(plan)
        end,
    })
    self.hint = addon.Hint.New(HINT_DELAY, HINT_DURATION, HINT_DISTANCE)

    local animationDriver = CreateFrame("Frame", nil, UIParent)
    animationDriver:SetScript("OnUpdate", function(_, elapsed)
        if UI.animator:IsRunning() then
            UI.animator:Update(elapsed)
        end

        UI:UpdateHint(elapsed)
    end)
    self.animationDriver = animationDriver
    self:Refresh()

    StaticPopupDialogs.BETTERBEJEWELED_NEW_GAME = {
        text = "Start a new BetterBejeweled game?",
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            addon.controller = addon.Controller.New()
            if addon.StartNewScoreSession then
                addon.StartNewScoreSession()
            end

            UI:Save()
            UI:Refresh()

            if addon.BroadcastScore then
                addon.BroadcastScore(true)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

function UI:Toggle()
    self.frame:SetShown(not self.frame:IsShown())
    self.menu:Hide()

    if self.frame:IsShown() then
        self:Refresh()
    end
end

addon.UI = UI
