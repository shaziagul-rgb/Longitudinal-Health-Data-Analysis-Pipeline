-- ---------------------------------------------------------
-- Basic dataset counts
-- ---------------------------------------------------------

SELECT COUNT(*) AS participant_count
FROM participants;

SELECT COUNT(*) AS assessment_count
FROM assessments;


-- ---------------------------------------------------------
-- Number of participants observed at each wave
-- ---------------------------------------------------------

SELECT
    wave,
    COUNT(DISTINCT participant_id) AS participants
FROM assessments
GROUP BY wave
ORDER BY wave;


-- ---------------------------------------------------------
-- Mean measurements by wave
-- ---------------------------------------------------------

SELECT
    wave,
    COUNT(*) AS assessment_count,
    AVG(bmi) AS mean_bmi,
    AVG(systolic_bp) AS mean_systolic_bp,
    AVG(questionnaire_score) AS mean_questionnaire_score
FROM assessments
GROUP BY wave
ORDER BY wave;


-- ---------------------------------------------------------
-- Missingness by variable
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS total_assessments,
    SUM(CASE WHEN bmi IS NULL THEN 1 ELSE 0 END) AS missing_bmi,
    SUM(CASE WHEN systolic_bp IS NULL THEN 1 ELSE 0 END) AS missing_systolic_bp,
    SUM(
        CASE
            WHEN questionnaire_score IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_questionnaire_score
FROM assessments;


-- ---------------------------------------------------------
-- Participants with four assessment waves
-- ---------------------------------------------------------

SELECT
    participant_id,
    COUNT(DISTINCT wave) AS number_of_waves
FROM assessments
GROUP BY participant_id
HAVING COUNT(DISTINCT wave) = 4
ORDER BY participant_id;


-- ---------------------------------------------------------
-- Longitudinal BMI change
-- ---------------------------------------------------------

WITH bmi_change AS (
    SELECT
        participant_id,
        MIN(CASE WHEN wave = 1 THEN bmi END) AS bmi_wave_1,
        MAX(CASE WHEN wave = 4 THEN bmi END) AS bmi_wave_4
    FROM assessments
    GROUP BY participant_id
)

SELECT
    participant_id,
    bmi_wave_1,
    bmi_wave_4,
    bmi_wave_4 - bmi_wave_1 AS bmi_change
FROM bmi_change
WHERE bmi_wave_1 IS NOT NULL
  AND bmi_wave_4 IS NOT NULL
ORDER BY participant_id;