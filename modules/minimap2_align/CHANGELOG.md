# Changelog

All notable changes to this module will be documented in this file.

## v2026.03.30 - 2026-03-30
* Added `samtools view -bS -@ ${task.cpus} - ` to to filter out potentially malformed records


## v2025.09.05 - 2025-09-05

### Added
* Initial release
* Runs samtools sorted bam, index, and depth if `mode = "bam"`
* Also supports paf mode

