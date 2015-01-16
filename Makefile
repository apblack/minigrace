include Makefile.conf

.PHONY: all c clean fullclean install js minigrace-environment selfhost-stats selftest samples sample-% test test.js uninstall
ARCH:=$(shell uname -s)-$(shell uname -m)
C_MODULES = $(UNICODE_MODULE) $(OTHER_MODULES)
DYNAMIC_STUBS = mirrors.grace
EXTERNAL_STUBS = unicode.grace repl.grace math.grace
GRACE_DIALECTS = sample/dialects/requireTypes.grace sample/dialects/staticTypes.grace sample/dialects/dialect.grace rtobjectdraw.grace objectdraw.grace ast.grace util.grace buildinfo.grace
GRACE_MODULES = gUnit.grace collections.grace StandardPrelude.grace collectionsPrelude.grace ast.grace mgcollections.grace
INTERNAL_STUBS = sys.grace io.grace
JSSOURCEFILES = js/compiler.js js/errormessages.js js/ast.js js/lexer.js js/parser.js js/genjs.js js/genc.js js/mgcollections.js js/xmodule.js js/identifierresolution.js js/buildinfo.js js/genjson.js js/collections.js js/collectionsPrelude.js js/gUnit.js 
KG=known-good/$(ARCH)/$(STABLE)
VERBOSITY = --verbose

ifeq ($(MINIGRACE_BUILD_SUBPROCESSES),)
    MINIGRACE_BUILD_SUBPROCESSES = 9
endif

