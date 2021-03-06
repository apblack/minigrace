dialect "standard"
import "collections" as collections
import "gUnit" as gU

trait dictionaryTest {
    class forMethod(m) {
        inherit gU.testCaseNamed(m)

        var oneToFive
        var evens
        var empty

        method dictionaryUnderTestWith (bindings) {
            collections.dictionary⟦String, Number⟧.withAll (bindings)
        }
        method dictionaryUnderTestEmpty { collections.dictionary.empty }
        method dictionaryUnderTestFactory { collections.dictionary }
        method setup {
            oneToFive := dictionaryUnderTestWith
                    ["one"::1, "two"::2, "three"::3, "four"::4, "five"::5]
            evens := dictionaryUnderTestWith
                    ["two"::2, "four"::4, "six"::6, "eight"::8]
            empty := dictionaryUnderTestEmpty
        }
        method testDictionaryTypeCollection {
            assert (oneToFive) hasType (Collection⟦Binding⟦String,Number⟧⟧)
        }
        method testDictionaryTypeDictionary {
            assert (oneToFive) hasType (Dictionary⟦String,Number⟧)
        }
        method testDictionaryTypeNotTypeWithWombat {
            deny (oneToFive) hasType (Dictionary⟦String,Number⟧ & interface { wombat })
        }

        method testDictionarySize {
            assert(oneToFive.size) shouldBe 5
            assert(empty.size) shouldBe 0
            assert(evens.size) shouldBe 4
        }

        method testDictionarySizeAfterRemove {
            oneToFive.removeKey "one"
            deny(oneToFive.containsKey "one") description "\"one\" still present"
            oneToFive.removeKey "two"
            oneToFive.removeKey "three"
            assert(oneToFive.size) shouldBe 2
        }

        method testDictionaryContentsAfterMultipleRemove {
            oneToFive.removeKey "one" .removeKey "two" .removeKey "three"
            assert(oneToFive.size) shouldBe 2
            deny(oneToFive.containsKey "one") description "\"one\" still present"
            deny(oneToFive.containsKey "two") description "\"two\" still present"
            deny(oneToFive.containsKey "three") description "\"three\" still present"
            assert(oneToFive.containsKey "four")
            assert(oneToFive.containsKey "five")
        }

        method testAsString {
            def dict2 = dictionary⟦String, Number⟧.withAll ["one"::1, "two"::2]
            def dStr = dict2.asString
            assert((dStr == "dictionary [one::1, two::2]") || {dStr == "dictionary [two::2, one::1]"})
                description "\"{dStr}\" should be \"dictionary [one::1, two::2]\""
        }

        method testAsStringEmpty {
            assert(empty.asString) shouldBe "dictionary []"
        }

        method testDictionaryEmptyDo {
            empty.do {each -> failBecause "empty.do did with {each}"}
            assert (true)   // so that there is always an assert
        }

