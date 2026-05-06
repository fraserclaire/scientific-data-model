SET search_path TO scientific;

SELECT
    st.accession AS study_accession,
    e.experiment_code,
    e.assay_type,
    c.condition_name,
    COALESCE(sc.value_text, sc.value_numeric::text) AS condition_value,
    COUNT(DISTINCT s.sample_id) AS sample_count,
    COUNT(DISTINCT l.library_id) AS library_count,
    ROUND(AVG(lrm.read_count)::numeric, 2) AS avg_reads_per_library,
    ROUND(AVG(rm.metric_value) FILTER (WHERE rm.metric_name = 'mapped_reads_pct'), 2) AS avg_mapped_reads_pct
FROM studies st
JOIN experiments e ON e.study_id = st.study_id
JOIN experiment_samples es ON es.experiment_id = e.experiment_id
JOIN samples s ON s.sample_id = es.sample_id
LEFT JOIN sample_conditions sc ON sc.sample_id = s.sample_id
LEFT JOIN conditions c ON c.condition_id = sc.condition_id
LEFT JOIN sequencing_libraries l ON l.sample_id = s.sample_id
LEFT JOIN library_run_metrics lrm ON lrm.library_id = l.library_id
LEFT JOIN analysis_runs ar ON ar.experiment_id = e.experiment_id
LEFT JOIN result_metrics rm ON rm.analysis_run_id = ar.analysis_run_id
    AND rm.sample_id = s.sample_id
GROUP BY st.accession, e.experiment_code, e.assay_type, c.condition_name, condition_value
ORDER BY st.accession, e.experiment_code, c.condition_name, condition_value;
