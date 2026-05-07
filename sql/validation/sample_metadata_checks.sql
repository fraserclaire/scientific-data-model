SET search_path TO scientific;

SELECT
    'samples_without_experiment' AS check_name,
    s.sample_code AS record_id,
    'Sample is not linked to any experiment through experiment_samples.' AS issue
FROM samples s
LEFT JOIN experiment_samples es ON es.sample_id = s.sample_id
WHERE es.sample_id IS NULL
ORDER BY s.sample_code;

SELECT
    'experiment_samples_without_treatment' AS check_name,
    e.experiment_code || ':' || s.sample_code AS record_id,
    'Experiment sample is missing a treatment condition.' AS issue
FROM experiment_samples es
JOIN experiments e ON e.experiment_id = es.experiment_id
JOIN samples s ON s.sample_id = es.sample_id
WHERE NOT EXISTS (
    SELECT 1
    FROM sample_conditions sc
    JOIN conditions c ON c.condition_id = sc.condition_id
    WHERE sc.sample_id = s.sample_id
      AND c.condition_name = 'treatment'
)
ORDER BY e.experiment_code, s.sample_code;

SELECT
    'experiment_samples_without_replicate_number' AS check_name,
    e.experiment_code || ':' || s.sample_code AS record_id,
    'Experiment sample is missing replicate_number.' AS issue
FROM experiment_samples es
JOIN experiments e ON e.experiment_id = es.experiment_id
JOIN samples s ON s.sample_id = es.sample_id
WHERE es.replicate_number IS NULL
ORDER BY e.experiment_code, s.sample_code;

SELECT
    'duplicate_replicate_assignments' AS check_name,
    e.experiment_code || ':' || es.role || ':R' || es.replicate_number AS record_id,
    'More than one sample has the same experiment role and replicate number.' AS issue
FROM experiment_samples es
JOIN experiments e ON e.experiment_id = es.experiment_id
WHERE es.replicate_number IS NOT NULL
GROUP BY e.experiment_code, es.role, es.replicate_number
HAVING COUNT(*) > 1
ORDER BY e.experiment_code, es.role, es.replicate_number;
