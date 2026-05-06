BEGIN;

SET search_path TO scientific;

INSERT INTO studies (accession, title, description, principal_investigator, institution)
VALUES
    ('SDM-STUDY-001', 'Treatment response pilot', 'Pilot study for cross-condition sequencing analysis.', 'A. Researcher', 'Example Institute');

INSERT INTO experiments (study_id, experiment_code, title, assay_type, objective, started_on)
SELECT study_id, 'EXP-RNA-001', 'RNA-seq treatment response', 'RNA-seq', 'Compare treated and control transcriptional profiles.', DATE '2026-01-15'
FROM studies
WHERE accession = 'SDM-STUDY-001';

INSERT INTO protocols (protocol_name, protocol_type, version, description)
VALUES
    ('RNA extraction standard', 'extraction', '1.0', 'Standard total RNA extraction protocol.'),
    ('Illumina stranded RNA library prep', 'library_preparation', '2.1', 'Stranded RNA-seq library preparation.');

INSERT INTO subjects (external_subject_id, organism, genotype, phenotype)
VALUES
    ('SUBJ-001', 'Homo sapiens', 'wildtype', '{"cohort": "control"}'),
    ('SUBJ-002', 'Homo sapiens', 'wildtype', '{"cohort": "treated"}');

INSERT INTO samples (subject_id, sample_code, sample_type, tissue, collection_timepoint)
SELECT subject_id, 'SAMPLE-CTRL-001', 'RNA', 'blood', 'baseline'
FROM subjects
WHERE external_subject_id = 'SUBJ-001';

INSERT INTO samples (subject_id, sample_code, sample_type, tissue, collection_timepoint)
SELECT subject_id, 'SAMPLE-TRT-001', 'RNA', 'blood', '24h'
FROM subjects
WHERE external_subject_id = 'SUBJ-002';

INSERT INTO experiment_samples (experiment_id, sample_id, protocol_id, role, replicate_number)
SELECT e.experiment_id, s.sample_id, p.protocol_id, 'control', 1
FROM experiments e
JOIN samples s ON s.sample_code = 'SAMPLE-CTRL-001'
JOIN protocols p ON p.protocol_name = 'RNA extraction standard'
WHERE e.experiment_code = 'EXP-RNA-001';

INSERT INTO experiment_samples (experiment_id, sample_id, protocol_id, role, replicate_number)
SELECT e.experiment_id, s.sample_id, p.protocol_id, 'treated', 1
FROM experiments e
JOIN samples s ON s.sample_code = 'SAMPLE-TRT-001'
JOIN protocols p ON p.protocol_name = 'RNA extraction standard'
WHERE e.experiment_code = 'EXP-RNA-001';

INSERT INTO conditions (condition_name, description)
VALUES
    ('treatment', 'Treatment arm or control group.'),
    ('dose', 'Administered dose.');

INSERT INTO sample_conditions (sample_id, condition_id, value_text)
SELECT s.sample_id, c.condition_id, 'control'
FROM samples s
JOIN conditions c ON c.condition_name = 'treatment'
WHERE s.sample_code = 'SAMPLE-CTRL-001';

INSERT INTO sample_conditions (sample_id, condition_id, value_text)
SELECT s.sample_id, c.condition_id, 'compound_a'
FROM samples s
JOIN conditions c ON c.condition_name = 'treatment'
WHERE s.sample_code = 'SAMPLE-TRT-001';

INSERT INTO sequencing_libraries (sample_id, protocol_id, library_code, library_strategy, library_layout, insert_size_bp)
SELECT s.sample_id, p.protocol_id, s.sample_code || '-LIB', 'RNA-Seq', 'paired', 300
FROM samples s
JOIN protocols p ON p.protocol_name = 'Illumina stranded RNA library prep';

INSERT INTO sequencing_runs (run_accession, instrument_platform, instrument_model, run_center, run_started_at)
VALUES
    ('RUN-001', 'Illumina', 'NovaSeq 6000', 'Example Sequencing Core', '2026-01-20 09:00:00-08');

INSERT INTO library_run_metrics (library_id, sequencing_run_id, read_count, base_count, mean_quality, pct_q30, pct_gc)
SELECT l.library_id, r.sequencing_run_id, 42000000, 12600000000, 35.80, 91.20, 48.30
FROM sequencing_libraries l
JOIN sequencing_runs r ON r.run_accession = 'RUN-001'
WHERE l.library_code = 'SAMPLE-CTRL-001-LIB';

INSERT INTO library_run_metrics (library_id, sequencing_run_id, read_count, base_count, mean_quality, pct_q30, pct_gc)
SELECT l.library_id, r.sequencing_run_id, 39500000, 11850000000, 35.10, 89.70, 49.10
FROM sequencing_libraries l
JOIN sequencing_runs r ON r.run_accession = 'RUN-001'
WHERE l.library_code = 'SAMPLE-TRT-001-LIB';

INSERT INTO reference_genomes (organism, build_name, source, uri)
VALUES
    ('Homo sapiens', 'GRCh38', 'GENCODE', 'https://www.gencodegenes.org/human/');

INSERT INTO analysis_workflows (workflow_name, workflow_version, workflow_engine, repository_uri, container_image)
VALUES
    ('rnaseq-expression', '0.1.0', 'Nextflow', 'https://github.com/example/rnaseq-expression', 'example/rnaseq-expression:0.1.0');

INSERT INTO analysis_runs (workflow_id, experiment_id, reference_genome_id, run_code, status, parameters, started_at, completed_at)
SELECT w.workflow_id, e.experiment_id, rg.reference_genome_id, 'ANALYSIS-RNA-001', 'completed',
       '{"aligner": "STAR", "quantifier": "featureCounts"}'::jsonb,
       '2026-01-21 10:00:00-08', '2026-01-21 14:30:00-08'
FROM analysis_workflows w
JOIN experiments e ON e.experiment_code = 'EXP-RNA-001'
JOIN reference_genomes rg ON rg.build_name = 'GRCh38'
WHERE w.workflow_name = 'rnaseq-expression';

INSERT INTO result_metrics (analysis_run_id, sample_id, metric_name, metric_value, unit)
SELECT ar.analysis_run_id, s.sample_id, 'mapped_reads_pct', 94.2, 'percent'
FROM analysis_runs ar
JOIN samples s ON s.sample_code = 'SAMPLE-CTRL-001'
WHERE ar.run_code = 'ANALYSIS-RNA-001';

INSERT INTO result_metrics (analysis_run_id, sample_id, metric_name, metric_value, unit)
SELECT ar.analysis_run_id, s.sample_id, 'mapped_reads_pct', 93.5, 'percent'
FROM analysis_runs ar
JOIN samples s ON s.sample_code = 'SAMPLE-TRT-001'
WHERE ar.run_code = 'ANALYSIS-RNA-001';

COMMIT;
