/*******************************************************************************

* COHORT SIZE CHECK — Step-by-step patient counts (v2)

* 

* Step 1: Trauma patients (inclusion only)

* Step 2: Trauma patients (after exclusion)

* Step 3: Trauma + SBP < 90 (NO exclusion)

* Step 4: Trauma + SBP < 90 (WITH exclusion)

******************************************************************************/
 
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
    'T14',  -- Injury of unspecified body region
    -- TRAUMATIC BRAIN INJURY (TBI)
    'S06', 'S07',  'S08',
    -- SPINAL CORD INJURIES
    'S12',  -- Fracture of cervical vertebra
    'S14',  -- Injury of nerves/spinal cord at neck level
    'S22',  -- Fracture of thoracic vertebra
    'S24',  -- Injury of nerves/spinal cord at thorax level
    'S32',  -- Fracture of lumbar spine/pelvis
    -- POISONING & TOXIC EFFECTS
    'T36', 'T37', 'T38', 'T39', 'T40', 'T41', 'T42', 'T43', 'T44',
    'T45', 'T46', 'T47', 'T48', 'T49', 'T50', 'T51', 'T52', 'T53',
    'T54', 'T55', 'T56', 'T57', 'T58', 'T59', 'T60', 'T61', 'T62',
    'T63', 'T64', 'T65',
    -- ALLERGIC/ANAPHYLACTIC REACTIONS
    'T78',  -- Adverse effects NEC (includes anaphylaxis)
    'T80',  -- Complications following infusion/transfusion
    'T88',  -- Other complications (includes anaphylaxis)
    -- BITES (HUMAN & ANIMAL)
    'W53', 'W54', 'W55', 'W56', 'W57', 'W58', 'W59',  -- ICD-10 bite codes
    'X20', 'X21', 'X22', 'X23', 'X24', 'X25', 'X26', 'X27',  -- Venomous animals
    -- IATROGENIC INJURIES
    'T81', 'T82', 'T83', 'T84', 'T85', 'T86', 'T87'  -- ICD-10 complications
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
    '958', '959',
    -- TRAUMATIC BRAIN INJURY (TBI)
    '850', '851', '852','853', '854',
    -- SPINAL CORD INJURIES
    '806',  -- Fracture of vertebral column with spinal cord injury (ICD-9)
    '952',  -- Spinal cord injury without fracture (ICD-9)
    -- POISONING & TOXIC EFFECTS
    '96',   -- Poisoning codes (ICD-9 960-969)
    '97',   -- Poisoning codes (ICD-9 970-979)
    '98',   -- Poisoning codes (ICD-9 980-989)
    -- ALLERGIC/ANAPHYLACTIC REACTIONS
    '9953', -- Anaphylactic shock (ICD-9)
    '9954', -- Anaphylactic reaction (ICD-9)
    -- BITES (HUMAN & ANIMAL)
    'E905', -- Venomous animals/plants (ICD-9)
    'E906', -- Other injury by animals (ICD-9)
    -- IATROGENIC INJURIES
    '996', '997', '998', '999',  -- Complications of medical care (ICD-9)
    'E870', 'E871', 'E872', 'E873', 'E874', 'E875', 'E876'  -- Misadventures (ICD-9)
  ]) AS icd_code_prefix
),
 
trauma_exclusion_icd10 AS (

  SELECT icd_code_prefix

  FROM UNNEST([

    'S12', 'S14', 'S22', 'S24', 'S32', 'S34',

    'T36', 'T37', 'T38', 'T39', 'T40', 'T41', 'T42', 'T43', 'T44',

    'T45', 'T46', 'T47', 'T48', 'T49', 'T50', 'T51', 'T52', 'T53',

    'T54', 'T55', 'T56', 'T57', 'T58', 'T59', 'T60', 'T61', 'T62',

    'T63', 'T64', 'T65',

    'T78', 'T80', 'T88',

    'W53', 'W54', 'W55', 'W56', 'W57', 'W58', 'W59',

    'X20', 'X21', 'X22', 'X23', 'X24', 'X25', 'X26', 'X27',

    'T81', 'T82', 'T83', 'T84', 'T85', 'T86', 'T87'

  ]) AS icd_code_prefix

),
 
