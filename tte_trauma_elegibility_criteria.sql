-- ============================================================================
-- STEP 1: Define ICD Code Inclusion Criteria
-- ============================================================================
-- jagh1729@gmail.com
WITH trauma_inclusion_icd10 AS (
  SELECT icd_code_prefix
  FROM UNNEST([
    -- Head injuries (excluding TBI - S06, S07, S08)
    'S00', 'S01', 'S02', 'S03', 'S04', 'S05', 'S09',
    -- Neck injuries (excluding cervical spine - S12, S14)
    'S10', 'S11', 'S13', 'S15', 'S16', 'S17', 'S19',
    -- Thorax injuries (excluding thoracic spine - S22, S24)
    'S20', 'S21', 'S23', 'S25', 'S26', 'S27', 'S28', 'S29',
    -- Abdomen/pelvis injuries (excluding lumbar/sacral spine - S32, S34)
    'S30', 'S31', 'S33', 'S35', 'S36', 'S37', 'S38', 'S39',
    -- Shoulder and upper arm
    'S40', 'S41', 'S42', 'S43', 'S45', 'S46', 'S47', 'S48', 'S49',
    -- Elbow and forearm
    'S50', 'S51', 'S52', 'S53', 'S55', 'S56', 'S57', 'S58', 'S59',
    -- Wrist and hand
    'S60', 'S61', 'S62', 'S63', 'S65', 'S66', 'S67', 'S68', 'S69',
    -- Hip and thigh (INCLUDING S72 - femur fractures)
    'S70', 'S71', 'S72', 'S73', 'S75', 'S76', 'S77', 'S78', 'S79',
    -- Knee and lower leg (INCLUDING S82 - tibia/fibula fractures)
    'S80', 'S81', 'S82', 'S83', 'S85', 'S86', 'S87', 'S88', 'S89',
    -- Ankle and foot
    'S90', 'S91', 'S92', 'S93', 'S95', 'S96', 'S97', 'S98', 'S99',
    -- Multiple/unspecified injuries
    'T00', 'T01', 'T02', 'T03', 'T04', 'T05', 'T06', 'T07', 
    -- Other injuries
    'T14'  -- Injury of unspecified body region
  ]) AS icd_code_prefix
),

trauma_inclusion_icd9 AS (
  SELECT icd_code_prefix
  FROM UNNEST([
    -- Fractures (800-829) - excluding 806 (spinal with cord injury)
    '800', '801', '802', '803', '804', '805', '807', '808', '809',
    '810', '811', '812', '813', '814', '815', '816', '817', '818', '819',
    '820', '821', '822', '823', '824', '825', '826', '827', '828', '829',
    -- Dislocations (830-839)
    '830', '831', '832', '833', '834', '835', '836', '837', '838', '839',
    -- Sprains and strains (840-848)
    '840', '841', '842', '843', '844', '845', '846', '847', '848',
    -- Internal injuries (860-869)
    '860', '861', '862', '863', '864', '865', '866', '867', '868', '869',
    -- Open wounds (870-897)
    '870', '871', '872', '873', '874', '875', '876', '877', '878', '879',
    '880', '881', '882', '883', '884', '885', '886', '887', '888', '889',
    '890', '891', '892', '893', '894', '895', '896', '897',
    -- Injury to blood vessels (900-904)
    '900', '901', '902', '903', '904',
    -- Traumatic complications and injuries (958-959)
    '958', '959'
  ]) AS icd_code_prefix
),

-- ============================================================================
-- STEP 2: Define EXCLUSION Criteria
-- ============================================================================

