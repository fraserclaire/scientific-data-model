# Scientific Data Model

Relational PostgreSQL model for structuring experimental metadata, sequencing outputs, and downstream analysis results across experiments.

## Purpose

This project is designed to make scientific data easier to compare across studies, assays, samples, sequencing runs, and analysis pipelines. The schema keeps raw experimental context, sequencing outputs, and derived results connected through stable identifiers so cross-experiment analysis can be performed with SQL.

## Current Scope

- Track experiments, studies, protocols, samples, biological material, and experimental conditions.
- Store sequencing runs, libraries, files, quality metrics, and genome/reference metadata.
- Capture analysis workflows, software versions, parameters, result tables, and result-level metrics.
- Provide example SQL queries for cross-experiment comparison and reproducible reporting.

## Repository Layout

```text
.
├── README.md
├── docs/
│   └── roadmap.md
├── sql/
│   ├── schema.sql
│   ├── seed_example.sql
│   └── queries/
│       ├── cross_experiment_summary.sql
│       ├── sample_lineage.sql
│       └── sequencing_qc.sql
└── .gitignore
```

## Quick Start

Create a PostgreSQL database and load the schema:

```bash
createdb scientific_data_model
psql scientific_data_model -f sql/schema.sql
psql scientific_data_model -f sql/seed_example.sql
```

Run an example query:

```bash
psql scientific_data_model -f sql/queries/cross_experiment_summary.sql
```

## Model Highlights

- Experiments are grouped under studies.
- Samples can be connected to subjects, source material, protocols, and conditions.
- Sequencing libraries and runs are modeled separately so one library can be sequenced more than once.
- Files are first-class records with checksums, storage locations, formats, and provenance.
- Analysis runs capture workflow identity, version, parameters, inputs, outputs, and metrics.

## Status

In progress. The first milestone is a normalized schema with enough seed data and queries to validate cross-experiment analysis patterns.
