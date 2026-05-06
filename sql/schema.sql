BEGIN;

CREATE SCHEMA IF NOT EXISTS scientific;
SET search_path TO scientific;

CREATE TABLE studies (
    study_id BIGSERIAL PRIMARY KEY,
    accession TEXT UNIQUE,
    title TEXT NOT NULL,
    description TEXT,
    principal_investigator TEXT,
    institution TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE experiments (
    experiment_id BIGSERIAL PRIMARY KEY,
    study_id BIGINT NOT NULL REFERENCES studies(study_id) ON DELETE CASCADE,
    experiment_code TEXT NOT NULL,
    title TEXT NOT NULL,
    assay_type TEXT NOT NULL,
    objective TEXT,
    started_on DATE,
    completed_on DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (study_id, experiment_code)
);

CREATE TABLE protocols (
    protocol_id BIGSERIAL PRIMARY KEY,
    protocol_name TEXT NOT NULL,
    protocol_type TEXT NOT NULL,
    version TEXT,
    description TEXT,
    uri TEXT,
    UNIQUE (protocol_name, version)
);

CREATE TABLE subjects (
    subject_id BIGSERIAL PRIMARY KEY,
    external_subject_id TEXT UNIQUE,
    organism TEXT NOT NULL,
    genotype TEXT,
    phenotype JSONB NOT NULL DEFAULT '{}'::jsonb,
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE samples (
    sample_id BIGSERIAL PRIMARY KEY,
    subject_id BIGINT REFERENCES subjects(subject_id) ON DELETE SET NULL,
    sample_code TEXT NOT NULL UNIQUE,
    sample_type TEXT NOT NULL,
    tissue TEXT,
    collection_timepoint TEXT,
    collected_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE experiment_samples (
    experiment_id BIGINT NOT NULL REFERENCES experiments(experiment_id) ON DELETE CASCADE,
    sample_id BIGINT NOT NULL REFERENCES samples(sample_id) ON DELETE CASCADE,
    protocol_id BIGINT REFERENCES protocols(protocol_id) ON DELETE SET NULL,
    role TEXT NOT NULL DEFAULT 'experimental',
    replicate_number INTEGER CHECK (replicate_number IS NULL OR replicate_number > 0),
    PRIMARY KEY (experiment_id, sample_id)
);

CREATE TABLE conditions (
    condition_id BIGSERIAL PRIMARY KEY,
    condition_name TEXT NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE sample_conditions (
    sample_id BIGINT NOT NULL REFERENCES samples(sample_id) ON DELETE CASCADE,
    condition_id BIGINT NOT NULL REFERENCES conditions(condition_id) ON DELETE CASCADE,
    value_text TEXT,
    value_numeric NUMERIC,
    unit TEXT,
    PRIMARY KEY (sample_id, condition_id)
);

CREATE TABLE sequencing_libraries (
    library_id BIGSERIAL PRIMARY KEY,
    sample_id BIGINT NOT NULL REFERENCES samples(sample_id) ON DELETE CASCADE,
    protocol_id BIGINT REFERENCES protocols(protocol_id) ON DELETE SET NULL,
    library_code TEXT NOT NULL UNIQUE,
    library_strategy TEXT NOT NULL,
    library_layout TEXT NOT NULL CHECK (library_layout IN ('single', 'paired')),
    insert_size_bp INTEGER CHECK (insert_size_bp IS NULL OR insert_size_bp > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sequencing_runs (
    sequencing_run_id BIGSERIAL PRIMARY KEY,
    run_accession TEXT UNIQUE,
    instrument_platform TEXT NOT NULL,
    instrument_model TEXT,
    run_center TEXT,
    run_started_at TIMESTAMPTZ,
    run_completed_at TIMESTAMPTZ
);

CREATE TABLE library_run_metrics (
    library_id BIGINT NOT NULL REFERENCES sequencing_libraries(library_id) ON DELETE CASCADE,
    sequencing_run_id BIGINT NOT NULL REFERENCES sequencing_runs(sequencing_run_id) ON DELETE CASCADE,
    read_count BIGINT CHECK (read_count IS NULL OR read_count >= 0),
    base_count BIGINT CHECK (base_count IS NULL OR base_count >= 0),
    mean_quality NUMERIC(5,2),
    pct_q30 NUMERIC(5,2),
    pct_gc NUMERIC(5,2),
    PRIMARY KEY (library_id, sequencing_run_id)
);

CREATE TABLE reference_genomes (
    reference_genome_id BIGSERIAL PRIMARY KEY,
    organism TEXT NOT NULL,
    build_name TEXT NOT NULL,
    source TEXT,
    uri TEXT,
    UNIQUE (organism, build_name)
);

CREATE TABLE data_files (
    file_id BIGSERIAL PRIMARY KEY,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_format TEXT NOT NULL,
    storage_uri TEXT NOT NULL UNIQUE,
    checksum_sha256 TEXT,
    size_bytes BIGINT CHECK (size_bytes IS NULL OR size_bytes >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE library_files (
    library_id BIGINT NOT NULL REFERENCES sequencing_libraries(library_id) ON DELETE CASCADE,
    file_id BIGINT NOT NULL REFERENCES data_files(file_id) ON DELETE CASCADE,
    file_role TEXT NOT NULL,
    PRIMARY KEY (library_id, file_id)
);

CREATE TABLE analysis_workflows (
    workflow_id BIGSERIAL PRIMARY KEY,
    workflow_name TEXT NOT NULL,
    workflow_version TEXT NOT NULL,
    workflow_engine TEXT,
    repository_uri TEXT,
    container_image TEXT,
    UNIQUE (workflow_name, workflow_version)
);

CREATE TABLE analysis_runs (
    analysis_run_id BIGSERIAL PRIMARY KEY,
    workflow_id BIGINT NOT NULL REFERENCES analysis_workflows(workflow_id) ON DELETE RESTRICT,
    experiment_id BIGINT REFERENCES experiments(experiment_id) ON DELETE SET NULL,
    reference_genome_id BIGINT REFERENCES reference_genomes(reference_genome_id) ON DELETE SET NULL,
    run_code TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL CHECK (status IN ('planned', 'running', 'completed', 'failed')),
    parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

CREATE TABLE analysis_inputs (
    analysis_run_id BIGINT NOT NULL REFERENCES analysis_runs(analysis_run_id) ON DELETE CASCADE,
    file_id BIGINT NOT NULL REFERENCES data_files(file_id) ON DELETE RESTRICT,
    input_role TEXT NOT NULL,
    PRIMARY KEY (analysis_run_id, file_id, input_role)
);

CREATE TABLE analysis_outputs (
    analysis_run_id BIGINT NOT NULL REFERENCES analysis_runs(analysis_run_id) ON DELETE CASCADE,
    file_id BIGINT NOT NULL REFERENCES data_files(file_id) ON DELETE RESTRICT,
    output_role TEXT NOT NULL,
    PRIMARY KEY (analysis_run_id, file_id, output_role)
);

CREATE TABLE result_metrics (
    result_metric_id BIGSERIAL PRIMARY KEY,
    analysis_run_id BIGINT NOT NULL REFERENCES analysis_runs(analysis_run_id) ON DELETE CASCADE,
    sample_id BIGINT REFERENCES samples(sample_id) ON DELETE SET NULL,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC,
    metric_text TEXT,
    unit TEXT,
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb,
    CHECK (metric_value IS NOT NULL OR metric_text IS NOT NULL)
);

CREATE INDEX idx_experiments_study ON experiments(study_id);
CREATE INDEX idx_samples_subject ON samples(subject_id);
CREATE INDEX idx_experiment_samples_sample ON experiment_samples(sample_id);
CREATE INDEX idx_sample_conditions_condition ON sample_conditions(condition_id);
CREATE INDEX idx_libraries_sample ON sequencing_libraries(sample_id);
CREATE INDEX idx_library_run_metrics_run ON library_run_metrics(sequencing_run_id);
CREATE INDEX idx_analysis_runs_experiment ON analysis_runs(experiment_id);
CREATE INDEX idx_result_metrics_sample_metric ON result_metrics(sample_id, metric_name);
CREATE INDEX idx_result_metrics_run ON result_metrics(analysis_run_id);

COMMIT;
