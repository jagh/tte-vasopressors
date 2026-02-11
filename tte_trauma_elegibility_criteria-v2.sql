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

    'S00', 'S01', 'S02', 'S03', 'S04', 'S05', 'S09',

    'S10', 'S11', 'S13', 'S15', 'S16', 'S17', 'S19',

    'S20', 'S21', 'S23', 'S25', 'S26', 'S27', 'S28', 'S29',

    'S30', 'S31', 'S33', 'S35', 'S36', 'S37', 'S38', 'S39',

    'S40', 'S41', 'S42', 'S43', 'S45', 'S46', 'S47', 'S48', 'S49',

    'S50', 'S51', 'S52', 'S53', 'S55', 'S56', 'S57', 'S58', 'S59',

    'S60', 'S61', 'S62', 'S63', 'S65', 'S66', 'S67', 'S68', 'S69',

    'S70', 'S71', 'S72', 'S73', 'S75', 'S76', 'S77', 'S78', 'S79',

    'S80', 'S81', 'S82', 'S83', 'S85', 'S86', 'S87', 'S88', 'S89',

    'S90', 'S91', 'S92', 'S93', 'S95', 'S96', 'S97', 'S98', 'S99',

    'T00', 'T01', 'T02', 'T03', 'T04', 'T05', 'T06', 'T07',

    'T14'

  ]) AS icd_code_prefix

),
 
trauma_inclusion_icd9 AS (

  SELECT icd_code_prefix

  FROM UNNEST([

    '800', '801', '802', '803', '804', '805', '807', '808', '809',

    '810', '811', '812', '813', '814', '815', '816', '817', '818', '819',

    '820', '821', '822', '823', '824', '825', '826', '827', '828', '829',

    '830', '831', '832', '833', '834', '835', '836', '837', '838', '839',

    '840', '841', '842', '843', '844', '845', '846', '847', '848',

    '860', '861', '862', '863', '864', '865', '866', '867', '868', '869',

    '870', '871', '872', '873', '874', '875', '876', '877', '878', '879',

    '880', '881', '882', '883', '884', '885', '886', '887', '888', '889',

    '890', '891', '892', '893', '894', '895', '896', '897',

    '900', '901', '902', '903', '904',

    '958', '959'

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

        AND NOT EXISTS (

          SELECT 1 FROM trauma_exclusion_icd9 te

          WHERE d.icd_code LIKE CONCAT(te.icd_code_prefix, '%')

        )

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
 
Row step  ed_stays  unique_patients
1 Step 1: Trauma  49949 43389
4 Step 2: Trauma + SBP<90 (WITH exclusion)  726 719
*/
 
 