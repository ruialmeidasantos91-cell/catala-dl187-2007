# Architecture

This document describes the full verification pipeline. It is the reference
for what each stage is responsible for, what it may and may not decide, and
what artefact it hands to the next stage.

The repository currently implements stages 2, 3 and 5 for a minimal scope
(Art. 19, Art. 20, Art. 10(1) of DL 187/2007). Stages 1, 4 and 6 are
specified here and marked as not yet implemented, so that the gap between
the intended method and the current code is visible rather than hidden.

## Overview

```
  ┌─────────────────────────────────────────────────────────────┐
  │ Legal source: Decreto-Lei n.º 187/2007, original wording     │
  └────────────────────────────┬────────────────────────────────┘
                               │
  (1) INTERPRETATION           ▼        neurosymbolic proposal
      ─────────────────  ┌──────────────────────┐   +
      LLM proposes a     │  human adjudication  │   human decision
      candidate FOL      │  (jurist in the loop)│   (authoritative)
      reading; the       └──────────┬───────────┘
      jurist accepts,               │  decision recorded in
      amends or rejects.            │  docs/INTERPRETATION.md
                                    ▼
  (2) SPECIFICATION      ┌──────────────────────┐
      ─────────────────  │  First-Order Logic   │  human-authored,
      Predicates over a  │  over finite structs │  machine-readable
      finite domain of   └──────────┬───────────┘
      beneficiaries.                │
                                    ▼
  (3) IMPLEMENTATION     ┌──────────────────────┐
      ─────────────────  │       Catala         │  literate: statute
      Executable legal   │  (.catala_en)        │  text and code in
      logic, default     └──────────┬───────────┘  the same file
      logic semantics.              │
                        ┌───────────┴───────────┐
                        ▼                       ▼
  (4) EXECUTION   ┌──────────┐            ┌──────────┐
      ──────────  │  OCaml   │            │  Python  │  (5) TESTING
      Catala      │ (compiled│            │ (compiled│  ──────────
      backends.   │  target) │            │  target) │  Hypothesis
                  └────┬─────┘            └────┬─────┘  property tests
                       └──────────┬────────────┘        + golden vectors
                                  │
  (5) VERIFICATION                ▼
      ─────────────────  ┌──────────────────────┐
      Independent        │       Lean 4         │  adequacy theorem:
      re-implementation  │  (proof of adequacy) │  code ⟺ FOL spec
      + machine proof.   └──────────┬───────────┘
                                    │
  (6) DECISION                      ▼
      ─────────────────  ┌──────────────────────┐
      Reasoned outcome   │  DEFERIDO / INDEFERIDO│  + the article that
      for one case.      │  + justification      │  decided the case
                         └──────────────────────┘
```

## Stage 1 — Interpretation (neurosymbolic + human)

**Status: not implemented in this repository.**

Legal text is not self-formalizing. Turning "15 civil years, consecutive or
interpolated" into `years ≥ 15` is an interpretive act with alternatives, and
the pipeline is only honest if that act is recorded.

The intended method is *proposal by machine, adjudication by human*:

1. A language model receives the article text and proposes a candidate FOL
   reading, together with the ambiguities it detected.
2. A jurist accepts, amends or rejects the proposal.
3. The decision, the rejected alternatives, and the reason are written to
   `docs/INTERPRETATION.md`.

The machine never has the last word. The record in `docs/INTERPRETATION.md`
is the authoritative artefact of this stage; the model output is evidence,
not authority. This is what makes the formalization auditable: a reader who
disagrees with `years ≥ 15` can find where the choice was made and on what
grounds.

## Stage 2 — Specification (First-Order Logic)

Human-authored FOL over a finite domain, currently carried in the header of
`Pensoes.catala_en` and mirrored in `lean/DL187/Eligibility.lean`.

```
Domain: B — set of beneficiaries
age(b) ∈ ℕ, years(b) ∈ ℕ, for b ∈ B

GP(b) ↔ years(b) ≥ 15        [Art. 19]
NA(b) ↔ age(b) ≥ 65          [Art. 20, original 2007 wording]
E(b)  ↔ GP(b) ∧ NA(b)        [Art. 10(1), partial]
```

The FOL text is duplicated in two places on purpose: it is the contract that
stage 3 and stage 5 must independently satisfy. The duplication is checked by
the adequacy theorem in stage 5, not by hand.

## Stage 3 — Implementation (Catala)

`Pensoes.catala_en` interleaves the statutory text with executable scopes.
Catala's default-logic semantics is the reason for choosing it: exceptions in
law ("without prejudice to...", "except when...") map onto Catala's exception
mechanism directly, which a general-purpose language cannot express without
manual ordering of conditions.

The current scope uses no exceptions yet, because the anticipation regimes of
Art. 20(a)–(d) are out of scope. This is the first place the exception
mechanism will earn its keep when the scope widens.

## Stage 4 — Execution (OCaml / Python)

**Status: not implemented in this repository.**

Catala compiles to OCaml and to Python. Neither backend is currently invoked.
The intended role of each:

- **OCaml** — the reference execution target. It is the backend the Catala
  team treats as primary, and the one to trust when the two disagree.
- **Python** — the integration target, because it is what an audit team can
  realistically call from a data pipeline, and what the property-based test
  harness of stage 5 drives.

Disagreement between the two backends on the same input is a compiler bug,
not a legal question, and should be reported upstream.

## Stage 5 — Verification and testing (Lean 4 + Hypothesis)

Two independent mechanisms, answering different questions.

**Lean 4 — is the implementation faithful to the specification?**
`lean/DL187/Eligibility.lean` re-implements the rules independently and proves
`isEligible_iff_spec`: the implementation is *logically equivalent* to the FOL
specification, for every beneficiary, not merely on the tested cases. This is
the claim that "faithful by construction" has to cash out as, and it is the
theorem that distinguishes this work from a well-tested program.

Alongside it the file proves totality, determinism, monotonicity, and the
sharpness of both thresholds.

**Hypothesis — do the two implementations agree in practice?**
**Status: not implemented.** Lean proves the Lean code correct; it says
nothing about the Catala code. The bridge is differential testing: generate
beneficiaries, run them through the Catala-compiled Python and through a
transcription of the Lean definitions, and fail on any divergence.

`tests/vectors.json` is the seed of this: a small set of golden cases,
consumed by every stage, so that at minimum the boundary behaviour is checked
identically everywhere.

## Stage 6 — Decision

**Status: not implemented.**

The end product for an auditor is not a boolean. It is a decision with a
reason attached:

```
DEFERIDO   — Art. 19 satisfied (35 ≥ 15 years); Art. 20 satisfied (68 ≥ 65).
INDEFERIDO — Art. 19 satisfied (20 ≥ 15 years); Art. 20 NOT satisfied (50 < 65).
```

The article that decided the case must appear in the output. A system that
returns `false` without naming the condition that failed is not auditable and
has no institutional value for the Tribunal de Contas use case.

## What is deliberately excluded

| Excluded | Reason |
|---|---|
| Anticipation regimes, Art. 20(a)–(d) | Requires Catala exception handling; next increment |
| Art. 12 density rules | Depends on the contribution record model, not yet formalized |
| Survivor's pension | Out of the thesis scope |
| Post-2014 amendments (sustainability factor, variable normal age) | The 2007 wording is fixed on purpose: a moving target cannot be a proof of concept |

## Reading order for a newcomer

1. `docs/INTERPRETATION.md` — why the rules say what they say
2. `Pensoes.catala_en` — the statute and its executable form
3. `lean/DL187/Eligibility.lean` — the specification and its proof
4. `run_pipeline.sh` — how it is all checked
