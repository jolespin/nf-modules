# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-12-02
- Added test data:
  - Bacteria: 
    - Species: `Escherichia coli str. K-12 substr. MG1655`
    - RefSeq: `GCF_000005845.2`
    - Files: `data/organisms/bacteria/e_coli.*.gz`

  - Archaea: 
    - Species: `Haloferax volcanii DS2`
    - RefSeq: `GCF_000025685.1`
    - Files: `data/organisms/archaea/h_volcanii.*.gz`

  - Eukarya: 
    - Species: `Saccharomyces cerevisiae S288C`
    - RefSeq: `GCF_000146045.2`
    - Files: `data/organisms/eukarya/yeast.*.gz`

  - Virus: 
    - Species: `Escherichia phage T7`
    - RefSeq: `GCF_000844825.1`
    - Files: `data/organisms/virus/phage.*.gz`
- Changed `${meta.id}.scaffolds.fasta.gz` to `${meta.id}.assembly.fa.gz` to be consistent with extension used by `FLYE`
- Changed `${meta.id}.assembly.fasta.gz` to `${meta.id}.assembly.fa.gz` to be consistent with extension used by `SPAdes`
- Updated `PyHMMSearch` to `v2025.10.23.post1` which includes `description` field of HMMs
- Added `gtdbtk_classifywf` module
- Changed default location from `modules/external/` to `modules/local/nf-modules/` because `nf-core` throws error

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