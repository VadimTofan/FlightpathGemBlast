local _, addon = ...

local AnimationDirector = {}
AnimationDirector.__index = AnimationDirector

local function stepDuration(step)
    if step.kind == "swap" then
        return step.valid and 0.16 or 0.28
    end

    if step.kind == "clear" then
        return 0.18
    end

    if step.kind == "reshuffle" then
        return 0.25
    end

    if step.kind == "settle" then
        local maximumDistance = 1

        for _, fall in ipairs(step.falls) do
            maximumDistance = math.max(
                maximumDistance,
                fall.toRow - fall.fromRow
            )
        end

        for _, refill in ipairs(step.refills) do
            maximumDistance = math.max(
                maximumDistance,
                refill.row - refill.startRow
            )
        end

        return math.min(0.35, 0.1 + maximumDistance * 0.035)
    end

    return 0.08
end

local function noop()
end

function AnimationDirector.New(callbacks)
    callbacks = callbacks or {}

    return setmetatable({
        callbacks = {
            startStep = callbacks.startStep or noop,
            updateStep = callbacks.updateStep or noop,
            finishStep = callbacks.finishStep or noop,
            finishPlan = callbacks.finishPlan or noop,
        },
        plan = nil,
        stepIndex = 0,
        elapsed = 0,
        duration = 0,
    }, AnimationDirector)
end

function AnimationDirector:IsRunning()
    return self.plan ~= nil
end

function AnimationDirector:Start(plan)
    if self:IsRunning() or not plan or #plan.steps == 0 then
        return false
    end

    self.plan = plan
    self.stepIndex = 1
    self.elapsed = 0
    self.duration = stepDuration(plan.steps[1])
    self.callbacks.startStep(plan.steps[1], self.duration)

    return true
end

function AnimationDirector:Update(elapsed)
    while self.plan and elapsed > 0 do
        local remaining = self.duration - self.elapsed
        local consumed = math.min(elapsed, remaining)
        self.elapsed = self.elapsed + consumed
        elapsed = elapsed - consumed

        local step = self.plan.steps[self.stepIndex]
        local progress = math.min(1, self.elapsed / self.duration)
        self.callbacks.updateStep(step, progress)

        if self.elapsed >= self.duration then
            self.callbacks.finishStep(step)
            self.stepIndex = self.stepIndex + 1

            if self.stepIndex > #self.plan.steps then
                local finishedPlan = self.plan
                self.plan = nil
                self.callbacks.finishPlan(finishedPlan)
            else
                self.elapsed = 0
                step = self.plan.steps[self.stepIndex]
                self.duration = stepDuration(step)
                self.callbacks.startStep(step, self.duration)
            end
        end
    end
end

if type(addon) == "table" then
    addon.AnimationDirector = AnimationDirector
end

return AnimationDirector
