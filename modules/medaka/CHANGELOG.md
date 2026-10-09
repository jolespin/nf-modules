# Changelog

All notable changes to this module will be documented in this file.

## v2026.10.09

### Added
- Model selection support: pass `"auto"` for automatic basecalling model detection from reads, or specify an explicit medaka model name
- When auto-detection fails, prints all available medaka models and exits with error

### Fixed
- `model` input parameter was declared but never passed to `medaka_consensus`
- `cleanup_cmd` for removing decompressed temp files was defined but never invoked

## v2026.01.22

### Changed
- Changed `${meta.id}.fa.gz` to `${meta.id}.medaka.fa.gz` now that `gtdbtk_classifywf` has an `extension` input

## v2025.12.09

### Added
- Initial release of module
- Automatically handles decompression
