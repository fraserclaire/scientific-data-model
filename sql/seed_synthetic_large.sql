BEGIN;

SET search_path TO scientific;

INSERT INTO studies (accession, title, description, principal_investigator, institution)
VALUES
    ('SDM-STUDY-101', 'Synthetic RNA-seq treatment atlas', 'Synthetic dataset for testing cross-experiment RNA-seq metadata queries.', 'Claire Fraser', 'Example Institute'),
    ('SDM-STUDY-102', 'Synthetic sequencing QC benchmark', 'Synthetic dataset for comparing sequencing QC across instruments and batches.', 'Claire Fraser', 'Example Institute')
ON CONFLICT (accession) DO NOTHING;

INSERT INTO protocols (protocol_name, protocol_type, version, description)
VALUES
    ('Synthetic RNA extraction', 'extraction', '1.0', 'Synthetic extraction protocol for demo data.'),
    ('Synthetic stranded RNA library prep', 'library_preparation', '1.0', 'Synthetic RNA-seq library protocol.'),
    ('Synthetic differential expression workflow', 'analysis', '1.0', 'Synthetic workflow for expression analysis.')
ON CONFLICT (protocol_name, version) DO NOTHING;

INSERT INTO conditions (condition_name, description)
VALUES
    ('treatment', 'Treatment arm or control group.'),
    ('dose', 'Synthetic dose level.'),
    ('batch', 'Synthetic processing batch.')
ON CONFLICT (condition_name) DO NOTHING;

INSERT INTO reference_genomes (organism, build_name, source, uri)
VALUES
    ('Homo sapiens', 'GRCh38', 'GENCODE', 'https://www.gencodegenes.org/human/')
ON CONFLICT (organism, build_name) DO NOTHING;

INSERT INTO analysis_workflows (workflow_name, workflow_version, workflow_engine, repository_uri, container_image)
VALUES
    ('synthetic-rnaseq-expression', '1.0.0', 'Nextflow', 'https://github.com/fraserclaire/scientific-data-model', 'scientific-data-model/synthetic-rnaseq:1.0.0')
ON CONFLICT (workflow_name, workflow_version) DO NOTHING;

WITH experiment_plan AS (
    SELECT *
    FROM (
        VALUES
            ('SDM-STUDY-101', 'EXP-RNA-101', 'Synthetic RNA-seq baseline response', 'RNA-seq', 'Compare baseline response by treatment.', DATE '2026-01-10'),
            ('SDM-STUDY-101', 'EXP-RNA-102', 'Synthetic RNA-seq dose response', 'RNA-seq', 'Compare dose response across treatment arms.', DATE '2026-02-14'),
            ('SDM-STUDY-102', 'EXP-RNA-201', 'Synthetic RNA-seq batch benchmark', 'RNA-seq', 'Compare sequencing quality across batches.', DATE '2026-03-20')
    ) AS planned(study_accession, experiment_code, title, assay_type, objective, started_on)
)
INSERT INTO experiments (study_id, experiment_code, title, assay_type, objective, started_on)
SELECT st.study_id, ep.experiment_code, ep.title, ep.assay_type, ep.objective, ep.started_on
FROM experiment_plan ep
JOIN studies st ON st.accession = ep.study_accession
ON CONFLICT (study_id, experiment_code) DO NOTHING;

WITH sample_plan AS (
    SELECT
        e.experiment_id,
        e.experiment_code,
        gs.replicate_number,
        treatment.value_text AS treatment,
        dose.value_numeric AS dose,
        batch.value_text AS batch,
        format('%s-%s-R%02s', e.experiment_code, upper(left(treatment.value_text, 3)), gs.replicate_number) AS sample_code,
        format('SUBJ-%s-%s-R%02s', e.experiment_code, upper(left(treatment.value_text, 3)), gs.replicate_number) AS external_subject_id
    FROM experiments e
    CROSS JOIN generate_series(1, 8) AS gs(replicate_number)
    CROSS JOIN LATERAL (
        SELECT CASE WHEN gs.replicate_number <= 4 THEN 'control' ELSE 'compound_a' END AS value_text
    ) treatment
    CROSS JOIN LATERAL (
        SELECT CASE
            WHEN e.experiment_code = 'EXP-RNA-102' AND gs.replicate_number > 4 THEN 10
            WHEN e.experiment_code = 'EXP-RNA-102' THEN 0
            WHEN gs.replicate_number > 4 THEN 5
            ELSE 0
        END::numeric AS value_numeric
    ) dose
    CROSS JOIN LATERAL (
        SELECT CASE WHEN gs.replicate_number IN (1, 2, 5, 6) THEN 'batch_a' ELSE 'batch_b' END AS value_text
    ) batch
    WHERE e.experiment_code IN ('EXP-RNA-101', 'EXP-RNA-102', 'EXP-RNA-201')
),
inserted_subjects AS (
    INSERT INTO subjects (external_subject_id, organism, genotype, phenotype, attributes)
    SELECT
        sp.external_subject_id,
        'Homo sapiens',
        'synthetic',
        jsonb_build_object('treatment_group', sp.treatment),
        jsonb_build_object('source', 'synthetic_large_seed')
    FROM sample_plan sp
    ON CONFLICT (external_subject_id) DO NOTHING
    RETURNING subject_id, external_subject_id
),
subject_lookup AS (
    SELECT subject_id, external_subject_id FROM inserted_subjects
    UNION
    SELECT subject_id, external_subject_id
    FROM subjects
    WHERE external_subject_id IN (SELECT external_subject_id FROM sample_plan)
),
inserted_samples AS (
    INSERT INTO samples (subject_id, sample_code, sample_type, tissue, collection_timepoint, metadata)
    SELECT
        sl.subject_id,
        sp.sample_code,
        'RNA',
        CASE WHEN sp.experiment_code = 'EXP-RNA-201' THEN 'PBMC' ELSE 'blood' END,
        CASE WHEN sp.treatment = 'control' THEN 'baseline' ELSE '24h' END,
        jsonb_build_object('source', 'synthetic_large_seed', 'experiment_code', sp.experiment_code)
    FROM sample_plan sp
    JOIN subject_lookup sl ON sl.external_subject_id = sp.external_subject_id
    ON CONFLICT (sample_code) DO NOTHING
    RETURNING sample_id, sample_code
),
sample_lookup AS (
    SELECT sample_id, sample_code FROM inserted_samples
    UNION
    SELECT sample_id, sample_code
    FROM samples
    WHERE sample_code IN (SELECT sample_code FROM sample_plan)
)
INSERT INTO experiment_samples (experiment_id, sample_id, protocol_id, role, replicate_number)
SELECT
    sp.experiment_id,
    s.sample_id,
    p.protocol_id,
    sp.treatment,
    sp.replicate_number
