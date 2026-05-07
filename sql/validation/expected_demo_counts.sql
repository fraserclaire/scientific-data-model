SET search_path TO scientific;

WITH expected_counts AS (
    SELECT *
    FROM (
        VALUES
            ('studies', 2),
            ('experiments', 3),
            ('subjects', 24),
            ('samples', 24),
            ('experiment_samples', 24),
            ('sequencing_libraries', 24),
            ('sequencing_runs', 3),
            ('library_run_metrics', 24),
            ('analysis_runs', 3),
            ('result_metrics', 72)
    ) AS counts(table_name, expected_rows)
),
actual_counts AS (
    SELECT 'studies' AS table_name, COUNT(*) AS actual_rows FROM studies
    UNION ALL SELECT 'experiments', COUNT(*) FROM experiments
    UNION ALL SELECT 'subjects', COUNT(*) FROM subjects
    UNION ALL SELECT 'samples', COUNT(*) FROM samples
    UNION ALL SELECT 'experiment_samples', COUNT(*) FROM experiment_samples
    UNION ALL SELECT 'sequencing_libraries', COUNT(*) FROM sequencing_libraries
    UNION ALL SELECT 'sequencing_runs', COUNT(*) FROM sequencing_runs
    UNION ALL SELECT 'library_run_metrics', COUNT(*) FROM library_run_metrics
    UNION ALL SELECT 'analysis_runs', COUNT(*) FROM analysis_runs
    UNION ALL SELECT 'result_metrics', COUNT(*) FROM result_metrics
)
SELECT
    'unexpected_demo_row_count' AS check_name,
    ec.table_name AS record_id,
    'Expected ' || ec.expected_rows || ' rows but found ' || ac.actual_rows || '.' AS issue
FROM expected_counts ec
JOIN actual_counts ac ON ac.table_name = ec.table_name
WHERE ac.actual_rows <> ec.expected_rows
ORDER BY ec.table_name;
