# Changelog

All notable changes to this module will be documented in this file.

## v2025.09.04 - 2025-09-04

### Added
* Added `--header simple`
* Removed `DIAMOND_BLASTP_WITH_CONCATENATION` and now `DIAMOND_BLASTP` supports both single files and multiple files
* Changed `meta2` to `dbmeta`
* Changed prefix from `"${meta.id}_vs_${dbmeta.id}"` to `"${meta.id}---${dbmeta.id}"`


## v2025.09.03 - 2025-09-03

### Added
* Added `DIAMOND_BLASTP_WITH_CONCATENATION` which takes a bunch of input fasta, concatenates them to a temporary file, runs `diamond blastp` then removes the temporary file.
