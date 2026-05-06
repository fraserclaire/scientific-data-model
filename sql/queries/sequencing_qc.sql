SET search_path TO scientific;

SELECT
    sr.run_accession,
    sr.instrument_platform,
    sr.instrument_model,
    l.library_strategy,
    l.library_layout,
    COUNT(*) AS libraries,
    ROUND(AVG(lrm.read_count)::numeric, 2) AS avg_read_count,
    ROUND(AVG(lrm.mean_quality), 2) AS avg_mean_quality,
    ROUND(AVG(lrm.pct_q30), 2) AS avg_pct_q30,
    ROUND(AVG(lrm.pct_gc), 2) AS avg_pct_gc
FROM sequencing_runs sr
JOIN library_run_metrics lrm ON lrm.sequencing_run_id = sr.sequencing_run_id
JOIN sequencing_libraries l ON l.library_id = lrm.library_id
GROUP BY sr.run_accession, sr.instrument_platform, sr.instrument_model, l.library_strategy, l.library_layout
ORDER BY sr.run_accession, l.library_strategy, l.library_layout;
