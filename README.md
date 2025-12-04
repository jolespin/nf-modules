# nf-modules

`NextFlow` bioinformatics module management tool

## Overview

`nf-modules` is a command-line tool for managing `NextFlow` bioinformatics modules. It provides simple commands to list available modules and fetch them for use in your `NextFlow` workflows.  Many of these modules are modifications from `nf-core`.  For official `nf-core` modules, please use https://github.com/nf-core.

## Installation

PyPI
```bash
pip install nf-modules
```

## Usage
Recommended minimal `NextFlow` project directory structure: 
```
├── nextflow.config
├── main.nf
├── modules/
│   ├── local/nf-modules/ # Your custom modules (e.g., assembly.nf) and nf-modules (e.g., pyhmmsearch)
│   └── nf-core/ # Official nf-core modules
├── bin/
├── .gitignore
└── README.md
```

### List available modules

```bash
# List all modules (names only)
nf-modules list

# Export as YAML format
nf-modules list -f yaml

# Filter modules by name
nf-modules list --filter spades
```

### Fetch modules

```bash
# Fetch modules to default directory (modules/local/nf-modules/)
nf-modules fetch pyrodigal spades

# Fetch to custom directory
nf-modules fetch -o modules/local/nf-modules/ pyrodigal spades

# Fetch from specific git tag/branch
nf-modules fetch -t v0.1.0 pyrodigal spades # Version
nf-modules fetch -t dev -f pyrodigal spades # Branch (overwrite previous version with -f/--force)
```

## Commands

### list

List all available modules in the repository.

**Options:**
- `-f, --format {list-name,list-version,yaml}`: Output format (default: list-name)
- `-t, --tag TAG`: Git tag or branch to fetch from (default: main)
- `--filter FILTER`: Filter modules by name pattern (case-insensitive substring match)

**Output Formats:**
* list-name
    ```
    barrnap
    flye
    pyrodigal
    spades
    trnascanse
    ...
    ```

* yaml
    ```yaml
    name: nf-modules
    dependencies:
    - barrnap=0.9--hdfd78af_4[2025.9.1]
    - flye=2.9.5--d577924c8416ccd8[2025.9.1]
    - pyrodigal=3.6.3.post1--py310h1fe012e_1[2025.9.1]
    ```

### fetch

Download modules from the repository to a local directory.

**Options:**
- `-o, --output-directory DIR`: Output directory (default: modules/local/nf-modules/)
- `-t, --tag TAG`: Git tag or branch to fetch from (default: main)
- `modules`: One or more module names to fetch

**Examples:**
```bash
nf-modules fetch pyrodigal
nf-modules fetch pyrodigal spades flye
nf-modules fetch -o modules/local/nf-modules/ -t v1.0.0 pyrodigal spades
```

## Utilities
### compile-reads-table

#### Illumina
```bash
compile-reads-table -f Fastq/ -n "[ID]_R[DIRECTION]_001.fastq.gz" -x fastq.gz
```

#### Oxford Nanopore / PacBio
```bash
compile-reads-table -f Fastq/ -n "[ID].merged.fastq" -x fastq -L
```

## Requirements

- Python 3.6+
- PyYAML
- Pandas ≥ 2.1.0

## Repository

The modules are sourced from: https://github.com/jolespin/nf-modules

## License

Apache 2.0