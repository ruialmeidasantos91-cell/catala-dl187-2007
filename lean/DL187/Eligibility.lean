/-
  SPDX-FileCopyrightText: 2026 Rui Almeida Santos
  SPDX-License-Identifier: Apache-2.0

  DL 187/2007 — Old-Age Pension Eligibility
  Formal verification of Art. 10(1), 19, 20 (original 2007 wording)

  This file is an INDEPENDENT re-implementation of the rules, not a
  translation of the Catala code. Its purpose is to state the First-Order
  Logic specification as a Lean proposition and to prove that the executable
  definition is logically equivalent to it, for every beneficiary.

  FOL specification (see docs/ARCHITECTURE.md, stage 2):
    GP(b) ↔ years(b) ≥ 15        [Art. 19]
    NA(b) ↔ age(b)   ≥ 65        [Art. 20]
    E(b)  ↔ GP(b) ∧ NA(b)        [Art. 10(1), partial — see docs/INTERPRETATION.md D3]
-/

namespace DL187

/-- A beneficiary, reduced to the two quantities the current scope needs.
    `years` is the number of civil years with a record of remuneration
    (Art. 19); the reduction from a contribution record to an integer is an
    interpretive decision, logged as D1. -/
structure Beneficiary where
  age   : Nat
  years : Nat
deriving Repr, DecidableEq

/-! ## The specification

The FOL predicates, stated as Lean propositions. These are the *meaning* the
implementation must match. Nothing below this point may change without a
corresponding entry in `docs/INTERPRETATION.md`. -/

/-- Art. 19 — guarantee period. -/
def SpecGuaranteePeriod (b : Beneficiary) : Prop := b.years ≥ 15

/-- Art. 20 — normal age of access (original 2007 wording). -/
def SpecNormalAge (b : Beneficiary) : Prop := b.age ≥ 65

/-- Art. 10(1) — common conditions (partial: substantive conditions only). -/
def SpecEligible (b : Beneficiary) : Prop :=
  SpecGuaranteePeriod b ∧ SpecNormalAge b

/-! ## The implementation

Executable, decidable versions of the same rules. -/

/-- Art. 19 — guarantee period. -/
def meetsGuaranteePeriod (b : Beneficiary) : Bool := b.years ≥ 15

/-- Art. 20 — normal age of access. -/
def meetsAgeCondition (b : Beneficiary) : Bool := b.age ≥ 65

/-- Art. 10(1) — eligibility (partial). -/
def isEligible (b : Beneficiary) : Bool :=
  meetsGuaranteePeriod b && meetsAgeCondition b

/-! ## Adequacy

The central result. Everything else in this file is a corollary or a
regression test. -/

/-- **Adequacy of Art. 19.** -/
theorem meetsGuaranteePeriod_iff (b : Beneficiary) :
    meetsGuaranteePeriod b = true ↔ SpecGuaranteePeriod b := by
  simp [meetsGuaranteePeriod, SpecGuaranteePeriod]

/-- **Adequacy of Art. 20.** -/
theorem meetsAgeCondition_iff (b : Beneficiary) :
    meetsAgeCondition b = true ↔ SpecNormalAge b := by
  simp [meetsAgeCondition, SpecNormalAge]

/-- **Adequacy theorem.** The executable definition and the First-Order Logic
    specification agree on *every* beneficiary. This is the claim that
    "faithful by construction" has to cash out as; the boundary cases below
    are consequences of it, not evidence for it. -/
theorem isEligible_iff_spec (b : Beneficiary) :
    isEligible b = true ↔ SpecEligible b := by
  simp [isEligible, SpecEligible, meetsGuaranteePeriod_iff, meetsAgeCondition_iff,
        SpecGuaranteePeriod, SpecNormalAge]

/-- Expanded form, useful for rewriting in arithmetic proofs. -/
theorem isEligible_iff (b : Beneficiary) :
    isEligible b = true ↔ (b.years ≥ 15 ∧ b.age ≥ 65) := by
  simp [isEligible, meetsGuaranteePeriod, meetsAgeCondition]

/-! ## Structural properties

The properties the doctoral plan requires the pension function to have. For
the current scope most are immediate; they are stated explicitly so that a
future scope extension which breaks one of them fails to compile rather than
passing silently. -/

/-- **Totality.** The function is defined for every beneficiary and returns a
    decision. Trivial at this scope (see D5); it stops being trivial once
    dates enter the model. -/
theorem isEligible_total (b : Beneficiary) :
    isEligible b = true ∨ isEligible b = false := by
  cases h : isEligible b
  · exact Or.inr rfl
  · exact Or.inl rfl

/-- **Functional determinism.** Equal inputs yield equal decisions. Immediate
    for a Lean function; stated because it is a property the thesis claims of
    the legal rule, and the claim must be visible somewhere. -/
theorem isEligible_deterministic (b₁ b₂ : Beneficiary) (h : b₁ = b₂) :
    isEligible b₁ = isEligible b₂ := by rw [h]

/-- **Decidability.** Eligibility is decidable, i.e. the specification is
    computable and not merely well-defined. -/
instance (b : Beneficiary) : Decidable (SpecEligible b) :=
  decidable_of_iff (isEligible b = true) (isEligible_iff_spec b)

/-- **Monotonicity.** Getting older and accumulating more years never removes
    eligibility. A scope extension that introduces an upper age bound or a
    clawback will break this theorem, which is the point of stating it. -/
theorem isEligible_mono {b b' : Beneficiary}
    (hage : b.age ≤ b'.age) (hyears : b.years ≤ b'.years)
    (h : isEligible b = true) : isEligible b' = true := by
  rw [isEligible_iff] at h ⊢
  omega

/-- **Sharpness of the age threshold.** One year below 65 is refused, however
    long the contribution record. -/
theorem age_threshold_sharp (n : Nat) :
    isEligible { age := 64, years := n } = false := by
  simp [isEligible, meetsAgeCondition]

/-- **Sharpness of the guarantee-period threshold.** Fourteen years is
    refused, at any age. -/
theorem years_threshold_sharp (n : Nat) :
    isEligible { age := n, years := 14 } = false := by
  simp [isEligible, meetsGuaranteePeriod]

/-! ## Golden cases

These mirror `tests/vectors.json` and the Catala test scopes exactly. If a
case here disagrees with the same case there, the pipeline is inconsistent
and `run_pipeline.sh` must fail. -/

/-- Case 1 — comfortably above both thresholds. -/
example : isEligible { age := 68, years := 35 } = true := by decide

/-- Case 2 — below the age threshold. -/
example : isEligible { age := 50, years := 20 } = false := by decide

/-- Case 3 — exactly on both thresholds; eligible (see D1). -/
example : isEligible { age := 65, years := 15 } = true := by decide

/-- Case 4 — one year short on age. -/
example : isEligible { age := 64, years := 40 } = false := by decide

/-- Case 5 — one year short on the guarantee period. -/
example : isEligible { age := 70, years := 14 } = false := by decide

/-- Case 6 — both thresholds missed. -/
example : isEligible { age := 30, years := 5 } = false := by decide

end DL187
