local TestRunner = require("tests.TestRunner")

TestRunner.describe("AddOn metadata", function()
    TestRunner.it("uses the Gem Blast identity", function()
        -- Given
        local tocFile = assert(io.open("GemBlast.toc", "r"))
        local toc = tocFile:read("*a")
        tocFile:close()

        -- When
        local hasTitle = toc:find(
            "## Title: Gem Blast",
            1,
            true
        ) ~= nil
        local hasSavedVariables = toc:find(
            "## SavedVariables: GemBlastDB",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasTitle)
        TestRunner.assertTrue(hasSavedVariables)
    end)

    TestRunner.it("uses the Gem Blast package and slash command", function()
        -- Given
        local pkgmetaFile = assert(io.open(".pkgmeta", "r"))
        local pkgmeta = pkgmetaFile:read("*a")
        pkgmetaFile:close()
        local launcherFile = assert(io.open("Launcher.lua", "r"))
        local launcher = launcherFile:read("*a")
        launcherFile:close()
        local uiFile = assert(io.open("UI.lua", "r"))
        local ui = uiFile:read("*a")
        uiFile:close()

        -- When
        local hasPackageName = pkgmeta:find(
            "package-as: GemBlast",
            1,
            true
        ) ~= nil
        local hasSlashCommand = launcher:find(
            'SLASH_GEMBLAST1 = "/gb"',
            1,
            true
        ) ~= nil
        local hasWindowTitle = ui:find(
            "|cffed55ffGEM|r |cff9f70ffBLAST|r",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(hasPackageName)
        TestRunner.assertTrue(hasSlashCommand)
        TestRunner.assertTrue(hasWindowTitle)
    end)

    TestRunner.it("loads saved data from the previous addon identity", function()
        -- Given
        local tocFile = assert(io.open("GemBlast.toc", "r"))
        local toc = tocFile:read("*a")
        tocFile:close()

        -- When
        local loadsLegacyData = toc:find(
            "## SavedVariables: GemBlastDB, BetterBejeweledDB",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(loadsLegacyData)
    end)

    TestRunner.it("uses the blue gem in the AddOns list", function()
        -- Given
        local tocFile = assert(io.open("GemBlast.toc", "r"))
        local toc = tocFile:read("*a")
        tocFile:close()

        local iconPath = "Media/Gems64/Blue.png"
        local iconFile = io.open(iconPath, "rb")

        -- When
        local hasBlueGemIcon = toc:find(
            "## IconTexture: Interface\\AddOns\\GemBlast"
                .. "\\Media\\Gems64\\Blue.png",
            1,
            true
        ) ~= nil
        local iconExists = iconFile ~= nil

        if iconFile then
            iconFile:close()
        end

        -- Then
        TestRunner.assertTrue(hasBlueGemIcon)
        TestRunner.assertTrue(iconExists)
    end)

    TestRunner.it("loads special effects before the animation director", function()
        -- Given
        local tocFile = assert(io.open("GemBlast.toc", "r"))
        local toc = tocFile:read("*a")
        tocFile:close()

        -- When
        local effectsPosition = toc:find(
            "Animation\\SpecialEffects.lua",
            1,
            true
        )
        local directorPosition = toc:find(
            "Animation\\Director.lua",
            1,
            true
        )

        -- Then
        TestRunner.assertTrue(effectsPosition ~= nil)
        TestRunner.assertTrue(effectsPosition < directorPosition)
    end)
end)
