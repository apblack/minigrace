dialect "none"
import "collections" as collections
import "intrinsic" as intrinsic

use intrinsic.annotations

def ConcurrentModification is public =
    intrinsic.constants.ProgrammingError.refine "ConcurrentModification"

type Binding⟦K,T⟧ = collections.Binding⟦K,T⟧
type Collection⟦T⟧ = collections.Collection⟦T⟧
def NoSuchObject = collections.NoSuchObject
def IteratorExhausted = collections.IteratorExhausted

method emptyJSMap {
    native "js" code ‹return new Map();›
}


def removed = object {
    // Used as a tombstone to mark the location of a removed VALUE.
    // The key, and the key-value binding object, remain in the dictionary
    method asString { "removed" }
    method == (other) { self.isMe(other) }
    method ≠ (other) { self.isMe(other).not }
    method hash { self.myIdentityHash }
}

once class dictionary⟦K,T⟧ {

    method asString { "the dictionary factory" }
    method empty { dictionary⟦K,T⟧ [] }
    method with(aBinding) { dictionary⟦K,T⟧ [aBinding] }
    method withAll(initial: Collection⟦Binding⟦K,T⟧⟧) { dictionary⟦K,T⟧ (initial) }
    method << (source:Collection⟦Binding⟦K,T⟧⟧) { self.withAll(source) }
}

class dictionary⟦K, T⟧ (initialBindings: Collection⟦Binding⟦K,T⟧⟧) {

    use collections.collection⟦T⟧
    var mods is readable := 0
    var numBindings := 0
    var table := emptyJSMap

    initialBindings.do { b:Binding -> self.add(b) }

    method size { numBindings }

