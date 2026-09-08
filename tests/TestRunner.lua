local TestRunner = {
    failures = 0,
    testsRun = 0,
}

local function formatValue(value)
    if type(value) == "string" then
        return string.format("%q", value)
    end

    return tostring(value)
end

function TestRunner.describe(name, callback)
    print(name)
    callback()
end

function TestRunner.it(name, callback)
    TestRunner.testsRun = TestRunner.testsRun + 1

    local succeeded, message = pcall(callback)
    if succeeded then
        print("  PASS " .. name)
        return
    end

    TestRunner.failures = TestRunner.failures + 1
    print("  FAIL " .. name)
    print("       " .. tostring(message))
end

function TestRunner.assertEqual(expected, actual)
    if expected ~= actual then
        error(
            "expected " .. formatValue(expected)
                .. ", received " .. formatValue(actual),
            2
        )
    end
end

function TestRunner.assertTrue(value)
    if value ~= true then
        error("expected true, received " .. formatValue(value), 2)
    end
end

function TestRunner.assertFalse(value)
    if value ~= false then
        error("expected false, received " .. formatValue(value), 2)
    end
end

function TestRunner.finish()
    print(
        string.format(
            "\n%d tests, %d failures",
            TestRunner.testsRun,
            TestRunner.failures
        )
    )

    if TestRunner.failures > 0 then
        os.exit(1)
    end
end

return TestRunner
