# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - TBD
### Changed
* `spades`
  * Changed `${meta.id}.scaffolds.fasta.gz` to `${meta.id}.scaffolds.fa.gz` now that `gtdbtk_classifywf` has an `extension` input
* `medaka`
  * Changed `${meta.id}.fa.gz` to `${meta.id}.medaka.fa.gz` now that `gtdbtk_classifywf` has an `extension` input
* `sylph_profile-veba`
  * Added `${prefix}` to fastq files during staging instead of using original filenames (e.g., `S1_1.fastq.gz` and `S1_2.fastq.gz` instead of `reads_1.fastq.gz` and `reads_2.fastq.gz`)
  
## [0.2.2] - 2026-01-19

### Added

* **New Modules**: 
  * `antismash-veba`
    * Initial release with support for bacteria and fungi taxon choices.
    * Automated archiving (`.tar.gz`) of `clusterblast/`, `subclusterblast/`, and `knowclusterblast/`.
    * Integration of `reformat_antismash_clusterblast.py` from VEBA.
  * `medaka`
    * Automatic handling of gzipped files
* `kegg_pathway_profiler`
  * Added `step_coverage.tsv.gz` and `step_coverage` emits to `kegg_pathway_profiler`.

### Changed
  * `kegg_pathway_profiler`
    * Updated tool version to `v2025.12.18`.
    * Renamed `coverage_report` to `pathway_coverage` in emit.

### Fixed
* Fixed `pykofamsearch` output to only emit `*.output.tsv.gz`, matching `pyhmmsearch` behavior.
* Fixed missing period in `identifier_mapping.proteins.tsv.gz` `pyrodigal` emit.

## [0.2.1] - 2025-12-05

* Added `identifier_mapping.proteins.tsv.gz` to each test organism
* Added `pykofamsearch_results.tsv.gz` to each test organism
* Added `kegg_pathway_profiler` module
* Reverted version from `gtdbtk_classifywf` from `2.5.2` to `2.4.1` because of significant performance issues with recomputing sketches [see GTDB-Tk issue #665](https://github.com/Ecogenomics/GTDBTk/issues/665)

## [0.2.0] - 2025-12-02

* Added test data:
* Bacteria: `Escherichia coli str. K-12 substr. MG1655` (GCF_000005845.2)
* Archaea: `Haloferax volcanii DS2` (GCF_000025685.1)
* Eukarya: `Saccharomyces cerevisiae S288C` (GCF_000146045.2)
* Virus: `Escherichia phage T7` (GCF_000844825.1)


* Changed `${meta.id}.scaffolds.fasta.gz` to `${meta.id}.assembly.fa.gz` to be consistent with extension used by `FLYE`
* Changed `${meta.id}.assembly.fasta.gz` to `${meta.id}.assembly.fa.gz` to be consistent with extension used by `SPAdes`
* Updated `PyHMMSearch` to `v2025.10.23.post1` which includes `description` field of HMMs
* Added `gtdbtk_classifywf` module
* Changed default location from `modules/external/` to `modules/local/nf-modules/` because `nf-core` throws error

## [0.1.1] - 2025-10-01

* Added `CHANGELOG.md` for each module to track changes
* Added `program` to `spades` module
* Added `checkm2_predict` module
* Added `pyhmmsearch` module
* Added `pykofamsearch` module
* Added `minimap2_align` module
* Added `strobealign` module
* Added `diamond_blastp` module
* Added `compleasm_run` module
* Added `tiara` module
* Added `veba_eukaryotic-gene-prediction` module
* Added `compile-reads-table` executable
* Add `-f/--force` to `nf-modules fetch` to overwrite

## [0.1.0](https://www.google.com/search?q=%5Bhttps://github.com/jolespin/nf-modules/releases/tag/v0.1.0%5D(https://github.com/jolespin/nf-modules/releases/tag/v0.1.0)) - 2025-09-01

### Added

* Initial release of nf-modules package
* `list` command to display available modules in the repository
* `fetch` command to download modules from GitHub repository
* Support for multiple output formats in list command (`list-name`, `list-version`, `yaml`)
* Tag/branch selection with `-t/--tag` option for fetch command
* Module filtering with `--filter` option for list command
* Initial module support: `barrnap`, `flye`, `pyrodigal`, `spades`, `trnascanse`
* Command-line interface with argparse
* pip installable package with entry points

### Pending

* `AutoCycler` https://academic.oup.com/bioinformatics/article/41/9/btaf474/8242761

