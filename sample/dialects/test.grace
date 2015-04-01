import "gUnit" as gu

var currentTestSuiteForDialect := done
var currentSetupBlockForTesting := done
var currentTestBlockForTesting := 0
var currentTestInThisEvaluation := 0

inherits gu.assertion.trait

method test(name:String) by(block:Block) is public {
    if(currentTestSuiteForDialect == done) then {
        Exception.raise("a test can only be created within a testSuite")
    }
    currentTestInThisEvaluation := currentTestInThisEvaluation + 1
    if(currentSetupBlockForTesting != done) then {
        currentTestSuiteForDialect.add(testCaseNamed(name)setupIn(currentSetupBlockForTesting)asTestNumber(currentTestInThisEvaluation))
    } else {
        if(currentTestInThisEvaluation == currentTestBlockForTesting) then {
            block.apply()
        }
    }
}

method testSuite(block:Block) is public {
    if(currentTestSuiteForDialect != done) then {
        Exception.raise("a testSuite cannot be created inside a testSuite")
    }
    currentTestSuiteForDialect := gu.testSuite.empty
    currentSetupBlockForTesting := block
    currentTestInThisEvaluation := 0
    block.apply()
    currentSetupBlockForTesting := done
    currentTestSuiteForDialect.runAndPrintResults()
    currentTestSuiteForDialect := done
    currentTestBlockForTesting := 0
}

method testCaseNamed(name') setupIn(setupBlock) asTestNumber(number) -> gu.TestCase {
    object {
        inherits gu.testCaseNamed(name')
             
        method setup { currentTestBlockForTesting := number; currentTestInThisEvaluation := 0; setupBlock.apply() }
        method teardown { currentTestBlockForTesting := 0 }

        method run (result) {
            result.testStarted(name)
            try {
                try {
                    setup
                } finally { teardown }
            } catch {e: self.AssertionFailure ->
                result.testFailed(name)withMessage(e.message)
            } catch {e: Exception ->
                result.testErrored(name)withMessage "{e.exception}: {e.message}"
            }
            result.testFinished(name)
        }

        method debug (result) {
            result.testStarted(name)
            try {
                print ""
                print "debugging test {name} ..."
                try {
                    setup
                } finally { teardown }
            } catch {e: self.AssertionFailure ->
                result.testFailed(name)withMessage(e.message)
                printBackTrace(e) limitedTo(8)
            } catch {e: Exception ->
                result.testErrored(name)withMessage(e.message)
                printBackTrace(e) limitedTo(8)
            }
            result.testFinished(name)
        }
    }
}
