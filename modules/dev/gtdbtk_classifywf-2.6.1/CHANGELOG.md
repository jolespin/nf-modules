# Changelog

All notable changes to this module will be documented in this file.

## v2026.01.21

### Changed
- Update version from `2.4.1` to `2.6.1`
- Replaced `mash_db` with `skani_sketch_dir`

## v2025.12.04

### Changed
- Moved `classify/${prefix}.taxonomy.tsv.gz` to `${prefix}.taxonomy.tsv.gz` for easier access

## v2025.12.02

### Added
- Initial module
- Added `-depth 3` to search for `GTDB`
- Added `--extension` argument to more easily adapt between assemblers
- Merged classification results into `taxonomy.tsv` (only outputs `${prefix}.taxonomy.tsv` for `summary`)

### Pending
- Update version from `2.4.1` to `2.6.1` when available.  Signficant performance issues with current implementation [GTDB-Tk:issue/#665](https://github.com/Ecogenomics/GTDBtk/issues/665)
