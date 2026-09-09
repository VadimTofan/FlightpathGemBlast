local _, addon = ...

local Communication = {}
Communication.__index = Communication

local PREFIX = "GEMBLAST"
local PUBLIC_BROADCAST_INTERVAL = 5
local PUBLIC_QUEUE_INTERVAL = 1
local MAX_PUBLIC_QUEUE = 50
local MAX_PUBLIC_SCORES = 100
local MAX_SEEN_PACKETS = 500
local ALLOWED_CHANNELS = {
    INSTANCE_CHAT = true,
    PARTY = true,
    RAID = true,
}

local function registrationSucceeded(result)
    if type(result) == "number" then
        return result <= 1
    end

    return result == true
end

local function sendSucceeded(result)
    if type(result) == "number" then
        return result == 0
    end

    return result == nil or result == true
end

local function trimOldestScore(scores, maximumEntries)
    local count = 0
    local oldestName
    local oldestUpdatedAt

    for name, score in pairs(scores) do
        count = count + 1
        if not oldestUpdatedAt or score.updatedAt < oldestUpdatedAt then
            oldestName = name
            oldestUpdatedAt = score.updatedAt
        end
    end

    if count > maximumEntries then
        scores[oldestName] = nil
    end
end

function Communication.New(api)
    return setmetatable({
        api = api,
        isRegistered = false,
        peerScores = {},
        publicScores = {},
        lastPublicBroadcast = nil,
        publicQueue = {},
        queuedPublicPackets = {},
        seenPackets = {},
        seenPacketOrder = {},
    }, Communication)
end

function Communication:BroadcastEncodedScore(encoded)
    if not self.isRegistered or type(encoded) ~= "string" then
        return false
    end

    local channel = self:GetGroupChannel()
    if not channel then
        return false
    end

    local succeeded, result = pcall(
        self.api.send,
        PREFIX,
        encoded,
        channel
    )

    return succeeded and sendSucceeded(result)
end


