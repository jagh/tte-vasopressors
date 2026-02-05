/*******************************************************************************
 * TRAUMATIC HYPOTENSION COHORT IDENTIFICATION
 * ==============================================================================
 * 
 * PURPOSE
 * -------
 * This query identifies patients presenting to the Emergency Department (ED) with:
 *   1. Traumatic injury (excluding TBI and spinal cord injuries)
 *   2. Hypotension (systolic blood pressure < 90 mmHg)
 * 
 * The cohort is then stratified by vasopressor use to enable comparative analysis.
 * 
 * 
 * DATA SOURCE
 * -----------
 * MIMIC-IV Emergency Department module (mimiciv_ed)
 * Tables used:
 *   - mimiciv_ed.edstays      : ED visit information
 *   - mimiciv_ed.diagnosis    : ICD diagnosis codes
 *   - mimiciv_ed.triage       : Initial triage vital signs
 *   - mimiciv_ed.vitalsign    : Vital signs during ED stay
 *   - mimiciv_ed.pyxis        : Medication dispensing records
 * 
 * NOTE: This version does NOT use the hospital module (mimiciv_hosp.patients)
 *       Therefore, age and mortality data are NOT available.
 *       To add these, you would need access to the hospital module.
 * 
 * 
 * KEY DEFINITIONS
 * ---------------
 * - Hypotension: SBP < 90 mmHg at any point during ED stay
 * - Trauma: ICD-9/10 codes for injuries (see inclusion criteria below)
 * - Vasopressors: Norepinephrine, Epinephrine, Dopamine, Phenylephrine, Vasopressin
 * 
 * 
 * AUTHOR & VERSION
 * ----------------
 * Version 2.0 - Uses only mimiciv_ed tables
 * 
 ******************************************************************************/


-- ============================================================================
-- PART 1: DEFINE INCLUSION CRITERIA (TRAUMA DIAGNOSES)
-- ============================================================================

WITH trauma_inclusion_icd10 AS (
  SELECT icd_code_prefix
  FROM UNNEST([
    -- HEAD INJURIES (excluding TBI codes S06-S08)
    'S00', 'S01', 'S02', 'S03', 'S04', 'S05', 'S09',
    
    -- NECK INJURIES (excluding cervical spine S12, S14)
    'S10', 'S11', 'S13', 'S15', 'S16', 'S17', 'S19',
    
    -- THORAX INJURIES (excluding thoracic spine S22, S24)
    'S20', 'S21', 'S23', 'S25', 'S26', 'S27', 'S28', 'S29',
    
    -- ABDOMEN/PELVIS INJURIES (excluding lumbar/sacral spine S32, S34)
    'S30', 'S31', 'S33', 'S35', 'S36', 'S37', 'S38', 'S39',
    
    -- SHOULDER AND UPPER ARM (S40-S49)
    'S40', 'S41', 'S42', 'S43', 'S45', 'S46', 'S47', 'S48', 'S49',
    
    -- ELBOW AND FOREARM (S50-S59)
    'S50', 'S51', 'S52', 'S53', 'S55', 'S56', 'S57', 'S58', 'S59',
    
    -- WRIST AND HAND (S60-S69)
    'S60', 'S61', 'S62', 'S63', 'S65', 'S66', 'S67', 'S68', 'S69',
    
    -- HIP AND THIGH (S70-S79) - includes femur fractures (S72)
    'S70', 'S71', 'S72', 'S73', 'S75', 'S76', 'S77', 'S78', 'S79',
    
    -- KNEE AND LOWER LEG (S80-S89) - includes tibia/fibula fractures (S82)
    'S80', 'S81', 'S82', 'S83', 'S85', 'S86', 'S87', 'S88', 'S89',
    
    -- ANKLE AND FOOT (S90-S99)
    'S90', 'S91', 'S92', 'S93', 'S95', 'S96', 'S97', 'S98', 'S99',
    
    -- MULTIPLE/UNSPECIFIED BODY REGION INJURIES (T00-T07)
    'T00', 'T01', 'T02', 'T03', 'T04', 'T05', 'T06', 'T07',
    
    -- INJURY OF UNSPECIFIED BODY REGION
    'T14'
  ]) AS icd_code_prefix
),

trauma_inclusion_icd9 AS (
  SELECT icd_code_prefix
  FROM UNNEST([
    -- FRACTURES (800-829), excluding 806 (spinal with cord injury)
    '800', '801', '802', '803', '804', '805', '807', '808', '809',
    '810', '811', '812', '813', '814', '815', '816', '817', '818', '819',
    '820', '821', '822', '823', '824', '825', '826', '827', '828', '829',
    
    -- DISLOCATIONS (830-839)
    '830', '831', '832', '833', '834', '835', '836', '837', '838', '839',
    
    -- SPRAINS AND STRAINS (840-848)
    '840', '841', '842', '843', '844', '845', '846', '847', '848',
    
    -- INTERNAL INJURIES (860-869)
    '860', '861', '862', '863', '864', '865', '866', '867', '868', '869',
    
    -- OPEN WOUNDS (870-897)
    '870', '871', '872', '873', '874', '875', '876', '877', '878', '879',
    '880', '881', '882', '883', '884', '885', '886', '887', '888', '889',
    '890', '891', '892', '893', '894', '895', '896', '897',
    
    -- INJURY TO BLOOD VESSELS (900-904)
    '900', '901', '902', '903', '904',
    
    -- TRAUMATIC COMPLICATIONS AND INJURIES (958-959)
    '958', '959'
  ]) AS icd_code_prefix
),


