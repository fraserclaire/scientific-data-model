# Roadmap

## Milestone 1: Core Relational Model

- Define normalized entities for studies, experiments, protocols, samples, sequencing libraries, sequencing runs, files, and analysis runs.
- Add constraints and indexes for common joins and lookups.
- Include realistic seed data for smoke testing.

## Milestone 2: Cross-Experiment Queries

- Summarize experiments by assay, condition, organism, and reference genome.
- Compare sequencing quality metrics across runs and instruments.
- Trace sample-to-result lineage from source material through derived analysis output.

## Milestone 3: Reproducibility Metadata

- Record pipeline versions, software tools, parameter JSON, container images, and workflow engine metadata.
- Track result provenance through analysis input and output file links.
- Add validation queries for missing provenance.

## Milestone 4: Packaging

- Add migration tooling.
- Add automated database tests.
- Add ERD documentation.
- Prepare sample dashboards or views for common scientific questions.