    method at (k) put (v) {
        mods := mods + 1
        native "js" code ‹var hc = request(var_k, "hash", [0])._value;
            while (true) {
                let b = this.data.table.get(hc)
                if (! b) break;  // get answers undedined if the key is not present
                if (Grace_isTrue(request(b.key, "==(1)", [1], var_k))) {
                    if (var_removed === b.value) {
                        this.data.numBindings = new GraceNum(this.data.numBindings._value + 1);
                    }   // otherwise, we are overwriting an existing binding
                    b.value = var_v;
                    return this;
                }
                hc++;
            }
            this.data.table.set(hc, {key: var_k, value: var_v});
            this.data.numBindings = new GraceNum(this.data.numBindings._value + 1);
            return this;
        ›
    }
    method add(aBinding) {
        self.at (aBinding.key) put (aBinding.value)
    }
    method addAll(bindings) {
        bindings.do{ each -> add(each) }
        self    // for chaining
    }
    method rehash is confidential {
        // makes a new map, without any of the removed entries
        mods := mods + 1
        numBindings := 0;
        native "js" code ‹
        let oldT = this.data.table;
        this.data.table = new Map();
        for (let p of oldT.values()) {
            if (var_removed !== p.value) {
                request(this, 'at(1)put(1)', [2], p.key, p.value);
            }
        }
        ›
        self
    }
    method at(k) {
        native "js" code ‹
        var hc = request(var_k, "hash", [0])._value;
        while (true) {
            let b = this.data.table.get(hc);
            if (! b) break;
            if (Grace_isTrue(request(b.key, "==(1)", [1], var_k))) {
                if (var_removed === b.value) break;
                return b.value;
            }
            hc++;
        }›
        NoSuchObject.raise "dictionary does not contain entry with key {k}"
    }
    method at(k) ifAbsent(action) {
        native "js" code ‹
        var hc = request(var_k, "hash", [0])._value;
        while (true) {
            let b = this.data.table.get(hc);
            if (! b) break;
            if (Grace_isTrue(request(b.key, "==(1)", [1], var_k))) {
                if (var_removed === b.value) break;
                return b.value;
            }
            hc++;
        }›
        action.apply
    }
    method containsKey(k) {
        native "js" code ‹
        var hc = request(var_k, "hash", [0])._value;
        while (true) {
            let b = this.data.table.get(hc);
            if (! b) break;
            if (Grace_isTrue(request(b.key, "==(1)", [1], var_k))) {
                return (var_removed === b.value ? GraceFalse : GraceTrue);
            }
            hc++;
        };
        return GraceFalse;›
    }
    method removeAllKeys(keys) {
        mods := mods + 1
        keys.do { k → removeKey(k) }
        self
    }
    method removeKey(k) {
        mods := mods + 1
        native "js" code ‹
        var hc = request(var_k, "hash", [0])._value;
        while (true) {
            let b = this.data.table.get(hc);
            if (! b) break;
            if (Grace_isTrue(request(b.key, "==(1)", [1], var_k))) {
                if (var_removed === b.value) break;
                b.value = var_removed;
                this.data.numBindings = new GraceNum(this.data.numBindings._value - 1);
                return this;
            }
            hc++;
        };›
        NoSuchObject.raise "dictionary does not contain entry with key {k}"
    }
    method removeKey(k) ifAbsent (action) {
        native "js" code ‹
        var hc = request(var_k, "hash", [0])._value;
        while (true) {
            let b = this.data.table.get(hc);
            if (! b) break;
            if (Grace_isTrue(request(b.key, "==(1)", [1], var_k))) {
                if (var_removed === b.value) break;
                b.value = var_removed;
                this.data.numBindings = new GraceNum(this.data.numBindings._value - 1);
                this.data.mods = new GraceNum(this.data.mods._value + 1)
                if (this.data.table.size > (2 * this.data.numBindings._value))
                    selfRequest(this, 'rehash');
                return this;
            }
            hc++;
        };›
        action.apply
    }
    method removeAllValues(removals) {
        // remove all bindings with any of the values in removals
        mods := mods + 1
        native "js" code ‹
        let t = this.data.table
        for (let b of t.values()) {
            if (Grace_isTrue(request(var_removals, 'contains(1)', [1], b.value))) {
                b.value = var_removed;
                this.data.numBindings = new GraceNum(this.data.numBindings._value - 1);
            }
        };
        if (this.data.table.size > (2 * this.data.numBindings._value))
            selfRequest(this, 'rehash');
        ›
        self
    }
    method removeValue(v) {
        // remove all bindings with value v
        mods := mods + 1
        def initialNumBindings = numBindings
        native "js" code ‹
        let t = this.data.table
        for (let b of t.values()) {
            if (Grace_isTrue(request(var_v, '==(1)', [1], b.value))) {
                b.value = var_removed;
                this.data.numBindings = new GraceNum(this.data.numBindings._value - 1);
            }
        };›
        if (numBindings == initialNumBindings) then {
            NoSuchObject.raise "dictionary does not contain any entries with value {v}"
        }
        self
    }
    method removeValue(v) ifAbsent (action) {
        // remove all bindings with value v
        mods := mods + 1
        def initialNumBindings = numBindings
        native "js" code ‹
        let t = this.data.table
        for (let b of t.values()) {
            if (Grace_isTrue(request(var_v, '==(1)', [1], b.value))) {
                b.value = var_removed;
                this.data.numBindings = new GraceNum(this.data.numBindings._value - 1);
            }
        };›
        if (numBindings == initialNumBindings) then {
            action.apply
        }
        self
    }
    method clear {
        native "js" code ‹this.data.table.clear();›
        numBindings := 0
        mods := mods + 1
        self
    }
    method containsValue(v) {
        self.valuesDo{ each ->
            if (v == each) then { return true }
        }
        false
    }
    method contains(v) { containsValue(v) }
    method asString {
        // do()separatedBy won't work, because it iterates over values,
        // and we need an iterator over bindings.
        native "js" code ‹
        var s = "dictionary [";
        var first = true;
        let t = this.data.table;
        for (let p of t.values()) {
            if (var_removed !== p.value) {
                if (first)
                    first = false;
                else
                    s += ", ";
                s += request(p.key, "asString", [0])._value;
                s += "::";
                s += request(p.value, "asString", [0])._value;
            }
        }
        s += "]";
        return new GraceString(s);
    ›
    }
    method asDebugString {
        native "js" code ‹
        const t = this.data.table;
        const size = this.data.numBindings._value;
        const cap = t.size;
        var s = "mapDict " + size + "/" + cap + "⟬";
        var first = true;
        for (let p of t.values()) {
            if (first)
                first = false;
            else
                s += ", ";
            s += request(p.key, "asDebugString", [0])._value;
            s += "::";
            s += request(p.value, "asDebugString", [0])._value;
        }
        s += "⟭";
        return new GraceString(s);
    ›
    }
    method keys  {
        def sourceDictionary = self
        object {
            use collections.enumerable⟦K⟧
            class iterator {
                def sourceIterator = sourceDictionary.bindingsIterator
                method hasNext { sourceIterator.hasNext }
                method next { sourceIterator.next.key }
                method asString {
                    "an iterator over keys of {sourceDictionary}"
                }
            }
            def size is public = sourceDictionary.size
            method asString {
                "a lazy sequence over keys of {sourceDictionary}"
            }
        }
    }
    method values {
        def sourceDictionary = self
        object {
            use collections.enumerable⟦T⟧
            class iterator {
                def sourceIterator = sourceDictionary.bindingsIterator
                // should be request on outer
                method hasNext { sourceIterator.hasNext }
                method next { sourceIterator.next.value }
                method asString {
                    "an iterator over values of {sourceDictionary}"
                }
            }
            def size is public = sourceDictionary.size
            method asString {
                "a lazy sequence over values of {sourceDictionary}"
            }
        }
    }
    method bindings {
        def sourceDictionary = self
        object {
            use collections.enumerable⟦T⟧
            method iterator { sourceDictionary.bindingsIterator }
            // should be request on outer
            def size is public = sourceDictionary.size
            method asString {
                "a lazy sequence over bindings of {sourceDictionary}"
            }
        }
    }
    method iterator { values.iterator }
    class bindingsIterator {
        // this should be confidential, but can't be until `outer` is fixed.
        def iMods = mods
        var count := 1
        def subjectDictionary = outer;
        native "js" code ‹this.data.allTheKeys = this.data.subjectDictionary.data.table.keys();
        ›
        method hasNext { size >= count }
        method next {
            if (iMods != mods) then {
                ConcurrentModification.raise (outer.asString)
            }
            if (size < count) then { IteratorExhausted.raise "over {outer.asString}" }
            native "js" code ‹
            let binding = request(var_collections, 'binding', [0]);
            while (true) {
                let iResult = this.data.allTheKeys.next();
                if (iResult.done) break;
                let nextKey = iResult.value
                let b = this.data.subjectDictionary.data.table.get(nextKey);
                    if (var_removed !== b.value) {
                        this.data.count = new GraceNum(this.data.count._value + 1);
                        return request(binding, 'key(1)value(1)',  [1,1], b.key, b.value);
                    }
            }
            ›
            // This exception should never be raised, because the (size < count) guard
            // before the native code means that iResult.done will never occur
            IteratorExhausted.raise "(JSIterator) over {outer.asString}"
        }
    }
    method keysAndValuesDo(block2) {
        native "js" code ‹
        let t = this.data.table;
        let iMods = this.data.mods._value;
        for (let p of t.values()) {
            if (var_removed !== p.value) {
                if (iMods !== this.data.mods._value)
                    request(var_ConcurrentModification, "raise(1)", [1], request(this, "asDebugString", [0]));
                request(var_block2, 'apply(2)', [2], p.key, p.value);
            }
        }
        ›
    }
    method keysDo(block1) {
        native "js" code ‹
        let t = this.data.table;
        let iMods = this.data.mods._value;
        for (let p of t.values()) {
            if (var_removed !== p.value) {
                if (iMods !== this.data.mods._value)
                    request(var_ConcurrentModification, "raise(1)", [1], request(this, "asDebugString", [0]));
                request(var_block1, 'apply(1)', [1], p.key);
            }
        }
        ›
    }
    method valuesDo(block1) {
        native "js" code ‹
        let t = this.data.table;
        let iMods = this.data.mods._value;
        for (let p of t.values()) {
            if (var_removed != p.value) {
                if (iMods !== this.data.mods._value)
                    request(var_ConcurrentModification, "raise(1)", [1], request(this, "asDebugString", [0]));
                request(var_block1, 'apply(1)', [1], p.value);
            }
        }
        ›
    }
    method do(block1) { valuesDo(block1) }

    method ==(other) {
        match (other) case { o:collections.ComparableToDictionary⟦K,T⟧ ->
            if (self.size != o.size) then {return false}
            self.keysAndValuesDo { k, v ->
                if (o.at(k)ifAbsent{return false} != v) then {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }
    method ≠ (other) { (self == other).not }

    method copy {
        def newCopy = dictionary⟦K,T⟧ []
        self.keysAndValuesDo{ k, v ->
            newCopy.at(k) put(v)
        }
        newCopy
    }

    method ++ (other:Collection⟦T⟧) {
        // answers a new dictionary containing all my keys and the keys of other;
        // if other contains one of my keys, other's value overrides mine
        def newDict = self.copy
        other.keysAndValuesDo {k, v ->
            newDict.at(k) put(v)
        }
        newDict
    }

    method -- (other:Collection⟦T⟧) {
        // answers a new dictionary like me but excluding the keys of other
        def newDict = dictionary []
        keysAndValuesDo { k, v ->
            if (! other.containsKey(k)) then {
                newDict.at(k) put(v)
            }
        }
        return newDict
    }

    method >>(target) is override {
        target << self.bindings
    }

    method <<(source) is override {
        self.addAll(source)
    }
}


