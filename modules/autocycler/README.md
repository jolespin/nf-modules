# AutoCycler

Monolithic consensus long-read assembler for bacterial isolate genomes. Runs the full AutoCycler pipeline per sample: genome size estimation, read subsampling, parallel multi-assembler assembly, consensus graph construction, and final assembly generation. Based on Ryan Wick's [AutoCycler](https://github.com/rrwick/Autocycler) and his `autocycler_fast.sh` script.

## Unique Features

* Accepts user-provided genome size or automatically estimates it via `autocycler helper genome_size` (quick Raven assembly)
* Handles gzipped input reads (decompresses internally)
* Runs 6 assemblers in parallel via GNU parallel with configurable concurrency
* Tolerates individual assembler failures (`set +e`) — remaining assemblies still produce a consensus
* Applies Ryan Wick's assembly weight adjustments:
  - Plassembler circular contigs: `Autocycler_cluster_weight=3`
  - Flye contigs: `Autocycler_consensus_weight=2`
* Outputs `*.assembly.fa.gz` (same naming convention as the Flye module for downstream compatibility)
* Preserves GFA output for future dnaapler integration
* Contig names are **not** prefixed — the downstream `PREFIX_CONTIGS` process handles that optionally

## Inputs

| Input | Type | Description |
|---|---|---|
| `(meta, reads)` | `tuple(val, path)` | Sample metadata and long-read FASTQ (`.fastq` or `.fastq.gz`) |
| `read_type` | `val` | AutoCycler read type string (see table below) |
| `genome_size` | `val` | Genome size: `"auto"` to estimate via Raven, or a specific value (see below) |

### `read_type` values

| Value | Use when |
|---|---|
| `ont_r9` | Oxford Nanopore R9 chemistry |
| `ont_r10` | Oxford Nanopore R10 chemistry **(default for ONT)** |
| `pacbio_clr` | PacBio continuous long reads |
| `pacbio_hifi` | PacBio HiFi / CCS reads **(default for PacBio)** |

The pipeline maps sequencing type to read type via `nextflow.config`:
```
ont_autocycler_read_type = "ont_r10"
pacbio_autocycler_read_type = "pacbio_hifi"
```

### `genome_size` values

| Value | Description |
|---|---|
| `"auto"` | Estimate genome size via a quick Raven assembly (`autocycler helper genome_size`) **(default)** |
| `"4m"` or `"4M"` | 4,000,000 bp — suffix `k`/`m`/`g` (case-insensitive) supported |
| `"4.5m"` | 4,500,000 bp — decimals allowed before the suffix |
| `"5000000"` | 5,000,000 bp — raw integer |
| `"5000k"` | 5,000,000 bp — equivalent using `k` suffix |

When `"auto"` is used, genome size is estimated per sample, which adds a Raven assembly step (~2-5 min). Providing a known genome size skips this step and can speed up the pipeline, especially when the expected size is known (e.g. *E. coli* ~`"5m"`, *S. aureus* ~`"2.8m"`).

## Outputs

| Output | Emit | Description |
|---|---|---|
| `*.assembly.fa.gz` | `fasta` | Consensus assembly FASTA (gzipped, raw contig names) |
| `*.assembly.gfa.gz` | `gfa` | Assembly graph (for dnaapler or visualization) |
| `*.assembly.yaml` | `stats` | AutoCycler combine statistics (contig count, sizes, topology) |
| `*.autocycler.log` | `log` | Combined log from all AutoCycler steps |
| `versions.yml` | `versions` | Tool versions |

## Pipeline Steps (executed sequentially within the process)

1. **Genome size determination** — uses the provided `genome_size` value, or estimates it via `autocycler helper genome_size` (quick Raven assembly) when set to `"auto"`
2. **Read depth estimation** — counts total bases and calculates depth relative to estimated genome size
3. **Adaptive subsampling** — if read depth >= `min_read_depth` (default: 25x), runs `autocycler subsample` to create N subsets (default: 4). If depth is below the threshold, skips subsampling and uses all reads as a single subset (count=1). Strategy is logged for user visibility
4. **Parallel assembly** — 6 assemblers x N subsets via GNU parallel (24 jobs at normal depth, 6 at low depth)
5. **Weight adjustments** — Plassembler circular and Flye consensus weights
6. **Compress** — `autocycler compress` (build unitig graph from all assemblies)
7. **Cluster** — `autocycler cluster` (group contigs into putative genomic elements)
8. **Trim + Resolve** — per QC-pass cluster (collapse redundancy, resolve repeats)
9. **Combine** — `autocycler combine` (merge clusters into final consensus with depth)
10. **Output** — gzip FASTA and GFA, copy stats YAML