trauma_exclusion AS (
  SELECT icd_code_prefix
  FROM UNNEST([
    -- ==========================================================================
    -- TRAUMATIC BRAIN INJURY (TBI)
    -- ==========================================================================
    #'S06',  -- Intracranial injury
    #'S07',  -- Crushing injury of head
    #'S08',  -- Traumatic amputation of head
    #'850',  -- Concussion (ICD-9)
    #'851',  -- Cerebral laceration/contusion (ICD-9)
    #'852',  -- Subarachnoid/subdural/extradural hemorrhage (ICD-9)
    #'853',  -- Other intracranial hemorrhage (ICD-9)
    #'854',  -- Intracranial injury, unspecified (ICD-9)
    
    -- ==========================================================================
    -- SPINAL CORD INJURIES
    -- ==========================================================================
    'S12',  -- Fracture of cervical vertebra
    'S14',  -- Injury of nerves/spinal cord at neck level
    'S22',  -- Fracture of thoracic vertebra
    'S24',  -- Injury of nerves/spinal cord at thorax level
    'S32',  -- Fracture of lumbar spine/pelvis
    'S34',  -- Injury of nerves/spinal cord at abdomen/pelvis level
    '806',  -- Fracture of vertebral column with spinal cord injury (ICD-9)
    '952',  -- Spinal cord injury without fracture (ICD-9)
    
    -- ==========================================================================
    -- POISONING & TOXIC EFFECTS
    -- ==========================================================================
    'T36', 'T37', 'T38', 'T39', 'T40', 'T41', 'T42', 'T43', 'T44',
    'T45', 'T46', 'T47', 'T48', 'T49', 'T50', 'T51', 'T52', 'T53',
    'T54', 'T55', 'T56', 'T57', 'T58', 'T59', 'T60', 'T61', 'T62',
    'T63', 'T64', 'T65',
    '96',   -- Poisoning codes (ICD-9 960-969)
    '97',   -- Poisoning codes (ICD-9 970-979)
    '98',   -- Poisoning codes (ICD-9 980-989)
    
    -- ==========================================================================
    -- ALLERGIC/ANAPHYLACTIC REACTIONS
    -- ==========================================================================
    'T78',  -- Adverse effects NEC (includes anaphylaxis)
    'T80',  -- Complications following infusion/transfusion
    'T88',  -- Other complications (includes anaphylaxis)
    '9953', -- Anaphylactic shock (ICD-9)
    '9954', -- Anaphylactic reaction (ICD-9)
    
    -- ==========================================================================
    -- BITES (HUMAN & ANIMAL)
    -- ==========================================================================
    'W53', 'W54', 'W55', 'W56', 'W57', 'W58', 'W59',  -- ICD-10 bite codes
    'X20', 'X21', 'X22', 'X23', 'X24', 'X25', 'X26', 'X27',  -- Venomous animals
    'E905', -- Venomous animals/plants (ICD-9)
    'E906', -- Other injury by animals (ICD-9)
    
    -- ==========================================================================
    -- IATROGENIC INJURIES
    -- ==========================================================================
    'T81', 'T82', 'T83', 'T84', 'T85', 'T86', 'T87',  -- ICD-10 complications
    '996', '997', '998', '999',  -- Complications of medical care (ICD-9)
    'E870', 'E871', 'E872', 'E873', 'E874', 'E875', 'E876'  -- Misadventures (ICD-9)
  ]) AS icd_code_prefix
),

-- ============================================================================
-- STEP 3: Identify Trauma Patients
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
  WHERE (
    -- ICD-10 inclusion
    (d.icd_version = 10 AND EXISTS (
      SELECT 1 FROM trauma_inclusion_icd10 ti
      WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')
    ))
    OR
    -- ICD-9 inclusion
    (d.icd_version = 9 AND EXISTS (
      SELECT 1 FROM trauma_inclusion_icd9 ti
      WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')
    ))
  )
  -- Apply exclusions
  AND NOT EXISTS (
    SELECT 1 FROM trauma_exclusion te
    WHERE d.icd_code LIKE CONCAT(te.icd_code_prefix, '%')
  )
),

