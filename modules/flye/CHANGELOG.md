# Changelog

All notable changes to this module will be documented in this file.

## v2026.10.07
### Changed
- Removed automatic `${meta.id}__` prefixing in favor of using `PREPEND_PREFIX_TO_FASTA_HEADERS` from `nf_utils` module

## v2025.10.28

### Changed
- Changed `${meta.id}.assembly.fasta.gz` to `${meta.id}.assembly.fa.gz` to be consistent with extension used by `SPAdes`

## v2025.09.01

### Added
- Initial release of module
- Adds "${meta.id}__" as prefix to all fasta in output