        method testDictionaryEqualityEmpty {
            assert(empty == dictionaryUnderTestEmpty) description "two empty dictionaries are not =="
            deny(empty ≠ dictionaryUnderTestEmpty) description "two empty dictionaries are ≠"
        }
        method testDictionaryInequalityEmpty {
            deny(empty == dictionaryUnderTestWith ["one"::1])
                description "empty dictionary equals dictionary with \"one\"::1"
            assert(empty != dictionaryUnderTestWith ["two"::2])
                description "empty dictionary equals dictionary with \"two\"::2"
            deny(empty == 3) description "the empty dictionary is equal to 3"
            assert (empty) shouldntBe (evens)
        }
        method testDictionaryInequalityFive {
            evens.at "ten" put 10
            assert(evens.size == oneToFive.size) description "evens.size should be 5"
            deny(oneToFive == evens)
            assert(oneToFive != evens)
        }
        method testDictionaryEqualityFive {
            assert(oneToFive == dictionaryUnderTestWith ["one"::1, "two"::2, "three"::3,
                "four"::4, "five"::5])
        }
        method testDictionaryKeysAndValuesDo {
            def accum = dictionaryUnderTestEmpty
            var n := 1
            oneToFive.keysAndValuesDo { k, v ->
                accum.at(k)put(v)
                assert (accum.size) shouldBe (n)
                n := n + 1
            }
            assert(accum) shouldBe (oneToFive)
        }
        method testDictionaryEmptyBindingsIterator {
            deny (empty.bindings.iterator.hasNext)
                description "the empty bindings iterator has elements"
        }
        method testDictionaryEvensBindingsIterator {
            def ei = evens.bindings.iterator
            assert (evens.size == 4) description "evens doesn't contain 4 elements!"
            assert (ei.hasNext) description "evens.bindings.iterator has no elements"
            def copyDict = dictionaryUnderTestWith [ei.next, ei.next, ei.next, ei.next]
            deny (ei.hasNext) description "evens.bindings.iterator has more than 4 elements"
            assert (copyDict) shouldBe (evens)
        }
        method testDictionaryAtPutReturnsTheDictionary {
            assert (empty.at "nine" put 9)
                shouldBe (dictionaryUnderTestWith ["nine"::9])
            assert (evens.at "ten" put 10.values >> set)
                shouldBe (set [2, 4, 6, 8, 10])
        }
        method testDictionaryRemoveKeyTwo {
            assert (evens.removeKey "two".values >> set) shouldBe (set [4, 6, 8])
            assert (evens.values >> set) shouldBe (set [4, 6, 8])
        }
        method testDictionaryRemoveAllValues {
            evens.removeAllValues [2, 6, 8]
            assert (evens.size) shouldBe 1
            assert (dict(evens) equals (dictionaryUnderTestWith ["four"::4]))
        }
        method testDictionaryRemoveAllKeys {
            evens.removeAllKeys ["two", "six", "eight"]
            assert (evens.size) shouldBe 1
            assert (evens.at "four") shouldBe 4
        }
        method testDictionaryRemoveValue4 {
            assert (evens.size == 4) description "evens doesn't contain 4 elements"
            assert (evens.size == 4) description "initial size of evens isn't 4"
            evens.removeValue 4
            assert (evens.size == 3)
                description "after removing 4, 3 elements should remain in evens"
            assert (evens.containsKey "two") description "Can't find key \"two\""
            assert (evens.containsKey "six") description "Can't find key \"six\""
            assert (evens.containsKey "eight") description "Can't find key \"eight\""
            deny (evens.containsKey "four") description "Found key \"four\""
            assert (evens.removeValue 4 ifAbsent { }.values >> set) shouldBe (set [2, 6, 8])
            assert (evens.values >> set) shouldBe (set [2, 6, 8])
            assert (evens.keys >> set) shouldBe (set ["two", "six", "eight"])
        }
        method testDictionaryRemoveMultiple {
            evens.removeValue 4 .removeValue 6 .removeValue 8
            assert (evens) shouldBe (dictionary.empty.at "two" put 2)
        }
        method testDictionaryRemove5 {
            assert {evens.removeKey 5} shouldRaise (NoSuchObject | TypeError)
            // TypeError if the type parameters are checked, NoSuchObejct otherwise
        }
        method testDictionaryRemoveTwice {
            evens.removeKey "four"
            deny (evens.containsKey "four") description "evens contains key \"four\" after it was removed"
            assert {evens.removeKey "four"} shouldRaise (NoSuchObject)
        }
        method testDictionaryRemoveKeyFive {
            assert {evens.removeKey "Five"} shouldRaise (NoSuchObject)
        }
        method testDictionaryChaining {
            oneToFive.at "eleven" put(11).at "twelve" put(12).at "thirteen" put(13)
            assert (oneToFive.values >> set) shouldBe (set [1, 2, 3, 4, 5, 11, 12, 13])
        }
        method testDictionaryPushAndExpand {
            evens.removeKey "two"
            evens.removeKey "four"
            evens.removeKey "six"
            evens.at "ten" put(10)
            evens.at "twelve" put(12)
            evens.at "fourteen" put(14)
            evens.at "sixteen" put(16)
            evens.at "eighteen" put(18)
            evens.at "twenty" put(20)
            assert (evens.values >> set)
                shouldBe (set [8, 10, 12, 14, 16, 18, 20])
        }

