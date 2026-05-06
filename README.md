# Scientific Data Model

Tool to design a relational schema and implement SQL queries to better structure experimental metadata, sequencing outputs, and analysis results for cross-experiment analysis.

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
|-- README.md
|-- LICENSE
|-- docs/
|   `-- roadmap.md
|-- sql/
|   |-- schema.sql
|   |-- seed_example.sql
|   |-- seed_synthetic_large.sql
|   `-- queries/
|       |-- cross_experiment_summary.sql
|       |-- sample_lineage.sql
|       `-- sequencing_qc.sql
`-- .gitignore
```

## Quick Start

Requirements:

- PostgreSQL server
- PostgreSQL command-line tools: `psql` and `createdb`
- A database role with permission to create databases and tables

Create a PostgreSQL database and load the schema:

```bash
createdb scientific_data_model
psql scientific_data_model -f sql/schema.sql
psql scientific_data_model -f sql/seed_example.sql
```

For a larger synthetic dataset with multiple studies, experiments, samples, sequencing runs, and result metrics, load:

```bash
psql scientific_data_model -f sql/seed_synthetic_large.sql
```

Run an example query:

```bash
psql scientific_data_model -f sql/queries/cross_experiment_summary.sql
```

## WSL/PostgreSQL Notes

If `createdb` or `psql` is missing on Ubuntu/WSL, install the PostgreSQL client tools:

```bash
sudo apt update
sudo apt install postgresql postgresql-client postgresql-client-common
```

Start PostgreSQL:

```bash
sudo service postgresql start
```

If PostgreSQL reports that your Linux user role does not exist, run commands as the default `postgres` role:

```bash
sudo -u postgres createdb scientific_data_model
sudo -u postgres psql scientific_data_model -f sql/schema.sql
```

If the demo database already exists and you want a clean reload:

```bash
sudo -u postgres dropdb --if-exists scientific_data_model
sudo -u postgres createdb scientific_data_model
sudo -u postgres psql scientific_data_model -f sql/schema.sql
sudo -u postgres psql scientific_data_model -f sql/seed_synthetic_large.sql
```

## Model Highlights

- Experiments are grouped under studies.
- Samples can be connected to subjects, source material, protocols, and conditions.
- Sequencing libraries and runs are modeled separately so one library can be sequenced more than once.
- Files are first-class records with checksums, storage locations, formats, and provenance.
- Analysis runs capture workflow identity, version, parameters, inputs, outputs, and metrics.

## Status

In progress. The first milestone is a normalized schema with enough seed data and queries to validate cross-experiment analysis patterns.

## License

MIT License.
