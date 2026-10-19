# Changelog

All notable changes to this module will be documented in this file.

## v2026.10.19
### Fixed
- Fixed issue regarding `veba_reformatted` processing silently failing due to `nan` in GFF parsing from NCBI by `biosynthetic_genbanks_to_table.py` ([VEBA Issue #213](https://github.com/jolespin/veba/issues/213))

## v2026.09.23
### Added
- Added `hmmdetection_strictness` parameter


## v2026.04.27
### Added
- GFF staging to handle NCBI GFF with `pseudogenic_tRNA` and other record types [issue/#15](https://github.com/jolespin/nf-modules/issues/15)

## v2026.01.02

### Added
- Archive `clusterblast/`, `subclusterblast/`, and `knowclusterblast/` when applicable (`.tar.gz`)
- Gzip the json file
- Added `taxon` input `choices: {bacteria, fungi}`
- Added `reformat_antismash_clusterblast.py` from `VEBA`

## v2025.12.21

### Added
- Added missing cluster flags

## v2025.12.11

### Added
- Initial release