-- ============================================================================
-- PART 2: DEFINE EXCLUSION CRITERIA
-- ============================================================================

trauma_exclusion AS (
  SELECT icd_code_prefix
  FROM UNNEST([
    -- SPINAL CORD INJURIES (neurogenic shock has different management)
    'S12', 'S14', 'S22', 'S24', 'S32', 'S34',
    '806', '952',
    
    -- POISONING & TOXIC EFFECTS (non-traumatic)
    'T36', 'T37', 'T38', 'T39', 'T40', 'T41', 'T42', 'T43', 'T44',
    'T45', 'T46', 'T47', 'T48', 'T49', 'T50', 'T51', 'T52', 'T53',
    'T54', 'T55', 'T56', 'T57', 'T58', 'T59', 'T60', 'T61', 'T62',
    'T63', 'T64', 'T65',
    '96', '97', '98',
    
    -- ALLERGIC/ANAPHYLACTIC REACTIONS (distributive shock)
    'T78', 'T80', 'T88',
    '9953', '9954',
    
    -- BITES (infection/envenomation)
    'W53', 'W54', 'W55', 'W56', 'W57', 'W58', 'W59',
    'X20', 'X21', 'X22', 'X23', 'X24', 'X25', 'X26', 'X27',
    'E905', 'E906',
    
    -- IATROGENIC INJURIES (hospital-acquired)
    'T81', 'T82', 'T83', 'T84', 'T85', 'T86', 'T87',
    '996', '997', '998', '999',
    'E870', 'E871', 'E872', 'E873', 'E874', 'E875', 'E876'
  ]) AS icd_code_prefix
),


-- ============================================================================
-- PART 3: IDENTIFY TRAUMA PATIENTS
-- ============================================================================

trauma_patients AS (
  SELECT DISTINCT
    d.subject_id,
    d.stay_id,
    d.icd_code,
    d.icd_version,
    d.icd_title,
    d.seq_num
  FROM `physionet-data.mimiciv_ed.diagnosis` d
  WHERE 
    -- ICD-10 inclusion
    (
      d.icd_version = 10 
      AND EXISTS (
        SELECT 1 FROM trauma_inclusion_icd10 ti
        WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')
      )
    )
    OR
    -- ICD-9 inclusion
    (
      d.icd_version = 9 
      AND EXISTS (
        SELECT 1 FROM trauma_inclusion_icd9 ti
        WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')
      )
    )
  -- Exclude specific conditions
  AND NOT EXISTS (
    SELECT 1 FROM trauma_exclusion te
    WHERE d.icd_code LIKE CONCAT(te.icd_code_prefix, '%')
  )
),


-- ============================================================================
-- PART 4: IDENTIFY HYPOTENSIVE PATIENTS (SBP < 90 mmHg)
-- ============================================================================

hypotensive_patients AS (
  SELECT 
    subject_id,
    stay_id,
    MIN(sbp) AS min_sbp_ed,
    STRING_AGG(DISTINCT vitals_source, ', ' ORDER BY vitals_source) AS hypotension_source
  FROM (
    -- Hypotension at triage
    SELECT 
      subject_id, 
      stay_id, 
      sbp,
      'Triage' AS vitals_source
    FROM `physionet-data.mimiciv_ed.triage`
    WHERE sbp IS NOT NULL AND sbp < 90
    
    UNION ALL
    
    -- Hypotension during ED stay
    SELECT 
      subject_id, 
      stay_id, 
      sbp,
      'ED Vitals' AS vitals_source
    FROM `physionet-data.mimiciv_ed.vitalsign`
    WHERE sbp IS NOT NULL AND sbp < 90
  )
  GROUP BY subject_id, stay_id
),


-- ============================================================================
-- PART 5: IDENTIFY VASOPRESSOR USE
-- ============================================================================

vasopressor_use AS (
  SELECT DISTINCT
    p.subject_id,
    p.stay_id,
    p.name AS medication_name,
    p.charttime AS admin_time
  FROM `physionet-data.mimiciv_ed.pyxis` p
  WHERE 
    LOWER(p.name) LIKE '%norepinephrine%'
    OR LOWER(p.name) LIKE '%levophed%'
    OR LOWER(p.name) LIKE '%epinephrine%'
    OR LOWER(p.name) LIKE '%adrenaline%'
    OR LOWER(p.name) LIKE '%dopamine%'
    OR LOWER(p.name) LIKE '%phenylephrine%'
    OR LOWER(p.name) LIKE '%neosynephrine%'
    OR LOWER(p.name) LIKE '%vasopressin%'
),

