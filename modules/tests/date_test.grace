dialect "minitest"
import "date" as date

testSuite {
    def example = date.fromString "26 March 2016, 13:51:25 PDT"

    test "year" by { assert (example.year) shouldBe 2016 }
    test "month" by { assert (example.month) shouldBe 3 }
    test "day of week" by { assert (example.day) shouldBe 7 }  //day of week — Saturday
    test "day of month" by { assert (example.date) shouldBe 26 }
    test "hour" by {
        assert ((example + date.timeZoneOffset).hour) shouldBe 20
    }
    test "minute" by { assert (example.minute) shouldBe 51 }
    test "second" by { assert (example.second) shouldBe 25 }
    test "ISO String" by {
        assert (example.asIsoString) shouldBe "2016-03-26T20:51:25.000Z"
    }
    test "addition" by {
        def twoDays = date.days 2
        def oneHour = date.hours 1
        def base = date.fromString "22 Nov 2015, 16:33:20"  // local TZ
        def later = base + twoDays + oneHour
        assert (later.date) shouldBe 24
        assert (later.hour) shouldBe 17
        assert (later.minute) shouldBe 33
        assert (later.second) shouldBe 20
    }
}

