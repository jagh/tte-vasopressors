# Target Trial Emulation: Vasopressors in Traumatic Hemorrhagic Shock

A Target Trial Emulation (TTE) framework to evaluate the effect of vasopressor use on mortality and organ dysfunction in patients with traumatic hemorrhagic shock.

## Background

Vasopressor use in severely injured trauma patients has been controversial due to concerns that vasoconstriction may worsen organ perfusion. Early observational studies showed higher odds of death among patients receiving vasopressors (unadjusted RR 2.31–7.39), but these results were confounded by indication bias—patients who received vasopressors were systematically sicker.

Recent pathophysiology research reveals that initial trauma-induced vasoconstriction evolves into a sympathoinhibitory phase with diminished catecholamine effect and neurohormonal depletion, leading to progressive hypotension that may not respond to fluid resuscitation alone.

Given the challenges of conducting randomized controlled trials in this emergent setting, this project employs **Target Trial Emulation** using real-world data from the MIMIC-IV database.

## Study Design

### Eligibility Criteria

**Inclusion:**
- Adult patients (≥18 years) admitted to the Emergency Department
- Hypotension (SBP <90 mmHg) at triage or during ED stay
- Traumatic mechanism of injury (blunt or penetrating)
- Evidence of hemorrhagic shock

**Exclusion:**
- Spinal cord injury as cause of shock
- Tension pneumothorax as cause of shock
- Vasopressors or transfusion received prior to ED arrival
- Cardiac arrest
- Comfort care prior to trauma
- Bites, iatrogenic injuries, anaphylaxis

### Intervention

- **Treatment arm:** Use of any vasopressor in the Emergency Department
  - Norepinephrine, Vasopressin, Dopamine, Epinephrine, Phenylephrine, etc.
- **Control arm:** No vasopressor use in the ED

### Outcomes

**Primary:** All-cause in-hospital mortality

**Secondary:**
- Organ failure (SOFA scores, duration of vital support)
- Transfusion requirements (48h cumulative volume)
- Fluid balance at 48h
- Total vasopressor requirement within 48h
- Length of stay

## Repository Structure

```
tte-vasopressors/
├── README.md
├── tte_vasopressor_in_traumatic_shock_exploration.ipynb  # Study protocol & exploration
└── tte_trauma_elegibility_criteria.sql                   # Cohort selection queries (BigQuery/MIMIC-IV)
```

## Data Source

This study uses the **MIMIC-IV** (Medical Information Mart for Intensive Care) database, accessed via Google BigQuery.

### Required Tables
- `physionet-data.mimiciv_ed.diagnosis`
- `physionet-data.mimiciv_ed.triage`
- `physionet-data.mimiciv_ed.vitalsign`
- `physionet-data.mimiciv_ed.pyxis`
- `physionet-data.mimiciv_ed.edstays`
- `physionet-data.mimiciv_3_1_hosp.patients`

## Getting Started

### Prerequisites

1. Access to MIMIC-IV database (requires PhysioNet credentialing)
2. Google Cloud Platform account with BigQuery access
3. Python environment with Jupyter Notebook

### Usage

1. Execute the SQL queries in `tte_trauma_elegibility_criteria.sql` to extract the study cohort
2. Follow the analysis workflow in the Jupyter notebook

## ICD Code Classification

The SQL script includes comprehensive ICD-9 and ICD-10 code classifications for:
- **Inclusion:** Traumatic injuries across body regions (S00-S99, T00-T14)
- **Exclusion:** TBI, spinal cord injuries, poisoning, anaphylaxis, bites, iatrogenic injuries

## References

- European Guidelines on trauma resuscitation and vasopressor use
- MIMIC-IV Database: Johnson AEW, et al. MIMIC-IV, a freely accessible electronic health record dataset. Sci Data. 2023.

## License

This project is for research purposes. MIMIC-IV data usage must comply with PhysioNet's data use agreement.

---

*This research is part of multi-center collaboration project investigating vasopressor initiation in shock states.*
