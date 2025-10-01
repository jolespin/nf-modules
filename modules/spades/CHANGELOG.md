# Changelog

All notable changes to this module will be documented in this file.

## [2025.9.1.post1] - 2025-09-01

### Added
- Added `program` input argument which defaults to `spades.py` but also supports other `SPAdes` programs like `metaspades.py` and `rnaspades.py`

### Changed
- Breaks previous usage as 4 arguments are required instead of 3.  Users can use `SPADES(input_ch, hmm, yml, [])` for previous usage
### Fixed

## [2025.9.1] - 2025-09-01

### Added
- Initial release of module
- Includes prefix for fasta files