        method testDictionaryFold {
            assert(oneToFive.fold{a, each -> a + each}startingWith(5))shouldBe(20)
            assert(evens.fold{a, each -> a + each}startingWith(0))shouldBe(20)
            assert(empty.fold{a, each -> a + each}startingWith(17))shouldBe(17)
        }

        method testDictionaryDoSeparatedBy {
            var s := ""
            evens.removeValue 2 .removeValue 4
            evens.do { each -> s := s ++ each.asString } separatedBy { s := s ++ ", " }
            assert ((s == "6, 8") || (s == "8, 6"))
                description "{s} should be \"8, 6\" or \"6, 8\""
        }

        method testDictionaryDoSeparatedByEmpty {
            var s := "nothing"
            empty.do { failBecause "do did when list is empty" }
                separatedBy { s := "kilroy" }
            assert (s) shouldBe ("nothing")
        }

        method testDictionaryConcat {
            def d1 = dictionaryUnderTestWith ["one"::1]
            def d2 = dictionaryUnderTestWith ["three"::3]
            assert (d1 ++ d2) shouldBe (dictionaryUnderTestWith ["one"::1, "three"::3])
        }

        method testDictionaryConcatAndOverride {
            def d1 = dictionaryUnderTestWith ["one"::0]
            def d2 = dictionaryUnderTestWith ["three"::3, "one"::1]
            assert (d1 ++ d2) shouldBe (dictionaryUnderTestWith ["one"::1, "three"::3])
        }

        method testDictionaryDoSeparatedBySingleton {
            var s := "nothing"
            dictionaryUnderTestWith ["key"::1].do { each -> assert(each)shouldBe(1) }
                separatedBy { s := "kilroy" }
            assert (s) shouldBe ("nothing")
        }

        method testDictionaryAsStringNonEmpty {
            evens.removeValue(6)
            evens.removeValue(8)
            def evensString = evens.asString
            assert ((evensString == "dictionary [two::2, four::4]") ||
                        (evensString == "dictionary [four::4, two::2]"))
                        description "evens.asString = {evensString}"
        }

        method testDictionaryAsStringEmpty {
            assert (empty.asString) shouldBe ("dictionary []")
        }

        method testDictionaryMapEmpty {
            assert (empty.map{x -> x * x} >> set) shouldBe (set.empty)
        }

        method testDictionaryMapEvens {
            assert(evens.map{x -> x + 1} >> set) shouldBe (set [3, 5, 7, 9])
        }

        method testDictionaryMapEvensInto {
            assert(evens.map{x -> x + 10} >> set.withAll(evens))
                shouldBe (set [2, 4, 6, 8, 12, 14, 16, 18])
        }

        method testDictionaryFilterNone {
            assert(oneToFive.filter{x -> false}.isEmpty)
        }

        method testDictionaryFilterEmpty {
            assert(empty.filter{x -> (x % 2) == 1}.isEmpty)
        }

        method testDictionaryFilterOdd {
            assert(oneToFive.filter{x -> (x % 2) == 1} >> set)
                shouldBe (set [1, 3, 5])
        }

        method testDictionaryMapAndFilter {
            assert(set.withAll(oneToFive.map{x -> x + 10}.filter{x -> (x % 2) == 1}))
                shouldBe (set [11, 13, 15])
        }
        method testDictionaryBindings {
            assert(oneToFive.bindings >> set) shouldBe (
                set ["one"::1, "two"::2, "three"::3, "four"::4, "five"::5])
        }
        method testDictionaryKeys {
            assert(oneToFive.keys >> set) shouldBe (
                set ["one", "two", "three", "four", "five"] )
        }
        method testDictionaryValues {
            assert(oneToFive.values >> set) shouldBe (
                set [1, 2, 3, 4, 5] )
        }

