# dnaapler all

Reorients assembled contigs to begin at biologically relevant start sites (e.g. dnaA for chromosomes, repA for plasmids) using [dnaapler](https://github.com/gbouras13/dnaapler). Runs the `dnaapler all` subcommand, which tries multiple reorientation methods per contig and selects the best match. Includes optional contig length filtering via SeqKit.

## Inputs

| Input | Type | Description |
|---|---|---|
| `(meta, assembly)` | `tuple(val, path)` | Sample metadata and assembled contigs FASTA |
| `min_contig_length` | `val` | Minimum contig length to retain (default: 1000) |

## Outputs

| Output | Emit | Description |
|---|---|---|
| `*.dnaapler.fa.gz` | `fasta` | Reoriented contigs passing length filter (gzipped) |
| `*.dnaapler.gfa.gz` | `gfa` | Reoriented assembly graph (gzipped) |
| `*.dnaapler.discarded-contigs.fa.gz` | `discarded_contigs` | Contigs below `min_contig_length` (gzipped) |
| `*.log` | `log` | dnaapler log |
| `versions.yml` | `versions` | Tool versions |

## Example Usage

```groovy
DNAAPLER_ALL(
    assembly_ch,    // tuple(meta, contigs.fasta)
    1000,           // min_contig_length
)

DNAAPLER_ALL.out.fasta              // tuple(meta, SAMPLE.dnaapler.fa.gz)
DNAAPLER_ALL.out.discarded_contigs  // tuple(meta, SAMPLE.dnaapler.discarded-contigs.fa.gz)
DNAAPLER_ALL.out.gfa                // tuple(meta, SAMPLE.dnaapler.gfa.gz)
DNAAPLER_ALL.out.log                // tuple(meta, SAMPLE.log)
```

## Resource Requirements

```groovy
withName: 'DNAAPLER_ALL' {
    cpus = 6
    memory = '28.GB'
    time = '8.h'
}
```

## Container

Custom Docker image with dnaapler + SeqKit. See `docker/Dockerfile`.
