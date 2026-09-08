local Hint = {}
Hint.__index = Hint

local _, addon = ...

function Hint.New(delay, duration, distance)
    return setmetatable({
        delay = delay,
        duration = duration,
        distance = distance,
        elapsed = 0,
        animationElapsed = nil,
        move = nil,
    }, Hint)
end

function Hint:Reset()
    self.elapsed = 0
    self.animationElapsed = nil
    self.move = nil
end

function Hint:Update(elapsed, active, findMove)
    if not active then
        return nil
    end

    if self.move then
        self.animationElapsed = (self.animationElapsed + elapsed)
            % self.duration
        local progress = self.animationElapsed / self.duration
        local offset = math.sin(progress * math.pi) * self.distance

        return self.move, offset, false
    end

    self.elapsed = self.elapsed + elapsed
    if self.elapsed < self.delay then
        return nil
    end

    self.elapsed = 0
    self.move = findMove()
    if not self.move then
        return nil
    end

    self.animationElapsed = 0

    return self.move, 0, false
end

if type(addon) == "table" then
    addon.Hint = Hint
end

return Hint
