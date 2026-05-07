SET search_path TO scientific;

SELECT
    'libraries_without_run_metrics' AS check_name,
    l.library_code AS record_id,
    'Sequencing library has no linked run-level QC metrics.' AS issue
FROM sequencing_libraries l
LEFT JOIN library_run_metrics lrm ON lrm.library_id = l.library_id
WHERE lrm.library_id IS NULL
ORDER BY l.library_code;

SELECT
    'run_metrics_missing_read_count' AS check_name,
    l.library_code || ':' || sr.run_accession AS record_id,
    'Library/run metric is missing read_count.' AS issue
FROM library_run_metrics lrm
JOIN sequencing_libraries l ON l.library_id = lrm.library_id
JOIN sequencing_runs sr ON sr.sequencing_run_id = lrm.sequencing_run_id
WHERE lrm.read_count IS NULL
ORDER BY l.library_code, sr.run_accession;

SELECT
    'run_metrics_outside_expected_qc_ranges' AS check_name,
    l.library_code || ':' || sr.run_accession AS record_id,
    'One or more QC values are outside expected percentage/quality ranges.' AS issue
FROM library_run_metrics lrm
JOIN sequencing_libraries l ON l.library_id = lrm.library_id
JOIN sequencing_runs sr ON sr.sequencing_run_id = lrm.sequencing_run_id
WHERE lrm.mean_quality < 0
   OR lrm.pct_q30 < 0 OR lrm.pct_q30 > 100
   OR lrm.pct_gc < 0 OR lrm.pct_gc > 100
ORDER BY l.library_code, sr.run_accession;

SELECT
    'sequencing_runs_without_libraries' AS check_name,
    sr.run_accession AS record_id,
    'Sequencing run has no libraries linked through library_run_metrics.' AS issue
FROM sequencing_runs sr
LEFT JOIN library_run_metrics lrm ON lrm.sequencing_run_id = sr.sequencing_run_id
WHERE lrm.sequencing_run_id IS NULL
ORDER BY sr.run_accession;