-- ============================================================================
-- STEP 4: Identify Hypotensive Patients (SBP <90 mmHg)
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
    FROM `physionet-data.mimiciv_ed.triage` -- both from ED
    WHERE sbp IS NOT NULL AND sbp < 90
    
    UNION ALL
    -- at ED admission or during ED stays
    -- Hypotension during ED stay (****maybe not during ED stay but roughly it's okay: Currently for cohort size : We could come back to this question again for -24 hours from admission or after 24 hours from discharge.
    -- And are their stay_ids are same? Otherwise, you would want to group by using admission id or subject_id 
    -- ##ED : hadm_id is null, ##ED -> ICU --> probably meaning that each ED patient admission could be identified by stay_id not by hadm_id.
    -- Also you may want to have timing later: yes ****)
    SELECT 
      subject_id, 
      stay_id, 
      sbp,
      'ED Vitals' AS vitals_source
    FROM `physionet-data.mimiciv_ed.vitalsign` -- both from ED
    WHERE sbp IS NOT NULL AND sbp < 90
  )
  GROUP BY subject_id, stay_id
),

-- ============================================================================
-- STEP 5: Identify Vasopressor Use During ED Stay
-- ============================================================================

vasopressor_use AS (
  SELECT DISTINCT
    p.subject_id,
    p.stay_id,
    p.name AS medication_name,
    p.charttime AS admin_time
  FROM `physionet-data.mimiciv_ed.pyxis` p
  WHERE 
    -- Search for vasopressor medications (case-insensitive)
    LOWER(p.name) LIKE '%norepinephrine%' -- could '%levophed%'
    OR LOWER(p.name) LIKE '%epinephrine%'  -- '%adrenaline%'
    OR LOWER(p.name) LIKE '%dopamine%'
    OR LOWER(p.name) LIKE '%phenylephrine%' -- '%neosynephrine%'
    OR LOWER(p.name) LIKE '%vasopressin%'
    OR LOWER(p.name) LIKE '%levophed%'
    -- OR LOWER(p.name) LIKE '%dobutamine%'
    OR LOWER(p.name) LIKE '%adrenaline%'
    OR LOWER(p.name) LIKE '%neosynephrine%'
    --------***** angio or some other names to be checked *********------------
),