FROM sample_plan sp
JOIN sample_lookup s ON s.sample_code = sp.sample_code
JOIN protocols p ON p.protocol_name = 'Synthetic RNA extraction'
ON CONFLICT (experiment_id, sample_id) DO NOTHING;

INSERT INTO sample_conditions (sample_id, condition_id, value_text)
SELECT s.sample_id, c.condition_id, sp.treatment
FROM (
    SELECT
        format('%s-%s-R%02s', e.experiment_code, upper(left(CASE WHEN gs.replicate_number <= 4 THEN 'control' ELSE 'compound_a' END, 3)), gs.replicate_number) AS sample_code,
        CASE WHEN gs.replicate_number <= 4 THEN 'control' ELSE 'compound_a' END AS treatment
    FROM experiments e
    CROSS JOIN generate_series(1, 8) AS gs(replicate_number)
    WHERE e.experiment_code IN ('EXP-RNA-101', 'EXP-RNA-102', 'EXP-RNA-201')
) sp
JOIN samples s ON s.sample_code = sp.sample_code
JOIN conditions c ON c.condition_name = 'treatment'
ON CONFLICT (sample_id, condition_id) DO NOTHING;

INSERT INTO sample_conditions (sample_id, condition_id, value_numeric, unit)
SELECT s.sample_id, c.condition_id, sp.dose, 'mg'
FROM (
    SELECT
        format('%s-%s-R%02s', e.experiment_code, upper(left(CASE WHEN gs.replicate_number <= 4 THEN 'control' ELSE 'compound_a' END, 3)), gs.replicate_number) AS sample_code,
        CASE
            WHEN e.experiment_code = 'EXP-RNA-102' AND gs.replicate_number > 4 THEN 10
            WHEN e.experiment_code = 'EXP-RNA-102' THEN 0
            WHEN gs.replicate_number > 4 THEN 5
            ELSE 0
        END::numeric AS dose
    FROM experiments e
    CROSS JOIN generate_series(1, 8) AS gs(replicate_number)
    WHERE e.experiment_code IN ('EXP-RNA-101', 'EXP-RNA-102', 'EXP-RNA-201')
) sp
JOIN samples s ON s.sample_code = sp.sample_code
JOIN conditions c ON c.condition_name = 'dose'
ON CONFLICT (sample_id, condition_id) DO NOTHING;

INSERT INTO sample_conditions (sample_id, condition_id, value_text)
SELECT s.sample_id, c.condition_id, sp.batch
FROM (
    SELECT
        format('%s-%s-R%02s', e.experiment_code, upper(left(CASE WHEN gs.replicate_number <= 4 THEN 'control' ELSE 'compound_a' END, 3)), gs.replicate_number) AS sample_code,
        CASE WHEN gs.replicate_number IN (1, 2, 5, 6) THEN 'batch_a' ELSE 'batch_b' END AS batch
    FROM experiments e
    CROSS JOIN generate_series(1, 8) AS gs(replicate_number)
    WHERE e.experiment_code IN ('EXP-RNA-101', 'EXP-RNA-102', 'EXP-RNA-201')
) sp
JOIN samples s ON s.sample_code = sp.sample_code
JOIN conditions c ON c.condition_name = 'batch'
ON CONFLICT (sample_id, condition_id) DO NOTHING;

