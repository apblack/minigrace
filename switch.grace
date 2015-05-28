method midpoint (a, b) { a + ((b - a) / 2).rounded }

factory method switchCollection (cases) default (defaultBlock) {
    def size = cases.size
    def caseArray = primitiveArray.new(size)
    var i := 0
    for (cases) do { c -> caseArray[i]:= c; i := i + 1 }
    caseArray.sortInitial(size) by { a, b -> a.key.compare(b.key) }
    method case(key) {
        var min := 0
        var max := size - 1
        while { max >= min } do {
            def mid = midpoint(min, max)
            def cur = caseArray[mid]
            if (key == cur.key) then { return cur.value }              
            if (key <  cur.key) then { max := mid - 1 } else { min := mid + 1 }
        }
        defaultBlock.apply
    }
}

method switch(*cases) default(defaultBlock) { 
    switchCollection(cases) default (defaultBlock)
}

def SwitchCaseNotCovered = Exception.refine "SwitchCaseNotCovered"
method switch(*cases) { 
    switchCollection(cases) default { SwitchCaseNotCovered.raise } 
}

// These examples work.
// Can someone make a better test of correctness for this?
//print (switch ("a"::1).case("a"))
//switch (1::{print "1"}, 2::{print "2"}).case(1).apply
