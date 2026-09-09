local TestRunner = require("tests.TestRunner")

local function readFile(path)
    local file = io.open(path, "r")

    if not file then
        return ""
    end

    local contents = file:read("*a")
    file:close()
    return contents
end

TestRunner.describe("CurseForge release workflow", function()
    TestRunner.it("publishes version tags with the configured project", function()
        -- Given
        local workflow = readFile(".github/workflows/release.yml")
        local toc = readFile("FlightpathGemBlast.toc")

        -- When
        local usesVersionTags = workflow:find(
            'tags:\n      - "v*"',
            1,
            true
        ) ~= nil
        local mapsTokenSecret = workflow:find(
            "CF_API_KEY: ${{ secrets.CF_API_TOKEN }}",
            1,
            true
        ) ~= nil
        local hasProjectId = toc:find(
            "## X-Curse-Project-ID: 1688263",
            1,
            true
        ) ~= nil
        local hasReleaseVersion = toc:find(
            "## Version: 0.1.4",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(usesVersionTags)
        TestRunner.assertTrue(mapsTokenSecret)
        TestRunner.assertTrue(hasProjectId)
        TestRunner.assertTrue(hasReleaseVersion)
    end)

    TestRunner.it("validates the package before uploading it", function()
        -- Given
        local workflow = readFile(".github/workflows/release.yml")

        -- When
        local packagePosition = workflow:find("args: -d", 1, true)
        local validationPosition = workflow:find(
            "name: Validate release archive",
            1,
            true
        )
        local uploadPosition = workflow:find("args: -c", 1, true)
        local checksZipIntegrity = workflow:find("unzip -t", 1, true) ~= nil

        -- Then
        TestRunner.assertTrue(packagePosition ~= nil)
        TestRunner.assertTrue(validationPosition ~= nil)
        TestRunner.assertTrue(uploadPosition ~= nil)
        TestRunner.assertTrue(packagePosition < validationPosition)
        TestRunner.assertTrue(validationPosition < uploadPosition)
        TestRunner.assertTrue(checksZipIntegrity)
    end)

    TestRunner.it("excludes development files from release archives", function()
        -- Given
        local pkgmeta = readFile(".pkgmeta")
        local gitignore = readFile(".gitignore")

        -- When
        local ignoresWorkflow = pkgmeta:find("  - .github", 1, true) ~= nil
        local ignoresTests = pkgmeta:find("  - tests", 1, true) ~= nil
        local ignoresReadme = pkgmeta:find("  - README.md", 1, true) ~= nil
        local ignoresReleaseOutput = gitignore:find(
            ".release",
            1,
            true
        ) ~= nil

        -- Then
        TestRunner.assertTrue(ignoresWorkflow)
        TestRunner.assertTrue(ignoresTests)
        TestRunner.assertTrue(ignoresReadme)
        TestRunner.assertTrue(ignoresReleaseOutput)
    end)
end)