function Communication:QueuePublicPacket(encoded)
    if type(encoded) ~= "string"
        or #encoded > 255
        or self.queuedPublicPackets[encoded] then
        return false
    end

    if #self.publicQueue >= MAX_PUBLIC_QUEUE then
        local oldestEncoded = table.remove(self.publicQueue, 1)
        self.queuedPublicPackets[oldestEncoded] = nil
    end

    self.publicQueue[#self.publicQueue + 1] = encoded
    self.queuedPublicPackets[encoded] = true

    return true
end


function Communication:FlushPublicQueue(channelId)
    if not self.isRegistered
        or type(channelId) ~= "number"
        or channelId <= 0
        or #self.publicQueue == 0 then
        return false
    end

    local now = self.api.now()
    if self.lastPublicBroadcast
        and now - self.lastPublicBroadcast < PUBLIC_QUEUE_INTERVAL then
        return false
    end

    self.lastPublicBroadcast = now
    local encoded = self.publicQueue[1]
    local succeeded, result = pcall(
        self.api.send,
        PREFIX,
        encoded,
        "CHANNEL",
        channelId
    )
    if not succeeded or not sendSucceeded(result) then
        return false
    end

    table.remove(self.publicQueue, 1)
    self.queuedPublicPackets[encoded] = nil

    return true
end

function Communication:BroadcastPublicScore(score, level, channelId, force)
    if not self.isRegistered
        or type(channelId) ~= "number"
        or channelId <= 0 then
        return false
    end

    local now = self.api.now()
    if not force
        and self.lastPublicBroadcast
        and now - self.lastPublicBroadcast < PUBLIC_BROADCAST_INTERVAL then
        return false
    end

    local message = string.format("P:1:S:%d:%d", score, level)
    local succeeded, result = pcall(
        self.api.send,
        PREFIX,
        message,
        "CHANNEL",
        channelId
    )
    local sent = succeeded and sendSucceeded(result)
    if sent then
        self.lastPublicBroadcast = now
    end

    return sent
end

function Communication:BroadcastPublicRequest(channelId)
    if not self.isRegistered
        or type(channelId) ~= "number"
        or channelId <= 0 then
        return false
    end

    local succeeded, result = pcall(
        self.api.send,
        PREFIX,
        "P:1:Q",
        "CHANNEL",
        channelId
    )

    return succeeded and sendSucceeded(result)
end

function Communication:Register()
    local succeeded, registered = pcall(
        self.api.registerPrefix,
        PREFIX
    )

    self.isRegistered = succeeded and registrationSucceeded(registered)

    return self.isRegistered
end

function Communication:GetGroupChannel()
    if self.api.isInInstanceGroup() then
        return "INSTANCE_CHAT"
    end

    if self.api.isInRaid() then
        return "RAID"
    end

    if self.api.isInGroup() then
        return "PARTY"
    end

    return nil
end

function Communication:BroadcastScore(score, level)
    if not self.isRegistered then
        return false
    end

    local channel = self:GetGroupChannel()
    if not channel then
        return false
    end

    local message = string.format("S:1:%d:%d", score, level)
    local succeeded, result = pcall(
        self.api.send,
        PREFIX,
        message,
        channel
    )

    return succeeded and sendSucceeded(result)
end

function Communication:HandleMessage(prefix, message, channel, sender, target)
    local isGroupChannel = ALLOWED_CHANNELS[channel] == true
    local isPublicChannel = channel == "CHANNEL"
        and self.api.isPublicChannel
        and self.api.isPublicChannel(target)

    if prefix ~= PREFIX
        or (not isGroupChannel and not isPublicChannel)
        or type(message) ~= "string"
        or type(sender) ~= "string"
        or sender == "" then
        return false
    end

    local localPlayer = self.api.playerName
        and self.api.playerName()
        or nil
    if localPlayer and sender == localPlayer then
        return false
    end

    if string.sub(message, 1, 3) == "B1:" then
        local scoreData = self.api.decodeScore
            and self.api.decodeScore(message)
            or nil
        if not scoreData
            or (not isPublicChannel and scoreData.name ~= sender)
            or scoreData.accountId == self.api.accountId then
            return false
        end

        local packetId = scoreData.accountId
            .. ":" .. scoreData.sessionId
            .. ":" .. scoreData.sequence
        if self.seenPackets[packetId] then
            return false
        end

        self.seenPackets[packetId] = true
        self.seenPacketOrder[#self.seenPacketOrder + 1] = packetId
        if #self.seenPacketOrder > MAX_SEEN_PACKETS then
            local oldestPacketId = table.remove(self.seenPacketOrder, 1)
            self.seenPackets[oldestPacketId] = nil
        end

        return true,
            "score",
            scoreData,
            isPublicChannel and "public" or "group",
            message
    end

    if isPublicChannel and message == "P:1:Q" then
        return true, "request"
    end

    local pattern = isPublicChannel
        and "^P:1:S:(%d+):(%d+)$"
        or "^S:1:(%d+):(%d+)$"
    local scoreText, levelText = string.match(message, pattern)
    if not scoreText then
        return false
    end

    local scores = isPublicChannel and self.publicScores or self.peerScores
    scores[sender] = {
        score = tonumber(scoreText),
        level = tonumber(levelText),
        updatedAt = isPublicChannel and self.api.now() or nil,
    }
    if isPublicChannel then
        trimOldestScore(scores, MAX_PUBLIC_SCORES)
    end

    return true, "score"
end

function Communication:ExpirePublicScores(now, maximumAge)
    local changed = false

    for name, peer in pairs(self.publicScores) do
        if now - peer.updatedAt > maximumAge then
            self.publicScores[name] = nil
            changed = true
        end
    end

    return changed
end

function Communication:ClearPeerScores()
    self.peerScores = {}
end

function Communication:ClearPublicScores()
    self.publicScores = {}
end

if type(addon) == "table" then
    addon.Communication = Communication
end

return Communication
