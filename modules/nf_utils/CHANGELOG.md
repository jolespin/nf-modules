# Changelog

All notable changes to this module will be documented in this file.

## [2026.10.7] - 2026-10-07
### Added
- Initial release of nf_utils module
- `PREPEND_PREFIX_TO_FASTA_HEADERS` process (migrated from `prefix_contigs` module)
  - Configurable `delimiter` input (default: `__`)
  - Supports both gzipped and uncompressed FASTA input
  - Preserves original filename and extension in output
