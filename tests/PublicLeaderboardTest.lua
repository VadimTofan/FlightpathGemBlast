local TestRunner = require("tests.TestRunner")

local function loadPublicLeaderboard()
    return require("Game.PublicLeaderboard")
end

local function createApi(overrides)
    local api = {
        joinChannel = function()
        end,
        leaveChannel = function()
        end,
        getChannelId = function()
            return 0
        end,
        hideChannel = function()
        end,
    }

    for key, value in pairs(overrides or {}) do
        api[key] = value
    end

    return api
end

TestRunner.describe("PublicLeaderboard channel lifecycle", function()
    TestRunner.it("joins the temporary public channel", function()
        -- Given
        local joinedChannel
        local PublicLeaderboard = loadPublicLeaderboard()
        local publicLeaderboard = PublicLeaderboard.New(createApi({
            joinChannel = function(channelName)
                joinedChannel = channelName
            end,
        }))

        -- When
        publicLeaderboard:Join()

        -- Then
        TestRunner.assertEqual("Flightpath Gem Blast", joinedChannel)
        TestRunner.assertTrue(publicLeaderboard.enabled)
        TestRunner.assertEqual("JOINING", publicLeaderboard.state)
        TestRunner.assertEqual("Joining...", publicLeaderboard:GetButtonLabel())
    end)

    TestRunner.it("confirms an asynchronous channel join", function()
        -- Given
        local hiddenChannel
        local PublicLeaderboard = loadPublicLeaderboard()
        local publicLeaderboard = PublicLeaderboard.New(createApi({
            getChannelId = function()
                return 7
            end,
            hideChannel = function(channelName)
                hiddenChannel = channelName
            end,
        }))
        publicLeaderboard:Join()

        -- When
        local newlyConnected = publicLeaderboard:RefreshConnection()

        -- Then
        TestRunner.assertTrue(newlyConnected)
        TestRunner.assertEqual("CONNECTED", publicLeaderboard.state)
        TestRunner.assertEqual(7, publicLeaderboard.channelId)
        TestRunner.assertEqual("Flightpath Gem Blast", hiddenChannel)
        TestRunner.assertEqual(
            "Leave Public Leaderboard",
            publicLeaderboard:GetButtonLabel()
        )
    end)

    TestRunner.it("leaves and clears the public channel state", function()
        -- Given
        local leftChannel
        local PublicLeaderboard = loadPublicLeaderboard()
        local publicLeaderboard = PublicLeaderboard.New(createApi({
            leaveChannel = function(channelName)
                leftChannel = channelName
            end,
            getChannelId = function()
                return 7
            end,
        }))
        publicLeaderboard:Join()
        publicLeaderboard:RefreshConnection()

        -- When
        publicLeaderboard:Leave()

        -- Then
        TestRunner.assertEqual("Flightpath Gem Blast", leftChannel)
        TestRunner.assertFalse(publicLeaderboard.enabled)
        TestRunner.assertEqual("DISCONNECTED", publicLeaderboard.state)
        TestRunner.assertEqual(nil, publicLeaderboard.channelId)
        TestRunner.assertEqual(
            "Join Public Leaderboard",
            publicLeaderboard:GetButtonLabel()
        )
    end)

    TestRunner.it("disconnects locally when WoW rejects the leave call", function()
        -- Given
        local PublicLeaderboard = loadPublicLeaderboard()
        local publicLeaderboard = PublicLeaderboard.New(createApi({
            leaveChannel = function()
                error("channel unavailable")
            end,
            getChannelId = function()
                return 7
            end,
        }))
        publicLeaderboard:Join()
        publicLeaderboard:RefreshConnection()

        -- When
        local succeeded = pcall(function()
            publicLeaderboard:Leave()
        end)

        -- Then
        TestRunner.assertTrue(succeeded)
        TestRunner.assertFalse(publicLeaderboard.enabled)
        TestRunner.assertEqual("DISCONNECTED", publicLeaderboard.state)
    end)

    TestRunner.it("recognizes messages from its connected channel", function()
        -- Given
        local PublicLeaderboard = loadPublicLeaderboard()
        local publicLeaderboard = PublicLeaderboard.New(createApi({
            getChannelId = function()
                return 7
            end,
        }))
        publicLeaderboard:Join()
        publicLeaderboard:RefreshConnection()

        -- When
        local isPublic = publicLeaderboard:IsChannelTarget(
            "7. Flightpath Gem Blast"
        )

        -- Then
        TestRunner.assertTrue(isPublic)
        TestRunner.assertFalse(
            publicLeaderboard:IsChannelTarget("6. AnotherChannel")
        )
        TestRunner.assertFalse(
            publicLeaderboard:IsChannelTarget("8. AnotherChannel")
        )
    end)

    TestRunner.it("reports a failed join without throwing", function()
        -- Given
        local PublicLeaderboard = loadPublicLeaderboard()
        local publicLeaderboard = PublicLeaderboard.New(createApi({
            joinChannel = function()
                error("channel unavailable")
            end,
        }))

        -- When
        local succeeded = publicLeaderboard:Join()

        -- Then
        TestRunner.assertFalse(succeeded)
        TestRunner.assertTrue(publicLeaderboard.enabled)
        TestRunner.assertEqual("ERROR", publicLeaderboard.state)
        TestRunner.assertEqual(
            "Retry Public Leaderboard",
            publicLeaderboard:GetButtonLabel()
        )
    end)

    TestRunner.it("stops waiting when a joined channel never appears", function()
        -- Given
        local PublicLeaderboard = loadPublicLeaderboard()
        local publicLeaderboard = PublicLeaderboard.New(createApi())
        publicLeaderboard:Join()

        -- When
        local connected = publicLeaderboard:RefreshConnection(true)

        -- Then
        TestRunner.assertFalse(connected)
        TestRunner.assertEqual("ERROR", publicLeaderboard.state)
        TestRunner.assertEqual(
            "Retry Public Leaderboard",
            publicLeaderboard:GetButtonLabel()
        )
    end)
end)
