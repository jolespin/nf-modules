# Changelog

All notable changes to this module will be documented in this file.

## v2026.5.13

### Changed
- Updated GTDB-Tk from 2.4.1 to 2.7.2
- Updated container to use Seqera community Wave containers
- Changed label from `process_high` to `process_high_memory`

### Removed
- Removed `mash_db` input (no longer needed in GTDB-Tk 2.7.x)
- Removed `--mash_db` / `--skip_ani_screen` flags

## v2026.5.6

### Added
- `GTDBTK_CLASSIFYWF_WITH_STAGING` process: stages genomes as `${genome_id}__GTDB-Tk_staging.${extension}` before classification, then removes the staging suffix from output file contents (taxonomy, tree, markers, MSA, filtered, and failed genomes)

## v2025.12.04

### Changed
- Moved `classify/${prefix}.taxonomy.tsv.gz` to `${prefix}.taxonomy.tsv.gz` for easier access

## v2025.12.02

### Added
- Initial module
- Added `-depth 3` to search for `GTDB`
- Added `--extension` argument to more easily adapt between assemblers
- Merged classification results into `taxonomy.tsv` (only outputs `${prefix}.taxonomy.tsv` for `summary`)