vasopressor_summary AS (
  SELECT
    subject_id,
    stay_id,
    COUNT(DISTINCT medication_name) AS num_different_vasopressors,
    STRING_AGG(DISTINCT medication_name, '; ' ORDER BY medication_name) AS vasopressors_given,
    MIN(admin_time) AS first_vasopressor_time,
    MAX(admin_time) AS last_vasopressor_time,
    COUNT(*) AS total_vasopressor_doses
  FROM vasopressor_use
  GROUP BY subject_id, stay_id
),


-- ============================================================================
-- PART 6: BUILD FINAL COHORT
-- ============================================================================

final_cohort AS (
  SELECT
    -- PATIENT AND VISIT IDENTIFIERS
    ed.subject_id,
    ed.stay_id,
    ed.hadm_id,
    
    -- ED VISIT DETAILS
    ed.intime AS ed_arrival,
    ed.outtime AS ed_departure,
    DATETIME_DIFF(ed.outtime, ed.intime, MINUTE) AS ed_los_minutes,
    ed.gender,
    ed.race,
    ed.arrival_transport,
    ed.disposition,
    
    -- TRAUMA DIAGNOSIS
    tp.icd_code AS trauma_icd_code,
    tp.icd_version AS trauma_icd_version,
    tp.icd_title AS trauma_diagnosis,
    tp.seq_num AS diagnosis_sequence,
    
    -- HEMODYNAMIC DATA
    hp.min_sbp_ed,
    hp.hypotension_source,
    
    -- VASOPRESSOR INFORMATION
    CASE WHEN vs.subject_id IS NOT NULL THEN 1 ELSE 0 END AS vasopressor_used,
    COALESCE(vs.num_different_vasopressors, 0) AS num_different_vasopressors,
    vs.vasopressors_given,
    vs.first_vasopressor_time,
    vs.last_vasopressor_time,
    vs.total_vasopressor_doses,
    
    -- Time from ED arrival to first vasopressor (minutes)
    CASE 
      WHEN vs.first_vasopressor_time IS NOT NULL 
      THEN DATETIME_DIFF(vs.first_vasopressor_time, ed.intime, MINUTE)
      ELSE NULL
    END AS minutes_to_first_vasopressor
    
  FROM `physionet-data.mimiciv_ed.edstays` ed
  
  -- Must have trauma diagnosis
  INNER JOIN trauma_patients tp
    ON ed.subject_id = tp.subject_id
    AND ed.stay_id = tp.stay_id
  
  -- Must have hypotension
  INNER JOIN hypotensive_patients hp
    ON ed.subject_id = hp.subject_id
    AND ed.stay_id = hp.stay_id
  
  -- Vasopressor data (optional)
  LEFT JOIN vasopressor_summary vs
    ON ed.subject_id = vs.subject_id
    AND ed.stay_id = vs.stay_id
)


-- ============================================================================
-- MAIN OUTPUT: COHORT SUMMARY STATISTICS
-- ============================================================================

SELECT
  -- COHORT SIZE
  COUNT(DISTINCT stay_id) AS total_ed_stays,
  COUNT(DISTINCT subject_id) AS total_unique_patients,
  
  -- VASOPRESSOR USAGE
  SUM(vasopressor_used) AS stays_with_vasopressor,
  SUM(CASE WHEN vasopressor_used = 0 THEN 1 ELSE 0 END) AS stays_without_vasopressor,
  ROUND(100.0 * SUM(vasopressor_used) / COUNT(*), 2) AS pct_vasopressor_use,
  
  -- GENDER DISTRIBUTION
  SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
  SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count,
  ROUND(100.0 * SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_male,
  
  -- HEMODYNAMIC DATA
  ROUND(AVG(min_sbp_ed), 1) AS mean_min_sbp,
  ROUND(STDDEV(min_sbp_ed), 1) AS sd_min_sbp,
  MIN(min_sbp_ed) AS lowest_sbp,
  MAX(min_sbp_ed) AS highest_sbp_under_90,
  
  -- ED LENGTH OF STAY
  ROUND(AVG(ed_los_minutes), 1) AS mean_ed_los_minutes,
  ROUND(STDDEV(ed_los_minutes), 1) AS sd_ed_los_minutes,
  
  -- DISPOSITION SUMMARY
  SUM(CASE WHEN disposition = 'ADMITTED' THEN 1 ELSE 0 END) AS admitted_count,
  SUM(CASE WHEN disposition = 'DISCHARGED' THEN 1 ELSE 0 END) AS discharged_count,
  SUM(CASE WHEN disposition = 'TRANSFER' THEN 1 ELSE 0 END) AS transfer_count,
  SUM(CASE WHEN disposition = 'EXPIRED' THEN 1 ELSE 0 END) AS expired_in_ed_count

FROM final_cohort;