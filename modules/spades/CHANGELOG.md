# Changelog

All notable changes to this module will be documented in this file.

## v2026.01.22

### Changed
- Changed `${meta.id}.scaffolds.fasta.gz` to `${meta.id}.scaffolds.fa.gz` now that `gtdbtk_classifywf` has an `extension` input

## v2025.10.28

### Changed
- Changed `${meta.id}.scaffolds.fasta.gz` to `${meta.id}.assembly.fa.gz` to be consistent with extension used by `FLYE`

## v2025.09.01.post1

### Added
- Added `program` input argument which defaults to `spades.py` but also supports other `SPAdes` programs like `metaspades.py` and `rnaspades.py`

### Changed
- Breaks previous usage as 4 arguments are required instead of 3.  Users can use `SPADES(input_ch, hmm, yml, [])` for previous usage

## v2025.09.01

### Added
- Initial release of module
- Includes prefix for fasta files
