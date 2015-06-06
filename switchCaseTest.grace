// Ian Van Houdt
import "gUnit" as gU

print "Testing the 'Switch...Case' implementation for Grace"

def switchTest = object {
    class forMethod(m) {
        inherits gU.testCaseNamed(m)
        
        //defs to be tested
        def five = 5
        def ten = 10
        def fifty = 50
        def fiveString = "five"
        def tenString = "ten"
        def fiftyString = "fifty"

        method testSwitchInteger {
            var x := "empty"
            var y := "empty"
            var z := "empty"
            switch(five)
                case { 0 -> x := "zero" }
                case { 5 -> x := "five" }
                case { 10 -> x := "ten" }
                case { _ -> x := "did not match" }
            switch(ten)
                case { 0 -> y := "zero" }
                case { 5 -> y := "five" }
                case { 10 -> y := "ten" }
                case { _ -> y := "did not match" }
            switch(fifty)
                case { 0 -> z := "zero" }
                case { 5 -> z := "five" }
                case { 10 -> z := "ten" }
                case { _ -> z := "did not match" }

            assert(x) shouldBe("five")
            assert(y) shouldBe("ten")
            assert(z) shouldBe("did not match")
        }

        method testSwitchStrings {
            var x := 0
            var y := 0
            var z := 0
            switch(fiveString)
                case { "zero" -> x := 0 }
                case { "five" -> x := 5 }
                case { "ten" -> x := 10 }
                case { _ -> x := "did not match" }
            switch(tenString)
                case { "zero" -> y := 0 }
                case { "five" -> y := 5 }
                case { "ten" -> y := 10 }
                case { _ -> y := "did not match" }
            switch(fiftyString)
                case { "zero" -> z := 0 }
                case { "five" -> z := 5 }
                case { "ten" -> z := 10 }
                case { _ -> z := "did not match" }
            assert(x) shouldBe(5)
            assert(y) shouldBe(10)
            assert(z) shouldBe("did not match")
        }

        method testSwitchType {
            def string = "Something"
            def number = 100
            var x := "Empty"
            var y := 0
            switch(string)
                case { i : String -> x := "true" }
                case { _ -> x := "false" }
            switch(number)
                case { i : Number -> y := "true" }
                case { _ -> y := "false" }
            assert(x) shouldBe("true")
            assert(y) shouldBe("true")
        }

        method testSwitchWithExpression {
            def tabulatedDouble = { n -> switch(n)
                case { 100 -> 200 }
                case { 200 -> 400 }
            }
            assert (tabulatedDouble.apply(100)) shouldBe(200)
            assert (tabulatedDouble.apply(200)) shouldBe(400)
        }

        method testSwitchWithExplicitException {
            def NotFound = Exception.refine "NotFound"
            def block = { n -> switch(n)
                case { _ -> NotFound.raise "This is an invalid case" }
            }
            assert {block.apply(0)} shouldRaise(NotFound)
        }

        method testSwitchWithImplicitException {
            def block = { n -> switch(n)
                case { 100 -> 200 }
            }
            def blockWithDefault = { n -> switch(n)
                case { 100 -> 200 }
                case { _ -> 0 }
            }
            assert {block.apply(0)} shouldRaise(Exception)
            assert (blockWithDefault.apply(0)) shouldBe(0)
        }
    }
}

def switchTests = gU.testSuite.fromTestMethodsIn(switchTest).debugAndPrintResults

