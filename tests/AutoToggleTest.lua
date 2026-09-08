local TestRunner = require("tests.TestRunner")
local AutoToggle = require("Game.AutoToggle")

TestRunner.describe("AutoToggle", function()
    TestRunner.it("opens the game when a flight starts", function()
        -- Given
        local autoToggle = AutoToggle.New()

        -- When
        local action = autoToggle:Handle(
            "PLAYER_CONTROL_LOST",
            true,
            true,
            false
        )

        -- Then
        TestRunner.assertEqual("show", action)
    end)

    TestRunner.it("opens when the player taxi flag appears", function()
        -- Given
        local autoToggle = AutoToggle.New()

        -- When
        local action = autoToggle:Handle(
            "UNIT_FLAGS",
            true,
            true,
            false
        )

        -- Then
        TestRunner.assertEqual("show", action)
    end)

    TestRunner.it("opens after a delayed taxi-state check", function()
        -- Given
        local autoToggle = AutoToggle.New()

        -- When
        local action = autoToggle:Handle(
            "TAXI_STATE_CHECK",
            true,
            true,
            false
        )

        -- Then
        TestRunner.assertEqual("show", action)
    end)

    TestRunner.it("closes a game that it opened when the flight ends", function()
        -- Given
        local autoToggle = AutoToggle.New()
        autoToggle:Handle("PLAYER_CONTROL_LOST", true, true, false)

        -- When
        local action = autoToggle:Handle(
            "PLAYER_CONTROL_GAINED",
            true,
            false,
            true
        )

        -- Then
        TestRunner.assertEqual("hide", action)
    end)

    TestRunner.it("keeps a manually opened game visible after a flight", function()
        -- Given
        local autoToggle = AutoToggle.New()
        autoToggle:Handle("PLAYER_CONTROL_LOST", true, true, true)

        -- When
        local action = autoToggle:Handle(
            "PLAYER_CONTROL_GAINED",
            true,
            false,
            true
        )

        -- Then
        TestRunner.assertEqual(nil, action)
    end)

    TestRunner.it("closes the game when combat begins", function()
        -- Given
        local autoToggle = AutoToggle.New()

        -- When
        local action = autoToggle:HandleCombat(true, true)

        -- Then
        TestRunner.assertEqual("hide", action)
    end)

    TestRunner.it("does nothing while disabled", function()
        -- Given
        local autoToggle = AutoToggle.New()

        -- When
        local action = autoToggle:HandleCombat(false, true)

        -- Then
        TestRunner.assertEqual(nil, action)
    end)
end)
