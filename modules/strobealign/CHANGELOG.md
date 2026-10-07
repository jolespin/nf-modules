# Changelog

All notable changes to this module will be documented in this file.

## v2026.10.07
### Changed
- Changed inputs to `tuple val(meta), path(reads), path(reference)` to handle improper pairing


## v2025.09.05

### Added
- Initial release
- Runs samtools sorted bam, index, and depth if `mode = "bam"`
- Also supports abundance and paf mode