trauma_exclusion_icd9 AS (

  SELECT icd_code_prefix

  FROM UNNEST([

    '806', '952',

    '96', '97', '98',

    '9953', '9954',

    'E905', 'E906',

    '996', '997', '998', '999',

    'E870', 'E871', 'E872', 'E873', 'E874', 'E875', 'E876'

  ]) AS icd_code_prefix

),
 
-- Inclusion only

trauma_inclusion_only AS (

  SELECT DISTINCT d.subject_id, d.stay_id

  FROM `physionet-data.mimiciv_ed.diagnosis` d

  WHERE 

    (

      d.icd_version = 10 

      AND EXISTS (

        SELECT 1 FROM trauma_inclusion_icd10 ti

        WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')

      )

    )

    OR

    (

      d.icd_version = 9 

      AND EXISTS (

        SELECT 1 FROM trauma_inclusion_icd9 ti

        WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')

      )

    )

),
 
-- Inclusion + exclusion

trauma_after_exclusion AS (

  SELECT DISTINCT d.subject_id, d.stay_id

  FROM `physionet-data.mimiciv_ed.diagnosis` d

  WHERE 

    (

      (

        d.icd_version = 10 

        AND EXISTS (

          SELECT 1 FROM trauma_inclusion_icd10 ti

          WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')

        )

        AND NOT EXISTS (

          SELECT 1 FROM trauma_exclusion_icd10 te

          WHERE d.icd_code LIKE CONCAT(te.icd_code_prefix, '%')

        )

      )

      OR

      (

        d.icd_version = 9 

        AND EXISTS (

          SELECT 1 FROM trauma_inclusion_icd9 ti

          WHERE d.icd_code LIKE CONCAT(ti.icd_code_prefix, '%')

        )

       # AND NOT EXISTS (

        #  SELECT 1 FROM trauma_exclusion_icd9 te

         # WHERE d.icd_code LIKE CONCAT(te.icd_code_prefix, '%')

       # )

      )

    )

),
 
-- Hypotensive stays

hypotensive_stays AS (

  SELECT DISTINCT subject_id, stay_id

  FROM (

    SELECT subject_id, stay_id

    FROM `physionet-data.mimiciv_ed.triage`

    WHERE sbp IS NOT NULL AND sbp < 90

    UNION ALL

    SELECT subject_id, stay_id

    FROM `physionet-data.mimiciv_ed.vitalsign`

    WHERE sbp IS NOT NULL AND sbp < 90

  )

)
 
SELECT

  'Step 1: Trauma (inclusion only)' AS step,

  COUNT(DISTINCT stay_id) AS ed_stays,

  COUNT(DISTINCT subject_id) AS unique_patients

FROM trauma_inclusion_only
 
UNION ALL
 
SELECT

  'Step 2: Trauma (after exclusion)' AS step,

  COUNT(DISTINCT stay_id) AS ed_stays,

  COUNT(DISTINCT subject_id) AS unique_patients

FROM trauma_after_exclusion
 
UNION ALL
 
SELECT

  'Step 3: Trauma + SBP<90 (NO exclusion)' AS step,

  COUNT(DISTINCT t.stay_id) AS ed_stays,

  COUNT(DISTINCT t.subject_id) AS unique_patients

FROM trauma_inclusion_only t

INNER JOIN hypotensive_stays h

  ON t.subject_id = h.subject_id

  AND t.stay_id = h.stay_id
 
UNION ALL
 
SELECT

  'Step 4: Trauma + SBP<90 (WITH exclusion)' AS step,

  COUNT(DISTINCT t.stay_id) AS ed_stays,

  COUNT(DISTINCT t.subject_id) AS unique_patients

FROM trauma_after_exclusion t

INNER JOIN hypotensive_stays h

  ON t.subject_id = h.subject_id

  AND t.stay_id = h.stay_id
 
ORDER BY step;
 
/*====> 
 
Step 1: Trauma (inclusion only) "ed_stays": "66146", "unique_patients": "55217"
Step 2: Trauma (after exclusion)", "ed_stays": "58016","unique_patients": "49453"
Step 3: Trauma + SBP<90 (NO exclusion)",  "ed_stays": "1287", "unique_patients": "1254"
Step 4: Trauma + SBP<90 (WITH exclusion)", "ed_stays": "983", "unique_patients": "968"

*/
 
 