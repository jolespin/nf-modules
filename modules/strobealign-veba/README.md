# Strobealign-VEBA

## v2026.10.07
### Changed
- Changed inputs to `tuple val(meta), path(reads), path(reference)` to handle improper pairing


## Unique Features
* Runs the `strobealign_wrapper` via `fastq_preprocessor`
* Supports sorted BAM, `samtools depth`, `samtools coverage`, mapped reads, and unmapped reads export