REALSOURCEFILES = collectionsPrelude.grace StandardPrelude.grace compiler.grace errormessages.grace util.grace ast.grace lexer.grace parser.grace genjs.grace genc.grace mgcollections.grace collections.grace interactive.grace xmodule.grace identifierresolution.grace genjson.grace gUnit.grace
SOURCEFILES = $(REALSOURCEFILES) buildinfo.grace
STABLE=61482bce15cec41844a512fd6f07853796a59bdb
WEBFILES = js/index.html js/global.css js/tests js/minigrace.js js/samples.js  js/tabs.js js/gracelib.js js/dom.js js/gtk.js js/debugger.js js/timer.js js/ace  js/sample js/debugger.html  js/*.png js/unicodedata.js $(GRACE_MODULES:%.grace=js/%.js) $(JSSOURCEFILES)

all: minigrace-environment $(C_MODULES) $(GRACE_MODULES:.grace=.gct) $(GRACE_MODULES:.grace=.gcn) sample-dialects $(GRACE_DIALECTS)

# The rules that follow are in alphabetical order.  Keep them that way!

ace-code: js/ace/ace.js

alltests: test test.js

backendtests: test

blackWeb: js samples ace-code
	rsync -a -l -z --delete $(WEBFILES) black@cs.pdx.edu:public_html/minigrace/js
	rsync -a -l -z --delete sample black@cs.pdx.edu:public_html/minigrace

bruceWeb: js samples ace-code
	rsync -a -l -z --delete $(WEBFILES) kim@project.cs.pomona.edu:www/minigrace/js
	rsync -a -l -z --delete sample kim@project.cs.pomona.edu:www/minigrace

buildinfo.grace:
	@echo "Checking buildinfo."
	@echo "method gitrevision { \"$(shell [ -e .git ] && git rev-parse HEAD || echo unknown )\" }" > buildinfo_tmp.grace
	@echo "method gitgeneration { \"$(shell [ -e .git ] && tools/git-calculate-generation || echo unknown )\" }" >> buildinfo_tmp.grace
	@echo "method prefix { \"$(PREFIX)\" }" >> buildinfo_tmp.grace
	@echo "method includepath { \"$(INCLUDE_PATH)\" }" >> buildinfo_tmp.grace
	@echo "method modulepath { \"$(MODULE_PATH)\" }" >> buildinfo_tmp.grace
	@echo "method objectpath { \"$(OBJECT_PATH)\" }" >> buildinfo_tmp.grace
	@if ! cmp -s buildinfo_tmp.grace buildinfo.grace ; then mv buildinfo_tmp.grace buildinfo.grace ; else rm buildinfo_tmp.grace ; fi

c: minigrace gracelib.c gracelib.h unicode.c unicodedata.h Makefile c/Makefile mirrors.c definitions.h curl.c repl.c math.c
	for f in gracelib.c gracelib.h unicode.c unicodedata.h $(SOURCEFILES) collectionsPrelude.grace StandardPrelude.grace $(UNICODE_MODULE) mirrors.c math.c definitions.h debugger.c curl.c repl.c ; do cp $$f c ; done && cd c && ../minigrace --make $(VERBOSITY) --noexec -XNoMain -XNativePrelude collectionsPrelude.grace && ../minigrace --make $(VERBOSITY) --noexec -XNoMain -XNativePrelude StandardPrelude.grace && ../minigrace --target c --make $(VERBOSITY) --module minigrace --noexec compiler.grace && rm -f *.gcn $(UNICODE_MODULE)

clean:
	rm -f gracelib.bc gracelib.o gracelib-basic.o
	rm -fr unicode.gco unicode.gso unicode.gcn unicode.gso.dSYM
	rm -f mirrors.gso math.gso
	rm -f debugger.o
	rm -fr *.gso *.gso.dSYM
	rm -f StandardPrelude.{c,gcn,gct} js/StandardPrelude.js collectionsPrelude.{c,gcn,gct} js/collectionsPrelude.js
	rm -rf l1 l2 buildinfo.grace
	rm -f $(SOURCEFILES:.grace=.c) minigrace.c
	rm -f $(SOURCEFILES:.grace=.gco)
	rm -f $(SOURCEFILES:.grace=.gcn) minigrace.gcn
	rm -f $(SOURCEFILES:.grace=.gso) minigrace.gso
	rm -f $(SOURCEFILES:.grace=.gct) minigrace.gct
	rm -f $(STUBS:.grace=.gct)
	rm -f stdin_minigrace.c
	rm -f minigrace-dynamic
	rm -f $(SOURCEFILES:.grace=)
	rm -f objectdraw.* rtobjectdraw.*
	( cd known-good && make clean )
	( cd js ; for sf in $(SOURCEFILES:.grace=.js) ; do rm -f $$sf ; done )
	( cd js ; for sf in $(SOURCEFILES) ; do rm -f $$sf ; done )
	rm -f js/minigrace.js
	( cd c ; rm -f *.gcn *.gct *.c *.h *.grace minigrace unicode.gso gracelib.o )
	rm -f minigrace.gco minigrace
	( cd sample/dialects && make clean )
	( cd js/sample/graphics && make clean )
	( cd js/sample/graphics && make clean )

collectionsPrelude.gcn collectionsPrelude.gct: collectionsPrelude.grace
	./minigrace $(VERBOSITY) --make --noexec -XNoMain $<

curl.gso: curl.c gracelib.h
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -o curl.gso -shared -fPIC curl.c -lcurl

echo:
	@echo MINIGRACE_BUILD_SUBPROCESSES = $(MINIGRACE_BUILD_SUBPROCESSES)
	@echo MAKEFLAGS = $(MAKEFLAGS)
	@echo WEBFILES = $(WEBFILES)
	@echo KG = $(KG):

fullclean: clean
	rm -f Makefile.conf
	rm -rf $$(ls -d known-good/*/* | grep -v $(STABLE))

fulltest: gencheck clean selftest test

gencheck:
	( X=$$(tools/git-calculate-generation) ; mv .git-generation-cache .git-generation-cache.$$$$ ; Y=$$(tools/git-calculate-generation) ; [ "$$X" = "$$Y" ] || exit 1 ; rm -rf .git-generation-cache ; mv .git-generation-cache.$$$$ .git-generation-cache )

graceWeb: js samples ace-code
	rsync -a -l -z --delete $(WEBFILES) grace@cs.pdx.edu:public_html/minigrace/js
	rsync -a -l -z --delete sample grace@cs.pdx.edu:public_html/minigrace

gracelib-basic.o: gracelib.c gracelib.h
	gcc -g -std=c99 -o gracelib-basic.o -c gracelib.c

