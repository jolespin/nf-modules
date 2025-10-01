# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-10-01
- Added `CHANGELOG.md` for each module to track changes
- Added `program` to `spades` module
- Added `checkm2_predict` module
- Added `pyhmmsearch` module
- Added `pykofamsearch` module
- Added `minimap2_align` module
- Added `strobealign` module
- Added `diamond_blastp` module
- Added `compleasm_run` module
- Added `tiara` module
- Added `veba_eukaryotic-gene-prediction` module
- Added `compile-reads-table` executable
- Add `-f/--force` to `nf-modules fetch` to overwrite

## [0.1.0] - 2025-09-01

### Added
- Initial release of nf-modules package
- `list` command to display available modules in the repository
- `fetch` command to download modules from GitHub repository
- Support for multiple output formats in list command:
  - `list-name`: Simple module names
  - `list-version`: Module names with tool and module versions
  - `yaml`: YAML format for environment management
- Tag/branch selection with `-t/--tag` option for fetch command
- Module filtering with `--filter` option for list command
- Initial module support for bioinformatics tools:
  - `barrnap` - Bacterial ribosomal RNA prediction
  - `flye` - De novo assembler for long-read sequencing
  - `pyrodigal` - Fast gene prediction for prokaryotes
  - `spades` - Genome assembler for bacterial genomes
  - `trnascanse` - tRNA gene detection
- Command-line interface with argparse
- pip installable package with entry points

[0.1.0]: https://github.com/jolespin/nf-modules/releases/tag/v0.1.0