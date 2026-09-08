local _, addon = ...
local Persistence = type(addon) == "table" and addon.Persistence
    or require("Persistence")
local MovePlanner = type(addon) == "table" and addon.MovePlanner
    or require("Game.MovePlanner")
local Board = type(addon) == "table" and addon.Board
    or require("Game.Board")

local Controller = {}
Controller.__index = Controller

function Controller.New(savedData, random)
    local data = Persistence.Normalize(savedData)

    return setmetatable({
        board = data.board,
        score = data.score,
        phase = "READY",
        random = random,
        soundEnabled = data.soundEnabled,
    }, Controller)
end

function Controller:Swap(firstRow, firstColumn, secondRow, secondColumn)
    local plan = self:BeginSwap(
        firstRow,
        firstColumn,
        secondRow,
        secondColumn
    )

    if not plan then
        return false
    end

    self:FinishSwap(plan)

    return plan.accepted
end

function Controller:BeginSwap(
    firstRow,
    firstColumn,
    secondRow,
    secondColumn
)
    if self.phase ~= "READY" then
        return nil
    end

    if not Board.AreAdjacent(
        firstRow,
        firstColumn,
        secondRow,
        secondColumn
    ) then
        return nil
    end

    local plan = MovePlanner.Plan(
        self.board,
        self.score,
        firstRow,
        firstColumn,
        secondRow,
        secondColumn,
        self.random
    )
    self.phase = "ANIMATING"

    return plan
end

function Controller:FinishSwap(plan)
    if self.phase ~= "ANIMATING" or not plan then
        return false
    end

    if plan.accepted then
        self.board = plan.finalBoard
        self.score = plan.finalScore
    end

    self.phase = "READY"

    return plan.accepted
end

function Controller:GetLevel()
    local Scoring = type(addon) == "table" and addon.Scoring
        or require("Game.Scoring")

    return Scoring.GetLevel(self.score)
end

if type(addon) == "table" then
    addon.Controller = Controller
end

return Controller
