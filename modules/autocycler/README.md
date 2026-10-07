# AutoCycler

Monolithic consensus long-read assembler for bacterial isolate genomes. Runs the full AutoCycler pipeline per sample: genome size estimation, read subsampling, parallel multi-assembler assembly, consensus graph construction, and final assembly generation. Based on Ryan Wick's [AutoCycler](https://github.com/rrwick/Autocycler) and his `autocycler_fast.sh` script.

## Unique Features

* Automatically estimates genome size per sample via `autocycler helper genome_size` (quick Raven assembly) — no manual input needed
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

## Outputs

| Output | Emit | Description |
|---|---|---|
| `*.assembly.fa.gz` | `fasta` | Consensus assembly FASTA (gzipped, raw contig names) |
| `*.assembly.gfa.gz` | `gfa` | Assembly graph (for dnaapler or visualization) |
| `*.assembly.yaml` | `stats` | AutoCycler combine statistics (contig count, sizes, topology) |
| `*.autocycler.log` | `log` | Combined log from all AutoCycler steps |
| `versions.yml` | `versions` | Tool versions |

## Pipeline Steps (executed sequentially within the process)

1. **Genome size estimation** — `autocycler helper genome_size` (quick Raven assembly)
2. **Read subsampling** — `autocycler subsample` (default: 2 subsets, seed 42)
3. **Parallel assembly** — 6 assemblers x 2 subsets = 12 jobs via GNU parallel
4. **Weight adjustments** — Plassembler circular and Flye consensus weights
5. **Compress** — `autocycler compress` (build unitig graph from all assemblies)
6. **Cluster** — `autocycler cluster` (group contigs into putative genomic elements)
7. **Trim + Resolve** — per QC-pass cluster (collapse redundancy, resolve repeats)
8. **Combine** — `autocycler combine` (merge clusters into final consensus with depth)
9. **Output** — gzip FASTA and GFA, copy stats YAML

## CPU Allocation Strategy

Each assembly job needs meaningful CPU allocation to run efficiently. The process ensures each concurrent job gets at least 4 threads, scaling concurrency based on available CPUs:

| `task.cpus` | Concurrent jobs | Threads/job | Behavior |
|---|---|---|---|
| 1 | 1 | 1 | Sequential, 1 thread (minimum viable) |
| 4 | 1 | 4 | Sequential, 4 threads per job |
| 8 | 2 | 4 | 2 concurrent, 4 threads each |
| 16 | 4 | 4 | 4 concurrent, 3 rounds of jobs |
| 32 | 8 | 4 | 8 concurrent, 2 rounds |
| 48 | 12 | 4 | All 12 concurrent, 4 threads each |
| 96 | 12 | 8 | All 12 concurrent, 8 threads each |

Non-assembly steps (genome size estimation, compress, trim, resolve, combine) use all available threads.

**Recommended allocation**: 16 CPUs / 32 GB for typical bacterial isolates. This runs 4 assembly jobs concurrently with 4 threads each, completing all 12 jobs in ~3 rounds.

## Configurable Parameters

Set in `nextflow.config` under `params`:

| Parameter | Default | Description |
|---|---|---|
| `autocycler_assemblers` | `"flye,raven,miniasm,myloasm,plassembler,metamdbg"` | Comma-separated assembler list |
| `autocycler_subsample_count` | `2` | Number of read subsets |
| `autocycler_min_depth_rel` | `0.1` | Filter contigs below this fraction of max depth |
| `ont_autocycler_read_type` | `"ont_r10"` | Read type for ONT samples |
| `pacbio_autocycler_read_type` | `"pacbio_hifi"` | Read type for PacBio samples |

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
// In a workflow:
AUTOCYCLER(
    reads_ch,       // tuple(meta, reads.fastq.gz)
    "ont_r10",      // read_type
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
