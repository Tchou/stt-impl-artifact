ML_DEPS=conf-libssl dune js_of_ocaml-compiler js_of_ocaml-ppx markup menhir menhirLib \
		ocaml-compiler-libs ocaml-expat \
		ocamlfind ocurl odoc sedlex zarith zarith_stubs_js pomap ppx_deriving tsort \
		ppx_expect mdx wasm_of_ocaml-compiler binaryen-bin \

.PHONY: phase1 phase2 claim_popl24

_opam:
	@echo "Creating local opam switch"
	opam switch create ./ 5.4.1

.deps-installed: _opam
	@echo "Installing dependencies"
	opam install -y $(ML_DEPS)
	touch $@


.cduce-installed: .deps-installed
	@echo "Installing CDuce"
	test -d cduce || git clone https://gitlab.math.univ-paris-diderot.fr/cduce/cduce.git
	cd cduce && \
	opam pin -y -n . && \
	opam install cduce-types cduce
	touch $@

.popl-24-installed: .cduce-installed
	@echo "Retrieving et al [POPL24] prototype"
	curl -L -O -J "https://zenodo.org/records/11203457/files/E-Sh4rk/Prototype-v1.2.3.zip?download=1"
	mkdir -p Prototype-v1.2.3
	unzip -q Prototype-v1.2.3.zip -d Prototype-v1.2.3
	mv Prototype-v1.2.3/*/* Prototype-v1.2.3
	touch $@

sstt:
	@echo "Retrieving Instrumented SSTT"
	git clone https://github.com/E-Sh4rk/sstt && \
	cd sstt && \
	git checkout -b instrumented origin/instrumented

MLsem:
	@echo "Retrieving MLsem"
	git clone https://github.com/E-Sh4rk/MLsem && \
	cd MLsem && \
	git checkout -b artefact-evaluation f73ed9772dc442d3f472fc495145a916563112a5 && \
	ln -s ../sstt

sstt/benchmarks/%.json: MLsem/tests/%.ml MLsem
	@echo "Running phase 1: recording tyling instances of $<"
	cd MLsem && \
	opam exec -- dune exec -- src/bin/native.exe -record $(patsubst MLsem/%,%,$<) && \
	cp $(patsubst sstt/benchmarks/%,tests/%,$@) sstt/benchmarks

JSON=sstt/benchmarks/0_hm.json sstt/benchmarks/1_union_inter.json sstt/benchmarks/2_dyn.json

phase2: $(JSON) sstt
	@echo "Running phase 2: testing SSTT in 8 configurations"
	cd sstt && \
	benchmarks/run.sh

claim_popl24: .popl-24-installed
	@echo "Running vanilla POPL24 to typecheck concat/flatten (should typecheck quickly)"
	@echo "-----------------------------------------------------------------------------"
	@echo

	cd Prototype-v1.2.3/src && \
	dune exec -- main/prototype.exe ../../claim_01/popl24_test_flatten.ml
	@echo
	@echo
	@echo "Disabling type simplification in POPL24 to typecheck concat/flatten (should not terminate, killed automatically after 10s)"
	@echo "--------------------------------------------------------------------------------------------------------------------------"
	@echo

	cd Prototype-v1.2.3/src && \
	diff -w -U 1  --color=always types/additions.ml ../../claim_01/additions.ml || true && \
	cp types/additions.ml types/additions.bak && \
	cp ../../claim_01/additions.ml types/ && \
	timeout --foreground 10 dune exec -- main/prototype.exe ../../claim_01/popl24_test_flatten.ml || true && \
	mv types/additions.bak types/additions.ml
	@echo

