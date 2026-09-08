local TestRunner = require("tests.TestRunner")

TestRunner.describe("AddOn metadata", function()
    TestRunner.it("uses the blue gem in the AddOns list", function()
        -- Given
        local tocFile = assert(io.open("BetterBejeweled.toc", "r"))
        local toc = tocFile:read("*a")
        tocFile:close()

        local iconPath = "Media/Gems64/Blue.png"
        local iconFile = io.open(iconPath, "rb")

        -- When
        local hasBlueGemIcon = toc:find(
            "## IconTexture: Interface\\AddOns\\BetterBejeweled"
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
end)

