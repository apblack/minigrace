dialect "minitest"
import "lexer" as lexer
import "parser" as parser
import "util" as util

method astNode (kind) from (code) {
    def toks = lexer.lexString(code)
    // print ("-" * 50)
    // toks.do { t -> print "{t.kind}: {t.value}"}
    // print ("=" * 50)
    def module = parser.parse(toks)
    def result = module.body.first
    assert (result.kind) shouldBe (kind)
    result
}

testSuite {
    test "methodRequest" by {
        def a = astNode "call" from
            ‹someTarget.firstPart(arg1, arg2) seceondPart(arg3) thirdPart "arg4"›
        assert (a.toGrace 1) shouldBe
            ‹someTarget.firstPart(arg1, arg2) seceondPart(arg3) thirdPart "arg4"›
    }

    test "typeDec" by {
        def a = astNode "typedec" from ‹type NewType⟦T⟧ = interface {
    foo → Done
    bar(x:T) → NewType ⟦T⟧
}›
        assert (a.toGrace 0) shouldBe
              ‹type NewType⟦T⟧ = interface {
        foo → Done
        bar(x:T) → NewType⟦T⟧}›
    }

    test "methodSignature" by {
        def a = astNode "typeliteral" from
            ‹interface {
    firstPart(param1:Number, param2:String)
        seceondPart(param3:interface{foo→Done})
        thirdPart(param4:NewType⟦T⟧)
}›
        def sig = a.methods.first
        assert (sig.kind) shouldBe "methodtype"
        assert (sig.toGrace 1) shouldBe
              ‹firstPart(param1:Number, param2:String)seceondPart(param3:interface {
                    foo → Done})thirdPart(param4:NewType⟦T⟧)›
    }
}
