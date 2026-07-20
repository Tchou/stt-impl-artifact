# Artifact Implementing Set-Theoretic Types

## Presentation

This repository contains the companion artifact for the paper "Implementing
Set-Theoretic Types".

The paper reports on the SSTT (Simple Set-Theoretic Types) library, in
particular the data-structures used to represent set-theoretic types. Such types are (informally) given by the grammar:

$ t ::= b | t\times t | t \rightarrow t | t \wedge t | t \vee t | \lnot t | 𝟘 | 𝟙 | \alpha $
where
- $b$ stands for basic types
- $\vee$, $\wedge$, $\lnot$ stand for union, intersection and negation of types
-  𝟘 for the empty type
-  𝟙 for the top type
- $\alpha$ is a type variable

The paper proposes a data-structure, dubbed `BDT` (for Binary Decision Tree) to represent such types. It also presents :

- a semantic simplification (SS) aimed at reducing the size of BDTs
- the complete pseudo-code of an optimized subtyping algorithm (deciding, given two polymorphic type $t$ and $s$ whether $\forall \sigma, t\sigma \leq s\sigma$) (which uses a cache to avoid recomputations, and whose handling is complex in the presence of recursive types)
- the complete pseudo-code of an optimized tallying algorithm (unification
  based subtyping constraints), which, given two types $t$ and $s$, finds the principal set of substitutions such $\{ \sigma_1, \ldots, \sigma_n \}$ such that $t\sigma_i \leq s\sigma_i$

The present artifact allows one to reproduce the experimental results in the paper. The experiment runs in two phases:

### Phase 1
The tests uses the [MLsem](github.com/E-Sh4rk/MLsem/) type checker to typecheck
three corpuses of programs. During typechecking, the tallying (unification)
problems are extracted and serialized to json files. As the goal of the paper is
*not* to benchmark a particular type checker implementation but only the type
data structure and basic function of subtyping and tallying, no benchmarking is
done during this first phase.

### Phase 2
The tallying problems from Phase 1 are read and solved by a benchmarking program which uses the SSTT library. The following 8 configurations are tested :
 - BDT : a plain BDT data-structure is used, without any optimization for size
 - SS : a BDT + semantic simplification data-structure is used
 - BDT + HC : a BDT + hashconsing of nodes
 - SS + HC : a BDT + semantic simplification + hashconsing of nodes
 - BDT + Naive Sub : a plain BDT implementation and a naive version of the subtyping algorithm (without caching)
 - SS + Naive Sub : an SS implementation and a naive version of
 the subtyping algorithm (without caching)
 - SS + Naive Tallying : an SS implementation and a naive version of the tallying, without constraint propagation nor simplification
 - CDuce : an implementation where the types/subtyping/talling procedure are replaced by those of the [CDuce compiler](https://gitlab.math.univ-paris-diderot.fr/cduce/cduce), the only known full implementation of set-theoretic types.


The paper also makes the claim that a preliminary (and more naive) version of
the semantic simplification is present in the artifact of [Polymorphic Type
Inference for Dynamic Languages, POPL24](https://zenodo.org/records/11203457)
and that such simplifications (like the SS strategy) are necessary in practice
or the type quickly grow too large to be useful.

## Artifact description

The artifact consists of a checkout of the SSTT library at the time of submission (it has since received more optimizations that are not part of the paper). It contains a script which
runs the SSTT constraint solving for the 8 configurations described above, for each of the 3 JSON files. The scripts then prints the (as well as stores in a file) the LaTeX code for the table used in the paper (Table 1). The artifacts also contains the web prototype of the SSTT library which provides a small REPL where one can tests subtyping or tallying problems.

## Instructions

### Using docker
The provided `Dockerfile`, based on an Ubuntu 25.04 image does the following:
- installs the dependencies from the Ubuntu repository
- installs the `opam` package manager for OCaml
- initializes a an opam switch (a specific version of the OCaml compiler and all the relevant libraries)
- checks out MLsem at the time of submission
- checks out sstt at the time of submission (an instrumented version)
- checks out the CDuce compiler
- builds everything

The image can be built with `docker build -t sstt .`. The command `docker run -p 8000:8000 sstt` launches the online REPL, which can be accessed pointing one's web browser toward [http://localhost:8000](http://localhost:8000).

By doing `docker run -ti sstt bash`, one has access to the `Makefile` script described in the following section and can run:
    - `make phase2` to run the tests and show the table
    - `make claim_popl24` to verify the claim about simplifications being necessary

### Using the Makefile

To run the tests outside of `docker` the following pre-requisites should be satisfied:
- the `opam` package manager should be installed and configured (a local switch is built by the script)
- the external dependencies should be installed on the system. On Ubuntu/Debian, those are:
```
git make unzip bubblewrap bzip2 binaryen cmake g++ libcurl4-gnutls-dev libexpat1-dev libgmp-dev libssl-dev ninja-build pkg-config curl npm ca-certificates
```

Note: `binaryen`, `ninja-build` and `npm` are only needed to build the Web console.

The following rules should be used:

- `make phase2`: benchmarks the 8 configurations of the SSTT library. The configuration is set at compile time, the 8 configuration files are stored in the directory `sstt/benchmarks/conifg`. The three
tested `json` files are in `sstt/benchmarks`.
These files are built from the MLsem checkout if not present.

- `make claim_popl24`: uses the artifact of [POPL24] to typechecks a simple function (concat and flatten on lists) which succeeds in a few hundred milliseconds. Type simplifications is then disabled (by replacing the function by the identity in the code) and the experiment is run again. A timeout is set to kill the program after 10s.

The following auxiliary rules are called to build the necessary dependencies for the two rules above:
- `_opam/.opam-switch/switch-config` creates the local `opam` for version 5.4.1 of the OCaml compiler.
- `.deps-installed` install the OCaml dependencies
- `.cduce/.stamp` clones the CDuce compiler from its public repository
- `.cduce-installed` installs CDuce in the current opam switch
- `Prototype-v1.2.3/.stamp` fetches the artifact for [POPL24] from its Zenodo URL
- `sstt/.stamp` fetches `sstt` from its public repository
- `MLsem/.stamp` fetches `MLsem` from its public repository, and checks out a commit from the time of submission (it's API as changed since)
- `sstt/benchmarks/%.json` builds the problem JSON files from tests in the MLsem repository

The submitted tarball already contains a checkout of `cduce`, `MLsem` and `sstt`, but requires the creation of a local opam switch.

We recommend using the two main targets of the makefile to run the tests and
automatically setup the environment, although it should be fairly easy to run
the commands manually.