## CPU Allocation Strategy

Each assembly job needs meaningful CPU allocation to run efficiently. The process ensures each concurrent job gets at least 4 threads, scaling concurrency based on available CPUs:

**Normal depth (>= 25x): 4 subsets x 6 assemblers = 24 jobs**

| `task.cpus` | Concurrent jobs | Threads/job | Behavior |
|---|---|---|---|
| 4 | 1 | 4 | Sequential, 4 threads per job |
| 8 | 2 | 4 | 2 concurrent, 12 rounds |
| 16 | 4 | 4 | 4 concurrent, 6 rounds |
| 32 | 8 | 4 | 8 concurrent, 3 rounds |
| 96 | 24 | 4 | All 24 concurrent, 4 threads each |

**Low depth (< 25x): 1 subset x 6 assemblers = 6 jobs**

| `task.cpus` | Concurrent jobs | Threads/job | Behavior |
|---|---|---|---|
| 4 | 1 | 4 | Sequential, 4 threads per job |
| 16 | 4 | 4 | 4 concurrent, 2 rounds |
| 32 | 6 | 5 | All 6 concurrent |

Non-assembly steps (genome size estimation, compress, trim, resolve, combine) use all available threads.

**Recommended allocation**: 16 CPUs / 32 GB for typical bacterial isolates. At normal depth, this runs 4 assembly jobs concurrently with 4 threads each, completing all 24 jobs in ~6 rounds.

## Configurable Parameters

Set in `nextflow.config` under `params`:

| Parameter | Default | Description |
|---|---|---|
| `autocycler_assemblers` | `"flye,raven,miniasm,myloasm,plassembler,metamdbg"` | Comma-separated assembler list |
| `autocycler_genome_size` | `"auto"` | Genome size: `"auto"` to estimate, or a value like `"4m"`, `"5000000"` |
| `autocycler_subsample_count` | `4` | Number of read subsets (at normal depth) |
| `autocycler_min_read_depth` | `25` | Minimum read depth for subsampling. Below this, all reads are used with each assembler (count=1) |
| `autocycler_min_depth_rel` | `0.1` | Filter contigs below this fraction of max depth |
| `ont_type` | `"ont_r10"` | Read type for ONT samples |
| `pacbio_type` | `"pacbio_hifi"` | Read type for PacBio samples |

## Default Assemblers

| Assembler | Strengths | Genome size required? |
|---|---|---|
| flye | High-quality, handles repeats well | No (optional) |
| raven | Fast, reliable | No |
| miniasm | Very fast, lower quality (improves consensus) | No |
| myloasm | Fast, good complement to others | No |
| plassembler | Separates chromosomal vs plasmid sequences | No |
| metamdbg | Fast, designed for long reads | No |

All 6 assemblers work with both ONT and PacBio reads. The `autocycler helper` command handles read-type-specific settings internally.

If plassembler's database is not available, its assembly jobs fail silently and the consensus proceeds with the remaining assemblers.

## Example Usage

```groovy
// In a workflow (auto genome size estimation):
AUTOCYCLER(
    reads_ch,       // tuple(meta, reads.fastq.gz)
    "ont_r10",      // read_type
    "auto",         // genome_size — estimate via Raven
)

// With a known genome size (skips Raven estimation):
AUTOCYCLER(
    reads_ch,
    "ont_r10",
    "4.6m",         // genome_size — E. coli
)

// Outputs:
AUTOCYCLER.out.fasta  // tuple(meta, SAMPLE.assembly.fa.gz)
AUTOCYCLER.out.gfa    // tuple(meta, SAMPLE.assembly.gfa.gz)
AUTOCYCLER.out.stats  // tuple(meta, SAMPLE.assembly.yaml)
AUTOCYCLER.out.log    // tuple(meta, SAMPLE.autocycler.log)
```

## Resource Requirements

```groovy
withName: 'AUTOCYCLER' {
    cpus = 16
    memory = '32.GB'
    time = '8.h'
    errorStrategy = 'finish'
}
```

## Container

Custom Docker image with AutoCycler + all assemblers + GNU parallel. See `docker/Dockerfile`.

## Limitations

* AutoCycler threads capped at 100 (hard limit in the tool)
* Individual assembler timeout is 4 hours (hardcoded in GNU parallel `--timeout`)
* Requires at least 2 successful assemblies for `autocycler compress` to work
* Not suitable for eukaryotic or metagenomic samples — designed for bacterial/archaeal isolates
