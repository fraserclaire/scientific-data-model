SET search_path TO scientific;

SELECT
    s.sample_code,
    subj.external_subject_id,
    subj.organism,
    e.experiment_code,
    l.library_code,
    sr.run_accession,
    ar.run_code AS analysis_run,
    aw.workflow_name,
    aw.workflow_version,
    rm.metric_name,
    rm.metric_value,
    rm.unit
FROM samples s
LEFT JOIN subjects subj ON subj.subject_id = s.subject_id
LEFT JOIN experiment_samples es ON es.sample_id = s.sample_id
LEFT JOIN experiments e ON e.experiment_id = es.experiment_id
LEFT JOIN sequencing_libraries l ON l.sample_id = s.sample_id
LEFT JOIN library_run_metrics lrm ON lrm.library_id = l.library_id
LEFT JOIN sequencing_runs sr ON sr.sequencing_run_id = lrm.sequencing_run_id
LEFT JOIN analysis_runs ar ON ar.experiment_id = e.experiment_id
LEFT JOIN analysis_workflows aw ON aw.workflow_id = ar.workflow_id
LEFT JOIN result_metrics rm ON rm.analysis_run_id = ar.analysis_run_id
    AND rm.sample_id = s.sample_id
ORDER BY s.sample_code, e.experiment_code, l.library_code, ar.run_code, rm.metric_name;
