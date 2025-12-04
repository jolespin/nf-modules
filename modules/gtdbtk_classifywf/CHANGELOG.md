# Changelog

All notable changes to this module will be documented in this file.

## v2025.12.2 - 2025-12-2

### Added
* Initial module
* Added `-depth 3` to search for `GTDB`
* Added `--extension` argument to more easily adapt between assemblers
* Merged classification results into `taxonomy.tsv` (only outputs `${prefix}.taxonomy.tsv` for `summary`)

### Pending:
* Update version from `2.4.1` to `2.5.3` when available.  Signficant performance issues with current implementation [GTDB-Tk:issue/#665](https://github.com/Ecogenomics/GTDBtk/issues/665)