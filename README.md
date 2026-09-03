# Formal Verification of Old-Age Pension Eligibility (DL 187/2007)

[![pipeline](https://github.com/ruialmeidasantos91-cell/catala-dl187-2007/actions/workflows/ci.yml/badge.svg)](https://github.com/ruialmeidasantos91-cell/catala-dl187-2007/actions/workflows/ci.yml)
![Status](https://img.shields.io/badge/Status-Work%20in%20Progress-yellow)
![Scope](https://img.shields.io/badge/Scope-Art.%2010(1)%2C%2019%2C%2020-lightgrey)
![License](https://img.shields.io/badge/License-CC%20BY%204.0-green)

A faithful-by-construction formalization of the old-age pension eligibility
rules of the Portuguese General Social Security Regime, as defined in
**Decreto-Lei n.º 187/2007, de 10 de Maio** — specified in First-Order Logic,
implemented in Catala, and machine-verified in Lean 4.

> **Not usable for real entitlement decisions.** The formalization fixes the
> original 2007 wording and excludes the 2014 amendments, the anticipation
> regimes, and the procedural condition of Art. 10(1). See
> [`docs/INTERPRETATION.md`](docs/INTERPRETATION.md).

## The pipeline

| # | Stage | Tool | Status |
|---|---|---|---|
| 1 | Interpretation | LLM proposal + jurist adjudication | ✗ not implemented — decisions logged by hand in [`docs/INTERPRETATION.md`](docs/INTERPRETATION.md) |
| 2 | Specification | First-Order Logic | ✓ Art. 19, 20, 10(1) partial |
| 3 | Implementation | Catala | ✓ `Pensoes.catala_en` |
| 4 | Execution | OCaml / Python backends | ✗ not implemented |
| 5 | Verification | Lean 4 — adequacy proof | ✓ `lean/DL187/Eligibility.lean` |
| 5 | Testing | Hypothesis — differential | ✗ not implemented; golden vectors only |
| 6 | Decision | deferido / indeferido + reason | ~ prototype in `tools/check_vectors.py` |

Full description of every stage, including what each one may and may not
decide: **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)**.

Stage 1 is what makes this method neurosymbolic rather than merely formal: a
language model proposes a candidate reading of the statute and lists the
ambiguities it finds, and a jurist accepts, amends or rejects it. The machine
never has the last word, and the adjudication — not the model output — is the
artefact that the rest of the pipeline depends on.

## What is actually proved

The point of the Lean layer is not that six test cases pass. It is
`isEligible_iff_spec`:

```lean
theorem isEligible_iff_spec (b : Beneficiary) :
    isEligible b = true ↔ SpecEligible b
```

The executable definition and the First-Order Logic specification agree on
**every** beneficiary, not on the cases someone thought to test. Alongside it
the file proves totality, functional determinism, decidability, monotonicity,
and the sharpness of both thresholds — the structural properties the research
claims of the pension function.

The boundary cases are regression tests, downstream of the theorem.

## Current scope

| Article | Description | Status |
|---|---|---|
| Art. 19 | Guarantee period — 15 civil years | ✓ complete |
| Art. 20 | Normal age of access — 65 years (2007 wording) | ✓ complete |
| Art. 10(1) | Common eligibility conditions | ~ **partial: substantive conditions only, the procedural requirement is not modelled** |

Excluded on purpose: anticipation regimes (Art. 20 a–d), Art. 12 density
rules, survivor's pension, post-2014 amendments. Each exclusion and its
reason is recorded in [`docs/INTERPRETATION.md`](docs/INTERPRETATION.md).

## Repository structure

```
Pensoes.catala_en           Catala implementation, with the FOL header and the statute text
lean/
  lakefile.toml             Lake package
  lean-toolchain            pinned Lean version
  DL187/Eligibility.lean    FOL specification, implementation, and the adequacy proof
tests/
  vectors.json              golden cases, shared by every stage
tools/
  check_vectors.py          independent Python transcription + decision prototype
docs/
  ARCHITECTURE.md           what each pipeline stage does
  INTERPRETATION.md         every formalization decision and its alternatives
run_pipeline.sh             end-to-end check
```

## How to run

```bash
./run_pipeline.sh              # every stage with an available toolchain
./run_pipeline.sh --diagnose   # plus toolchain versions and clerk help
```

Stages whose toolchain is missing are reported as `SKIP`, not as success.

> **Where the pipeline actually runs end to end.** A development machine
> commonly has only part of the toolchain — Catala installs through `opam`,
> Lean through `elan`, and on Windows these end up on opposite sides of the
> WSL boundary. Locally you will therefore see `SKIP` for whichever half is
> missing. The GitHub Actions workflow is the reference environment: it is the
> only place where the Catala scopes and the Lean proofs are checked against
> the same golden vectors in a single run, and the badge above reflects that
> run, not a local one.

Individual steps:

```bash
python3 tools/check_vectors.py                       # Python vs. golden vectors
clerk run Pensoes.catala_en --scope=TestCase1        # a single Catala case
cd lean && lake build                                # all Lean proofs
```

### Prerequisites

- [Catala](https://catala-lang.org) with `clerk`
- [Lean 4](https://leanprover.github.io) with `lake`, via `elan`
- Python 3.10+

## Academic context

Part of the doctoral project *Verificação Formal das Pensões de Velhice e
Invalidez*, within the Rules as Code paradigm (INRIA, OECD). The Tribunal de
Contas (Portugal) is the institutional anchor for the practical utility of
this work in Social Security auditing.

If you cite this repository, please use [`CITATION.cff`](CITATION.cff).

## Legal scope

| Field | Value |
|---|---|
| Diploma | Decreto-Lei n.º 187/2007, de 10 de Maio |
| Regime | Regime Geral de Segurança Social |
| Wording | Original 2007, before the 2014 amendments |
| Coverage | Partial — work in progress |

## License and citation

Copyright © 2026 Rui Almeida Santos. Licensing is split by the nature of the
material, because Creative Commons licences are not designed for software and
do not address patents or source availability:

| Material | Licence | File |
|---|---|---|
| Source code — `.lean`, `.py`, `.sh`, `.catala_en`, build and workflow files | [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) | [`LICENSE`](LICENSE) |
| Documentation and formalization text — `README.md`, `docs/`, `CITATION.cff`, `tests/vectors.json` | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | [`LICENSE-DOCS`](LICENSE-DOCS) |

Both licences require attribution. Apache-2.0 additionally requires that
modified files carry a notice of the change, so a derivative cannot be
presented as this work unaltered. See [`NOTICE`](NOTICE).

**If you use this work, cite it.** Metadata is in
[`CITATION.cff`](CITATION.cff). Released versions are archived with a DOI, and
the DOI — not this repository URL — is the stable reference.

### On the statutory text

Decreto-Lei n.º 187/2007 is Portuguese legislation and is not covered by the
licences above. The English renderings of the statutory text in this
repository are unofficial working translations by the author, made to keep the
formalization readable to an international audience. They have no legal value;
the Portuguese original governs.