gracelib.o: gracelib-basic.o debugger.o l2/minigrace StandardPrelude.gcn collectionsPrelude.gcn
	ld -o gracelib.o -r gracelib-basic.o StandardPrelude.gcn collectionsPrelude.gcn debugger.o

%.gso: %.grace minigrace
	./minigrace $(VERBOSITY) --dynamic-module $<

install: minigrace $(GRACE_MODULES:%.grace=js/%.js) $(GRACE_DIALECTS:%.grace=%.gso) $(GRACE_DIALECTS:%.grace=js/%.js)
	install -d $(PREFIX)/bin $(MODULE_PATH) $(OBJECT_PATH) $(INCLUDE_PATH)
	install -m 755 minigrace $(PREFIX)/bin/minigrace
	install -m 755 $(C_MODULES) $(MODULE_PATH)
	install -m 755 gracelib.o $(OBJECT_PATH)
	install -m 644 gracelib.h $(INCLUDE_PATH)
	install -m 644 mgcollections.grace $(MODULE_PATH)
	install -m 644 $(GRACE_MODULES) $(GRACE_MODULES:%.grace=js/%.js) $(GRACE_MODULES:%.grace=%.gct) $(MODULE_PATH)
	install -m 644 $(GRACE_DIALECTS) $(GRACE_DIALECTS:%.grace=js/%.js) $(GRACE_DIALECTS:%.grace=%.gct) $(GRACE_DIALECTS:%.grace=%.gso) $(GRACE_DIALECTS:%.grace=%.gcn) $(MODULE_PATH)

js/%.js: %.grace minigrace
	cd js; ../minigrace $(VERBOSITY) --target js -o $(@F) ../$<

js/ace/ace.js:
	curl https://raw.githubusercontent.com/ajaxorg/ace-builds/master/src-min/ace.js > js/ace/ace.js

js/dom.gct: stubs/dom.grace
	(cd stubs; rm -f $(@:%.gct=%{.c,.gcn,});  ../minigrace $(VERBOSITY) --make --noexec $(<:stubs/%.grace=%.grace); mv $(<:stubs/%.grace=%.gct) ../js/; rm -f $(@:%.gct=%{.c,.gcn,});)

js/index.html: js/index.in.html js/ace js/minigrace.js js/tests
	@echo Generating index.html from index.in.html...
	@awk '!/<!--\[!SH\[/ { print } /<!--\[!SH\[/ { gsub(/<!--\[!SH\[/, "") ; gsub(/\]!\]-->/, "") ; system($$0) }' < $< > $@

js/minigrace.js: js/minigrace.in.js
	@echo Generating minigrace.js from minigrace.in.js...
	@cat js/minigrace.in.js > js/minigrace.js
	@echo "MiniGrace.version = '$$(tools/calculate-version HEAD)';" >> js/minigrace.js
	@echo "MiniGrace.revision = '$$(git rev-parse HEAD|cut -b1-7)';" >> js/minigrace.js

js/sample-dialects js/sample-graphics: js/sample-%: js
	$(MAKE) -C js/sample/$* VERBOSITY=$(VERBOSITY)

js/sample/dialects/requireTypes.js js/sample/dialects/requireTypes.gct: js/sample/dialects/requireTypes.grace
	$(MAKE) -C js/sample/dialects VERBOSITY=$(VERBOSITY) $(@F)

js/sample/dialects/staticTypes.js js/sample/dialects/staticTypes.gct: js/sample/dialects/staticTypes.grace
	$(MAKE) -C js/sample/dialects VERBOSITY=$(VERBOSITY) $(@F)

js: minigrace js/index.html js/dom.gct $(GRACE_MODULES:%.grace=js/%.js) $(WEBFILES)
	ln -f minigrace js/minigrace

just-minigrace:
	./l2/minigrace --vtag l2 -j $(MINIGRACE_BUILD_SUBPROCESSES) --make --native --module minigrace $(VERBOSITY) compiler.grace

