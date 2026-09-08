local AutoToggle = {}
AutoToggle.__index = AutoToggle
local _, addon = ...

function AutoToggle.New()
    return setmetatable({
        openedForFlight = false,
    }, AutoToggle)
end

function AutoToggle:Handle(event, enabled, isOnTaxi, windowShown)
    if not enabled then
        self.openedForFlight = false
        return nil
    end

    if (event == "PLAYER_CONTROL_LOST"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "TAXI_STATE_CHECK"
        or event == "UNIT_FLAGS")
        and isOnTaxi then
        if not windowShown then
            self.openedForFlight = true
            return "show"
        end

        return nil
    end

    if (event == "PLAYER_CONTROL_GAINED" or event == "UNIT_FLAGS")
        and not isOnTaxi then
        if self.openedForFlight then
            self.openedForFlight = false
            return "hide"
        end

        return nil
    end

    return nil
end

function AutoToggle:HandleCombat(enabled, windowShown)
    if not enabled or not windowShown then
        return nil
    end

    self.openedForFlight = false

    return "hide"
end

if type(addon) == "table" then
    addon.AutoToggle = AutoToggle
end

return AutoToggle