vasopressor_summary AS (
  --------***** if medication name is different but actually it's the same vasopressors or.... 
  -- if the dosage just changed over time does it make any difference? / 
  -- either bolus or not, we still want to collect dosages
  -- pheny: 9:00 to 9:03
  -- pheny: 9:02 to 9:06 =>  combine

  -- I believe you wanted to collect only 48 hours and currently it's all. 
  -- If it is required to be changed as 48 hours - from when. No time zero*********
  -- Time Zero: selected as cohort: (traumatic) hypotensive : SBP < 
  -- Collect those from 
  -- For covariates: MAP, DBP, SBP all required to be included as well as the others. ----------
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
-- STEP 6: Create Final Cohort
-- ============================================================================

final_cohort AS (
  SELECT
    -- Patient/visit identifiers
    ed.subject_id,
    ed.stay_id,
    ed.hadm_id,
    
    -- ED visit details
    ed.intime AS ed_arrival,
    ed.outtime AS ed_departure,
    DATETIME_DIFF(ed.outtime, ed.intime, MINUTE) AS ed_los_minutes,
    ed.gender,
    ed.race,
    ed.arrival_transport,
    ed.disposition,
    
    -- Trauma information
    tp.icd_code AS trauma_icd_code,
    tp.icd_version AS trauma_icd_version,
    tp.icd_title AS trauma_diagnosis,
    tp.seq_num AS diagnosis_sequence,
    
    -- Hypotension information
    hp.min_sbp_ed,
    hp.hypotension_source,
    
    -- Vasopressor information
    CASE WHEN vs.subject_id IS NOT NULL THEN 1 ELSE 0 END AS vasopressor_used,
    COALESCE(vs.num_different_vasopressors, 0) AS num_different_vasopressors,
    vs.vasopressors_given,
    vs.first_vasopressor_time,
    vs.last_vasopressor_time,
    vs.total_vasopressor_doses,
    
    -- Time from ED arrival to first vasopressor
    CASE 
      WHEN vs.first_vasopressor_time IS NOT NULL 
      THEN DATETIME_DIFF(vs.first_vasopressor_time, ed.intime, MINUTE)
      ELSE NULL
    END AS minutes_to_first_vasopressor,
    
    -- Patient demographics
    p.anchor_age,
    p.anchor_year,
    p.anchor_year_group,
    p.dod AS date_of_death,  -------------------------------------- ** Are we okay with dod or do we want in-hospital mortality?/ Do we want toinclude those who died at ED and couldn't go to ICU? THen they won't have hadm_id --
    -- first, check the data distribution of dod times.
    -- priority: in-hospital mortality
    -- secondary: organ failure (we haven't)
    
    -- Mortality indicators
    CASE WHEN p.dod IS NOT NULL THEN 1 ELSE 0 END AS died,
    CASE 
      WHEN p.dod IS NOT NULL 
      THEN DATE_DIFF(p.dod, DATE(ed.intime), DAY)
      ELSE NULL
    END AS days_ed_to_death
    
  FROM `physionet-data.mimiciv_ed.edstays` ed
  
  -- INNER JOIN: Must have trauma diagnosis
  INNER JOIN trauma_patients tp
    ON ed.subject_id = tp.subject_id
    AND ed.stay_id = tp.stay_id
  
  -- INNER JOIN: Must have hypotension
  INNER JOIN hypotensive_patients hp
    ON ed.subject_id = hp.subject_id
    AND ed.stay_id = hp.stay_id
  
  -- LEFT JOIN: Include both vasopressor users and non-users
  LEFT JOIN vasopressor_summary vs
    ON ed.subject_id = vs.subject_id
    AND ed.stay_id = vs.stay_id
  
  -- LEFT JOIN: Add patient demographics
  LEFT JOIN `physionet-data.mimiciv_3_1_hosp.patients` p
    ON ed.subject_id = p.subject_id
)

-- ============================================================================
-- MAIN OUTPUT: Summary Statistics
-- ============================================================================

SELECT
  -- Cohort size
  COUNT(DISTINCT stay_id) AS total_ed_stays,
  COUNT(DISTINCT subject_id) AS total_unique_patients,
  
  -- Vasopressor usage
  SUM(vasopressor_used) AS stays_with_vasopressor,
  SUM(CASE WHEN vasopressor_used = 0 THEN 1 ELSE 0 END) AS stays_without_vasopressor,
  ROUND(100.0 * SUM(vasopressor_used) / COUNT(*), 2) AS pct_vasopressor_use,
  
  -- Demographics
  ROUND(AVG(anchor_age), 1) AS mean_age,
  ROUND(STDDEV(anchor_age), 1) AS sd_age,
  MIN(anchor_age) AS min_age,
  MAX(anchor_age) AS max_age,
  SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
  SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count,
  ROUND(100.0 * SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_male,
  
  -- Clinical metrics
  ROUND(AVG(min_sbp_ed), 1) AS mean_min_sbp,
  ROUND(STDDEV(min_sbp_ed), 1) AS sd_min_sbp,
  MIN(min_sbp_ed) AS lowest_sbp,
  MAX(min_sbp_ed) AS highest_sbp,
  ROUND(AVG(ed_los_minutes), 1) AS mean_ed_los_minutes,
  ROUND(STDDEV(ed_los_minutes), 1) AS sd_ed_los_minutes,
  
  -- Outcomes
  SUM(died) AS total_deaths,
  ROUND(100.0 * SUM(died) / COUNT(*), 2) AS overall_mortality_pct,
  
  -- Mortality by vasopressor use
  ROUND(100.0 * SUM(CASE WHEN vasopressor_used = 1 THEN died ELSE 0 END) / 
        NULLIF(SUM(vasopressor_used), 0), 2) AS mortality_pct_with_vasopressor,
  ROUND(100.0 * SUM(CASE WHEN vasopressor_used = 0 THEN died ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN vasopressor_used = 0 THEN 1 ELSE 0 END), 0), 2) AS mortality_pct_without_vasopressor,
  
  -- Days to death (for those who died)
  ROUND(AVG(CASE WHEN died = 1 THEN days_ed_to_death END), 1) AS mean_days_to_death_if_died

FROM final_cohort;

/*******************************************************************************
 * ADDITIONAL QUERIES - Uncomment as needed
 ******************************************************************************/

-- =============================================================================
-- FULL DATASET EXPORT (for statistical software like R, Stata, SPSS)
-- =============================================================================
-- SELECT * FROM final_cohort ORDER BY ed_arrival;

-- =============================================================================
-- STRATIFIED MORTALITY ANALYSIS
-- =============================================================================
-- SELECT
--   vasopressor_used,
--   COUNT(*) AS n,
--   SUM(died) AS deaths,
--   ROUND(100.0 * SUM(died) / COUNT(*), 2) AS mortality_pct,
--   ROUND(AVG(min_sbp_ed), 1) AS avg_min_sbp,
--   ROUND(AVG(anchor_age), 1) AS avg_age,
--   ROUND(AVG(ed_los_minutes), 1) AS avg_ed_los_min,
--   ROUND(AVG(CASE WHEN died = 1 THEN days_ed_to_death END), 1) AS avg_days_to_death
-- FROM final_cohort
-- GROUP BY vasopressor_used
-- ORDER BY vasopressor_used;

-- =============================================================================
-- TOP TRAUMA DIAGNOSES
-- =============================================================================
-- SELECT 
--   trauma_icd_code,
--   trauma_diagnosis,
--   COUNT(*) AS frequency,
--   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
--   SUM(vasopressor_used) AS received_vasopressor,
--   SUM(died) AS deaths,
--   ROUND(100.0 * SUM(died) / COUNT(*), 2) AS mortality_pct
-- FROM final_cohort
-- GROUP BY trauma_icd_code, trauma_diagnosis
-- ORDER BY frequency DESC
-- LIMIT 20;

-- =============================================================================
-- VASOPRESSOR TYPES ANALYSIS
-- =============================================================================
-- SELECT 
--   vasopressors_given,
--   COUNT(*) AS frequency,
--   ROUND(AVG(min_sbp_ed), 1) AS avg_min_sbp,
--   ROUND(AVG(minutes_to_first_vasopressor), 1) AS avg_time_to_vasopressor_min,
--   SUM(died) AS deaths,
--   ROUND(100.0 * SUM(died) / COUNT(*), 2) AS mortality_pct
-- FROM final_cohort
-- WHERE vasopressor_used = 1
-- GROUP BY vasopressors_given
-- ORDER BY frequency DESC;

-- =============================================================================
-- DISPOSITION (DISCHARGE STATUS) ANALYSIS
-- =============================================================================
-- SELECT 
--   disposition,
--   COUNT(*) AS n,
--   SUM(vasopressor_used) AS received_vasopressor,
--   SUM(died) AS deaths,
--   ROUND(100.0 * SUM(died) / COUNT(*), 2) AS mortality_pct
-- FROM final_cohort
-- GROUP BY disposition
-- ORDER BY n DESC;

-- =============================================================================
-- SBP SEVERITY STRATIFICATION
-- =============================================================================
-- SELECT
--   CASE 
--     WHEN min_sbp_ed < 60 THEN '<60 mmHg (Severe)'
--     WHEN min_sbp_ed < 70 THEN '60-69 mmHg (Moderate)'
--     WHEN min_sbp_ed < 80 THEN '70-79 mmHg (Mild-Moderate)'
--     ELSE '80-89 mmHg (Mild)'
--   END AS sbp_category,
--   COUNT(*) AS n,
--   SUM(vasopressor_used) AS received_vasopressor,
--   ROUND(100.0 * SUM(vasopressor_used) / COUNT(*), 2) AS pct_vasopressor,
--   SUM(died) AS deaths,
--   ROUND(100.0 * SUM(died) / COUNT(*), 2) AS mortality_pct
-- FROM final_cohort
-- GROUP BY sbp_category
-- ORDER BY MIN(min_sbp_ed);