known-good/%:
	@echo "making $@"
	cd known-good && $(MAKE) $*
	rm -f known-good/*out

$(KG)/collectionsPrelude.gct: $(KG)/collectionsPrelude.grace
	cd $(KG) ; ./minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg collectionsPrelude.grace

$(KG)/StandardPrelude.gct: $(KG)/StandardPrelude.grace $(KG)/collectionsPrelude.gct
	cd $(KG) ; ./minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg StandardPrelude.grace

$(KG)/StandardPrelude.grace: StandardPrelude.grace
	ln -sf $(realpath $<) $@

$(KG)/collectionsPrelude.grace: collectionsPrelude.grace
	ln -sf $(realpath $<) $@

l1/%.gct: l1/%.grace $(KG)/StandardPrelude.gct
	(cd l1; ./minigrace $(VERBOSITY) --vtag l1 --make --noexec -XNoMain $(<F))

l1/%.grace: l1/exists

l1/collectionsPrelude.gct: l1/collectionsPrelude.grace $(KG)/minigrace
	cd l1 ; ../$(KG)/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg collectionsPrelude.grace

l1/exists: $(C_MODULES)
	mkdir -p l1
	(cd l1 ; for f in $(SOURCEFILES) $(C_MODULES) gracelib.h gracelib-basic.o ; do ln -sf ../$$f . ; done ; )
	touch l1/exists

l1/gracelib.o: gracelib-basic.o debugger.o $(KG)/minigrace StandardPrelude.grace collectionsPrelude.grace
	cd l1; ../$(KG)/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg collectionsPrelude.grace
	cd l1; ../$(KG)/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg StandardPrelude.grace
	ld -o l1/gracelib.o -r gracelib-basic.o l1/StandardPrelude.gcn l1/collectionsPrelude.gcn debugger.o

l1/math.gcn: math.c
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -o $@ -fPIC $<

l1/minigrace: l1/exists $(KG)/minigrace $(STUBS:%.grace=l1/%.gct) $(KG)/collectionsPrelude.gct $(KG)/StandardPrelude.gct $(SOURCEFILES) gracelib.c gracelib.h l1/gracelib.o
	@echo "dependencies are $^"
	(cd l1; ../$(KG)/minigrace $(VERBOSITY) --make --native --module minigrace --gracelib ./ --vtag kg -j $(MINIGRACE_BUILD_SUBPROCESSES) compiler.grace)

l1/mirrors.gso: mirrors.c
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -shared -o $@ -fPIC $<

l1/repl.gcn: repl.c
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -o $@ -fPIC $<

l1/StandardPrelude.gct: l1/StandardPrelude.grace $(KG)/minigrace
	cd l1 ; ../$(KG)/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg StandardPrelude.grace

l1/unicode.gcn: unicode.c unicodedata.h gracelib.h
	gcc -g -std=c99 -c -o $@ -fPIC $<

l2/%.gct: l2/%.grace
	(cd l2; ./minigrace $(VERBOSITY) --vtag l2 --make --noexec -XNoMain $(<F))

l2/collectionsPrelude.gct: l2/collectionsPrelude.grace l1/minigrace
	cd l2 ; ../l1/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg collectionsPrelude.grace

l2/exists: $(C_MODULES)
	mkdir -p l2
	(cd l2 ; for f in $(SOURCEFILES) $(C_MODULES) gracelib.h gracelib-basic.o collectionsPrelude.gct StandardPrelude.gct ; do ln -sf ../$$f . ; done ;)
	touch l2/exists

l2/gracelib.o: gracelib-basic.o debugger.o l1/minigrace StandardPrelude.grace collectionsPrelude.grace
	cd l2; ../l1/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag l1 collectionsPrelude.grace
	cd l2; ../l1/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag l1 StandardPrelude.grace
	ld -o l2/gracelib.o -r gracelib-basic.o l2/StandardPrelude.gcn l2/collectionsPrelude.gcn debugger.o

l2/minigrace: l2/exists l1/minigrace $(STUBS:%.grace=l1/%.gct) $(SOURCEFILES) $(C_MODULES:%=l1/%) l1/gracelib.o
	(cd l2; ../l1/minigrace $(VERBOSITY) --make --native --module minigrace --vtag l1 -j $(MINIGRACE_BUILD_SUBPROCESSES) compiler.grace)

l2/StandardPrelude.gct: l2/StandardPrelude.grace l1/minigrace
	cd l2 ; ../l1/minigrace $(VERBOSITY) --make --noexec -XNoMain --vtag kg StandardPrelude.grace

Makefile.conf: configure
	./configure

math.gso: math.c gracelib.h
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -o math.gso -shared -fPIC math.c

# Giant hack! Not suitable for use.
minigrace-dynamic: l2/minigrace $(SOURCEFILES)
	l1/minigrace $(VERBOSITY) --make --noexec --import-dynamic -XNoMain -XNativePrelude --vtag l1 StandardPrelude.grace
	ld -o gracelib.o -r gracelib-basic.o StandardPrelude.gcn debugger.o
	l2/minigrace $(VERBOSITY) --make --import-dynamic $(VERBOSITY) --module minigrace-dynamic --vtag l2 compiler.grace

minigrace: l2/minigrace $(STUBS:%.grace=%.gct) $(SOURCEFILES) $(C_MODULES) l2/gracelib.o
	./l2/minigrace --vtag l2 -j $(MINIGRACE_BUILD_SUBPROCESSES) --make --native --module minigrace $(VERBOSITY) compiler.grace

minigrace-environment: minigrace StandardPrelude.gct gracelib.o gUnit.gct .git/hooks/commit-msg

mirrors.gso: mirrors.c gracelib.h
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -o mirrors.gso -shared -fPIC mirrors.c

objectdraw.grace:
	curl https://raw.githubusercontent.com/gracelang/objectdraw/master/objectdraw.grace > objectdraw.grace

objectdraw.gcn objectdraw.gso:
	@echo "Can't build $@; no C version of dom module"

repl.gso: repl.c gracelib.h
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -o repl.gso -shared -fPIC repl.c

repltest: minigrace
	./tests/harness "../minigrace" tests repl

rtobjectdraw.grace: objectdraw.grace tools/make-rt-version
	./tools/make-rt-version objectdraw.grace > rtobjectdraw.grace

rtobjectdraw.gcn rtobjectdraw.gso:
	@echo "Can't build $@; no C version of dom module"

sample-dialects: minigrace
	$(MAKE) -C sample/dialects VERBOSITY=$(VERBOSITY)

sample/dialects/%.gso: sample/dialects/%.grace
	$(MAKE) -C sample/dialects  VERBOSITY=$(VERBOSITY) $(@F)

sample/dialects/requireTypes.gct sample/dialects/requireTypes.gso: sample/dialects/requireTypes.grace
	$(MAKE) -C sample/dialects  VERBOSITY=$(VERBOSITY) $(@F)

sample/dialects/staticTypes.gct sample/dialects/staticTypes.gso: sample/dialects/staticTypes.grace
	$(MAKE) -C sample/dialects  VERBOSITY=$(VERBOSITY) $(@F)

samples: sample-dialects js/sample-dialects js/sample-graphics

selfhost-stats: minigrace
	cat compiler.grace util.grace ast.grace parser.grace genc.grace > tmp.grace
	GRACE_STATS=1 ./minigrace -XIgnoreShadowing < tmp.grace >/dev/null
	rm -f tmp.grace

selftest: minigrace
	rm -rf selftest
	mkdir -p selftest
	for f in $(SOURCEFILES) unicode.gso gracelib.o gracelib.h ; do ln -sf ../$$f selftest ; done
	( cd selftest ; ../minigrace $(VERBOSITY) --make --native --module minigrace --vtag selftest -j $(MINIGRACE_BUILD_SUBPROCESSES) compiler.grace )
	rm -rf selftest

StandardPrelude.gcn StandardPrelude.gct: StandardPrelude.grace collectionsPrelude.gct
	./minigrace $(VERBOSITY) --make --noexec -XNoMain $<

# The next three rules are Static Pattern Rules.  Each is like an implicit rule 
# for making %.gct from stubs/%.grace, but applies only to the targets in $(STUBS:*)

$(STUBS:%.grace=%.gct): %.gct: stubs/%.grace l2/minigrace l2/StandardPrelude.gct
	cd stubs; rm -f $(@:%.gct=%{.c,.gcn,}); ../l2/minigrace $(VERBOSITY) --make --noexec $(<F) && mv $@ ../ && rm -f $(@:%.gct=%{.c,.gcn});

$(STUBS:%.grace=l1/%.gct): l1/%.gct: stubs/%.grace l1/exists $(KG)/minigrace $(KG)/StandardPrelude.gct
	cd stubs; rm -f $(@F:%.gct=%{.c,.gcn,}); ../$(KG)/minigrace $(VERBOSITY) --make --noexec $(<F) && mv $(@F) ../l1 && rm -f $(@F:%.gct=%{.c,.gcn})

$(STUBS:%.grace=l2/%.gct): l2/%.gct: stubs/%.grace l2/exists l1/minigrace l1/StandardPrelude.gct
	cd stubs; rm -f $(@F:%.gct=%{.c,.gcn,}); ../l1/minigrace $(VERBOSITY) --make --noexec $(<F) && mv $(@F) ../l2 && rm -f $(@F:%.gct=%{.c,.gcn})

tarWeb: js samples
	tar -cvf webfiles.tar $(WEBFILES) tests sample
#	Untar in your public_html directory with "tar -xpf ~/webfiles.tar". Make the
#	subdirectory that tar creates readable and executable by your web daemon.

tarball: minigrace
	touch c/Makefile.conf
	make -C c fullclean
	make c
	sed -e 's/DISTRIB=tree/DISTRIB=tarball/' < configure > c/configure
	chmod 755 c/configure
	VER=$$(tools/calculate-version) ; mkdir minigrace-$$VER ; cp -R c/* minigrace-$$VER ; mkdir minigrace-$$VER/tests ; cp tests/*.grace tests/*.out tests/harness minigrace-$$VER/tests ; mkdir -p minigrace-$$VER/sample/dialects ; cp sample/dialects/*.grace sample/dialects/README sample/dialects/Makefile minigrace-$$VER/sample/dialects ; cp -R README doc minigrace-$$VER ; tar cjvf ../minigrace-$$VER.tar.bz2 minigrace-$$VER ; rm -rf minigrace-$$VER

test.js.compile:
	@echo "compiling tests to JavaScript"
	@cd js/tests; ls *_test.grace | grep -v "fail" | sed 's/^t\([0-9]*\)_.*/& \1/' | while read -r fileName num; do echo "$$num \c"; ../../minigrace --target js $${fileName}; done && echo "tests compiled."

