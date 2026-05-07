SET search_path TO scientific;

SELECT
    'completed_analysis_without_reference_genome' AS check_name,
    ar.run_code AS record_id,
    'Completed analysis run is missing a reference genome.' AS issue
FROM analysis_runs ar
WHERE ar.status = 'completed'
  AND ar.reference_genome_id IS NULL
ORDER BY ar.run_code;

SELECT
    'completed_analysis_without_result_metrics' AS check_name,
    ar.run_code AS record_id,
    'Completed analysis run has no result metrics.' AS issue
FROM analysis_runs ar
LEFT JOIN result_metrics rm ON rm.analysis_run_id = ar.analysis_run_id
WHERE ar.status = 'completed'
  AND rm.analysis_run_id IS NULL
ORDER BY ar.run_code;

SELECT
    'result_metrics_without_sample' AS check_name,
    rm.result_metric_id::text AS record_id,
    'Result metric is not linked to a sample.' AS issue
FROM result_metrics rm
WHERE rm.sample_id IS NULL
ORDER BY rm.result_metric_id;

SELECT
    'completed_analysis_without_input_files' AS check_name,
    ar.run_code AS record_id,
    'Completed analysis run has no input files recorded in analysis_inputs.' AS issue
FROM analysis_runs ar
LEFT JOIN analysis_inputs ai ON ai.analysis_run_id = ar.analysis_run_id
WHERE ar.status = 'completed'
  AND ai.analysis_run_id IS NULL
ORDER BY ar.run_code;

SELECT
    'completed_analysis_without_output_files' AS check_name,
    ar.run_code AS record_id,
    'Completed analysis run has no output files recorded in analysis_outputs.' AS issue
FROM analysis_runs ar
LEFT JOIN analysis_outputs ao ON ao.analysis_run_id = ar.analysis_run_id
WHERE ar.status = 'completed'
  AND ao.analysis_run_id IS NULL
ORDER BY ar.run_code;
