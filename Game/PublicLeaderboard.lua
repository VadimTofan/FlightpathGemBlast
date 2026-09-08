local PublicLeaderboard = {}
PublicLeaderboard.__index = PublicLeaderboard

local _, addon = ...

local CHANNEL_NAME = "BetterBejeweled"

function PublicLeaderboard.New(api)
    return setmetatable({
        api = api,
        enabled = false,
        state = "DISCONNECTED",
        channelId = nil,
    }, PublicLeaderboard)
end

function PublicLeaderboard:Join()
    self.enabled = true
    self.state = "JOINING"
    local succeeded = pcall(self.api.joinChannel, CHANNEL_NAME)
    if not succeeded then
        self.state = "ERROR"

        return false
    end

    return true
end

function PublicLeaderboard:RefreshConnection(finalCheck)
    if not self.enabled then
        return false
    end

    local channelId = self.api.getChannelId(CHANNEL_NAME)
    if not channelId or channelId <= 0 then
        self.channelId = nil
        self.state = finalCheck and "ERROR" or "JOINING"

        return false
    end

    local newlyConnected = self.state ~= "CONNECTED"
    self.channelId = channelId
    self.state = "CONNECTED"
    pcall(self.api.hideChannel, CHANNEL_NAME)

    return newlyConnected
end

function PublicLeaderboard:Leave()
    pcall(self.api.leaveChannel, CHANNEL_NAME)
    self.enabled = false
    self.state = "DISCONNECTED"
    self.channelId = nil
end

function PublicLeaderboard:GetButtonLabel()
    if self.state == "CONNECTED" then
        return "Leave Public Leaderboard"
    end

    if self.state == "JOINING" then
        return "Joining..."
    end

    if self.state == "ERROR" then
        return "Retry Public Leaderboard"
    end

    return "Join Public Leaderboard"
end

function PublicLeaderboard:IsChannelTarget(target)
    if self.state ~= "CONNECTED" then
        return false
    end

    if type(target) == "number" then
        return target == self.channelId
    end

    if type(target) ~= "string" then
        return false
    end

    local targetName = string.match(target, "^%d+%.%s*(.+)$") or target

    return string.lower(targetName) == string.lower(CHANNEL_NAME)
end

if type(addon) == "table" then
    addon.PublicLeaderboard = PublicLeaderboard
end

return PublicLeaderboard