INSERT INTO sequencing_libraries (sample_id, protocol_id, library_code, library_strategy, library_layout, insert_size_bp)
SELECT
    s.sample_id,
    p.protocol_id,
    s.sample_code || '-LIB',
    'RNA-Seq',
    'paired',
    280 + ((row_number() OVER (ORDER BY s.sample_code)) % 5) * 10
FROM samples s
JOIN protocols p ON p.protocol_name = 'Synthetic stranded RNA library prep'
WHERE s.metadata ->> 'source' = 'synthetic_large_seed'
ON CONFLICT (library_code) DO NOTHING;

INSERT INTO sequencing_runs (run_accession, instrument_platform, instrument_model, run_center, run_started_at, run_completed_at)
VALUES
    ('SYN-RUN-001', 'Illumina', 'NovaSeq 6000', 'Synthetic Core', '2026-01-20 09:00:00-08', '2026-01-20 20:00:00-08'),
    ('SYN-RUN-002', 'Illumina', 'NextSeq 2000', 'Synthetic Core', '2026-02-21 09:00:00-08', '2026-02-21 18:00:00-08'),
    ('SYN-RUN-003', 'Illumina', 'NovaSeq X Plus', 'Synthetic Core', '2026-03-27 09:00:00-08', '2026-03-27 21:00:00-08')
ON CONFLICT (run_accession) DO NOTHING;

WITH library_plan AS (
    SELECT
        l.library_id,
        s.sample_code,
        CASE
            WHEN s.sample_code LIKE 'EXP-RNA-101%' THEN 'SYN-RUN-001'
            WHEN s.sample_code LIKE 'EXP-RNA-102%' THEN 'SYN-RUN-002'
            ELSE 'SYN-RUN-003'
        END AS run_accession,
        row_number() OVER (ORDER BY s.sample_code) AS rn
    FROM sequencing_libraries l
    JOIN samples s ON s.sample_id = l.sample_id
    WHERE s.metadata ->> 'source' = 'synthetic_large_seed'
)
INSERT INTO library_run_metrics (library_id, sequencing_run_id, read_count, base_count, mean_quality, pct_q30, pct_gc)
SELECT
    lp.library_id,
    sr.sequencing_run_id,
    28000000 + (lp.rn * 950000),
    (28000000 + (lp.rn * 950000)) * 150,
    33.50 + ((lp.rn % 7) * 0.35),
    86.00 + ((lp.rn % 8) * 1.20),
    45.00 + ((lp.rn % 6) * 0.90)
FROM library_plan lp
JOIN sequencing_runs sr ON sr.run_accession = lp.run_accession
ON CONFLICT (library_id, sequencing_run_id) DO NOTHING;

WITH analysis_plan AS (
    SELECT
        e.experiment_id,
        e.experiment_code,
        w.workflow_id,
        rg.reference_genome_id
    FROM experiments e
    JOIN analysis_workflows w ON w.workflow_name = 'synthetic-rnaseq-expression'
    JOIN reference_genomes rg ON rg.organism = 'Homo sapiens' AND rg.build_name = 'GRCh38'
    WHERE e.experiment_code IN ('EXP-RNA-101', 'EXP-RNA-102', 'EXP-RNA-201')
)
INSERT INTO analysis_runs (workflow_id, experiment_id, reference_genome_id, run_code, status, parameters, started_at, completed_at)
SELECT
    workflow_id,
    experiment_id,
    reference_genome_id,
    experiment_code || '-ANALYSIS',
    'completed',
    jsonb_build_object('aligner', 'STAR', 'quantifier', 'featureCounts', 'dataset', 'synthetic_large_seed'),
    '2026-04-01 10:00:00-08',
    '2026-04-01 15:00:00-08'
FROM analysis_plan
ON CONFLICT (run_code) DO NOTHING;

WITH metric_plan AS (
    SELECT
        ar.analysis_run_id,
        s.sample_id,
        s.sample_code,
        row_number() OVER (ORDER BY s.sample_code) AS rn,
        CASE WHEN s.sample_code LIKE '%-COM-%' THEN 1 ELSE 0 END AS treated_flag
    FROM analysis_runs ar
    JOIN experiments e ON e.experiment_id = ar.experiment_id
    JOIN experiment_samples es ON es.experiment_id = e.experiment_id
    JOIN samples s ON s.sample_id = es.sample_id
    WHERE ar.run_code LIKE 'EXP-RNA-%-ANALYSIS'
)
INSERT INTO result_metrics (analysis_run_id, sample_id, metric_name, metric_value, unit, attributes)
SELECT analysis_run_id, sample_id, 'mapped_reads_pct', 90.0 + (rn % 8) + treated_flag * 0.8, 'percent', jsonb_build_object('source', 'synthetic_large_seed')
FROM metric_plan
UNION ALL
SELECT analysis_run_id, sample_id, 'expressed_genes', 14500 + (rn * 73) + treated_flag * 280, 'genes', jsonb_build_object('source', 'synthetic_large_seed')
FROM metric_plan
UNION ALL
SELECT analysis_run_id, sample_id, 'mitochondrial_reads_pct', 3.2 + (rn % 5) * 0.4 - treated_flag * 0.2, 'percent', jsonb_build_object('source', 'synthetic_large_seed')
FROM metric_plan;

COMMIT;