test.js: js js/collections.js js/gUnit.js js/sample/dialects/requireTypes.js js/sample/dialects/ mgcollections.gso buildinfo.gso requireTypes.gct js/sample/dialects/requireTypes.gso js/sample/dialects/staticTypes.js js/sample/dialects/staticTypes.gct js/sample/dialects/staticTypes.gso
	npm install performance-now
	js/tests/harness ../../minigrace js/tests ""

test: minigrace-environment
	./tests/harness "../minigrace" tests ""

togracetest: minigrace
	./tests/harness "../minigrace" tests tograce

unicode.gcn: unicode.c unicodedata.h gracelib.h
	gcc -g -std=c99 -fPIC -c -o unicode.gcn unicode.c

unicode.gso: unicode.c unicodedata.h gracelib.h
	gcc -g -std=c99 $(UNICODE_LDFLAGS) -fPIC -shared -o unicode.gso unicode.c

uninstall:
	rm -f $(PREFIX)/bin/minigrace
	rm -f $(MODULE_PATH)/*.gso
	rm -f $(OBJECT_PATH)/gracelib.o
	rm -f $(INCLUDE_PATH)/gracelib.h
	rm -f $(MODULE_PATH)/*.{gct,js,grace,gcn,gso}

%.gcn %.gct: %.grace StandardPrelude.gct
	./minigrace $(VERBOSITY) --make --noexec $<

.git/hooks/commit-msg: tools/validate-commit-message
	@ln -s ../../tools/validate-commit-message .git/hooks/commit-msg

%.o: %.c
	gcc -g -std=c99 -c -o $@ $<