        method testDictionaryCopy {
            def evensCopy = evens.copy
            evens.removeKey("two")
            evens.removeValue(4)
            assert (evens.size) shouldBe 2
            assert (evensCopy) shouldBe
                (dictionary ["two"::2, "four"::4, "six"::6, "eight"::8])
        }
        method dict(a)equals(b) {
            // a helper method that shows where two dictionaries differ
            def ak = a.keys.sorted
            def bk = b.keys.sorted
            assert (ak == bk) description "keys {ak} ≠ {bk}"
            a.keysAndValuesDo{k, v ->
                assert (b.at(k) == v) description "a.at({k}) = {v} but b.at({k}) = {b.at(k)}"
            }
            true
        }
        method testPipeIntoExistingDictionary {
            def witness = evens.bindings >> oneToFive
            assert (dict(witness) equals (
                dictionaryUnderTestWith ["one"::1, "two"::2, "three"::3,
                      "four"::4, "five"::5, "six"::6, "eight"::8]))
            assert (oneToFive) shouldBe (
                dictionaryUnderTestWith ["one"::1, "two"::2, "three"::3,
                      "four"::4, "five"::5, "six"::6, "eight"::8])
        }
        method testPipeBindingSequenceIntoExistingDictionary {
            def witness = ["two"::2, "four"::4, "six"::6, "eight"::8] >> oneToFive
            assert (dict(witness) equals (
                dictionaryUnderTestWith ["one"::1, "two"::2, "three"::3,
                      "four"::4, "five"::5, "six"::6, "eight"::8]))
            assert (oneToFive) shouldBe (
                dictionaryUnderTestWith ["one"::1, "two"::2, "three"::3,
                      "four"::4, "five"::5, "six"::6, "eight"::8])
        }
        method testPipeIntoEmptyInstance {
            assert (dict(evens.bindings >> dictionary.empty) equals (evens))
        }
        method testLeftPipeIntoEmptyInstance {
            assert (dict(dictionary.empty << evens.bindings) equals (evens))
        }
        method testPipeIntoFactory {
            assert (["two"::2, "four"::4, "six"::6, "eight"::8] >> dictionaryUnderTestFactory)
                shouldBe (evens)
        }
        method testDictionaryValuesEmpty {
            def vs = empty.values
            assert(vs.isEmpty)
            assert(vs) shouldBe []
        }
        method testDictionaryKeysEmpty {
            assert(empty.keys) shouldBe []
        }
        method testDictionaryValuesSingle {
            assert(dictionary ["one"::1].values) shouldBe
                (sequence [1])
        }
        method testDictionaryKeysSingle {
            assert(dictionary ["one"::1].keys) shouldBe
                (sequence ["one"])
        }
        method testDictionaryBindingsEvens {
            assert(set.withAll(evens.bindings)) shouldBe
                (set ["two"::2, "four"::4, "six"::6, "eight"::8])
        }
        method testDictionarySortedOnValues {
            assert(evens.bindings.sortedBy{b1, b2 -> b1.value.compare(b2.value)})
                shouldBe (sequence ["two"::2, "four"::4, "six"::6, "eight"::8])
        }
        method testDictionarySortedOnKeys {
            assert(evens.bindings.sortedBy{b1, b2 -> b1.key.compare(b2.key)})
                shouldBe (sequence ["eight"::8, "four"::4, "six"::6, "two"::2])
        }
        method testDictionaryFailFastValuesDoRemoveKey {
            assert {
                oneToFive.valuesDo { v ->
                    oneToFive.removeKey "one" ifAbsent {}
                }
            } shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastValuesDoRemoveValue {
            assert {
                oneToFive.valuesDo { v ->
                    oneToFive.removeValue 1 ifAbsent {}
                }
            } shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastValuesDoAtPut {
            assert {
                oneToFive.valuesDo { v ->
                    if (! oneToFive.containsKey "zero") then {
                        oneToFive.at "zero" put 0
                    }
                }
            } shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastKeysDoRemoveKey {
            assert {
                oneToFive.keysDo { k ->
                    oneToFive.removeKey "one" ifAbsent {}
                }
            } shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastKeysDoRemoveValye {
            assert {
                oneToFive.keysDo { k ->
                    oneToFive.removeValue 1 ifAbsent {}
                }
            } shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastKeysDoAtPut {
            assert {
                oneToFive.keysDo { k ->
                    if (! oneToFive.containsKey "zero") then {
                        oneToFive.at "zero" put 0
                    }
                }
            } shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastIteratorValues {
            def iter = oneToFive.iterator
            oneToFive.at "three" put(100)
            assert {iter.next} shouldRaise (ConcurrentModification)
            def iter2 = oneToFive.iterator
            oneToFive.at "three"
            assert {iter2.next} shouldntRaise (ConcurrentModification)
            def iter3 = oneToFive.iterator
            oneToFive.removeValue(2)
            assert {iter3.next} shouldRaise (ConcurrentModification)
            def iter4 = oneToFive.iterator
            oneToFive.removeKey("four")
            assert {iter4.next} shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastIteratorKeys {
            def iter = oneToFive.keys.iterator
            oneToFive.at "three" put(100)
            assert {iter.next} shouldRaise (ConcurrentModification)
            def iter2 = oneToFive.keys.iterator
            oneToFive.at "three"
            assert {iter2.next} shouldntRaise (ConcurrentModification)
            def iter3 = oneToFive.keys.iterator
            oneToFive.removeValue(2)
            assert {iter3.next} shouldRaise (ConcurrentModification)
            def iter4 = oneToFive.keys.iterator
            oneToFive.removeKey("four")
            assert {iter4.next} shouldRaise (ConcurrentModification)
        }
        method testDictionaryFailFastIteratorBindings {
            def iter = oneToFive.bindings.iterator
            oneToFive.at "three" put(100)
            assert {iter.next} shouldRaise (ConcurrentModification)
            def iter2 = oneToFive.bindings.iterator
            oneToFive.at "three"
            assert {iter2.next} shouldntRaise (ConcurrentModification)
            def iter3 = oneToFive.bindings.iterator
            oneToFive.removeValue(2)
            assert {iter3.next} shouldRaise (ConcurrentModification)
            def iter4 = oneToFive.bindings.iterator
            oneToFive.removeKey("four")
            assert {iter4.next} shouldRaise (ConcurrentModification)
        }
        method testDictionaryClear {
            assert (evens.clear) shouldBe (dictionary.empty)
        }
        method testDictionaryAnySatisfy {
            assert (oneToFive.anySatisfy { x -> (x/2).isEven })
                description "oneToFive does not contain an x s.t. x/2 is even"
            deny (empty.anySatisfy {_ -> true})
                description "empty includes some element!"
            deny (oneToFive.anySatisfy {x -> x > 5})
                description "oneToFive includes an element greater than 5"
            deny (oneToFive.anySatisfy { x -> x == 6 }) description "oneToFive includes 6"
        }
        method testDictionaryAllSatisfy {
            assert (oneToFive.allSatisfy { x -> (x/2) < x })
                description "not all of oneToFive are s.t. x > x/2"
            assert (empty.allSatisfy {_ -> false})
                description "all of empty satisfies all predicates"
            deny (oneToFive.allSatisfy {x -> x > 2})
                description "all of oneToFive are greater than 2"
            assert (oneToFive.allSatisfy { x -> x ≠ 6 }) description "one of oneToFive == 6"
        }
        method testDictionaryMultipleRemoves {
            // this test causes set to fill up with removed tombestones,
            // even though it stillhas plenty of space
            var smallDict := dictionary.with (1::2)
            assert (smallDict) shouldBe (dictionary.with (1::2))
            (2..1000).do { each → 
                smallDict.add(each::(each*2))
                smallDict.removeKey(each)
            }
            assert (smallDict) shouldBe (dictionary.with (1::2))
        }
    }
}
