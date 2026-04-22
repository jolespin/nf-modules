# Changelog

All notable changes to this module will be documented in this file.

## v2026.03.26

### Added
- Added `--estimate-unknown`
- Added `--debug` to track progress more easily

## v2026.03.02

### Changed
- Added `${prefix}` to fastq files during staging instead of using original filenames (e.g., `S1_1.fastq.gz` and `S1_2.fastq.gz` instead of `reads_1.fastq.gz` and `reads_2.fastq.gz`)

## v2026.01.21

### Changed
- Changed `tuple val(batch_meta), val(sample_metas), path(r1_reads), path(r2_reads)` to `tuple val(batch_meta), val(sample_metas), path(reads)` in `SYLPH_PROFILE_MANY` and `SYLPH_PROFILE_MANY_WITH_TAXONOMY`

## v2026.01.20

### Added
- Initial release
- Adds `Sample` column
- Contains 4 `nextflow` processes:
    - `SYLPH_PROFILE` - Use when there are many samples and small-ish databases
    - `SYLPH_PROFILE_MANY` - Use when there are large databases (e.g., `GlobDB`)
    - `SYLPH_PROFILE_WITH_TAXONOMY` - Use when there are many samples and small-ish databases.  Must provide taxonomy mappings.
    - `SYLPH_PROFILE_MANY_WITH_TAXONOMY` - Use when there are large databases (e.g., `GlobDB`).  Must provide taxonomy mappings.
- When taxonomy is provided, `append_taxonomy_to_sylph_profile.py` from `VEBA` adds `Database` and `Taxonomy` fields
