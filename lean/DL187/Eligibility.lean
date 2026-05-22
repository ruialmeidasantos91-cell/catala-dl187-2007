-- DL 187/2007 - Old-Age Pension Eligibility
-- Formal verification of Art. 10(1), 19, 20 (original 2007 wording)
--
-- FOL Specification:
-- GP(b) ↔ years(b) ≥ 15                  [Art. 19]
-- NA(b) ↔ age(b) ≥ 65                    [Art. 20]
-- E(b)  ↔ GP(b) ∧ NA(b)                  [Art. 10(1)]

structure Beneficiary where
  age : Nat
  years : Nat

-- Art. 19: Guarantee period
def meetsGuaranteePeriod (b : Beneficiary) : Bool :=
  b.years ≥ 15

-- Art. 20: Normal age of access (original 2007)
def meetsAgeCondition (b : Beneficiary) : Bool :=
  b.age ≥ 65

-- Art. 10(1): Eligibility (partial)
def isEligible (b : Beneficiary) : Bool :=
  meetsGuaranteePeriod b && meetsAgeCondition b

-- Theorem: boundary case -- exactly 15 years and 65 years old is eligible
theorem boundary_eligible :
    isEligible { age := 65, years := 15 } = true := by
  decide

-- Theorem: below age threshold is not eligible
theorem below_age_not_eligible :
    isEligible { age := 50, years := 35 } = false := by
  decide

-- Theorem: below guarantee period is not eligible
theorem below_guarantee_not_eligible :
    isEligible { age := 68, years := 10 } = false := by
  decide
