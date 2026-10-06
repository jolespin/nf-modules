# Identifier Mapping Files

Summary of the identifier mapping files produced by the `veba_eukaryotic-gene-prediction` module.

---

## 1. `identifier_mapping.metaeuk.tsv`

**Produced by:** `compile_metaeuk_identifiers.py` (line 346)

**Has header:** Yes

**Purpose:** Full MetaEuk gene prediction metadata. Contains parsed MetaEuk header information including target accessions, contig IDs, strand, gene coordinates, bitscores, e-values, exon coordinates, and simplified gene IDs. This is the most detailed identifier mapping file and serves as the source for the nuclear identifier mapping.

**Index column:** `MetaEuk_header` (the raw MetaEuk header string)

**Columns (in order):**

| Column | Description |
|---|---|
| `MetaEuk_header` | Raw MetaEuk header (index) |
| `T_acc` | Target accession |
| `C_acc` | Contig ID |
| `S` | Strand (`+` or `-`) |
| `gene_id` | Simplified gene ID (format: `{contig}_{low}:{high}({strand})`) |
| `bitscore` | Bitscore |
| `e-value` | E-value |
| `num_exons` | Number of exons |
| `low_coord` | Low coordinate of gene |
| `high_coord` | High coordinate of gene |
| `all_low_exon_coords` | List of low exon coordinates |
| `all_taken_low_exon_coords` | List of taken low exon coordinates |
| `all_high_exon_coords` | List of high exon coordinates |
| `all_taken_high_exon_coords` | List of taken high exon coordinates |
| `all_exon_nucl_len` | List of exon nucleotide lengths |
| `all_taken_exon_nucl_len` | List of taken exon nucleotide lengths |

**Nextflow output channel:** `metaeuk_identifier_mapping` (gzipped as `*.identifier_mapping.metaeuk.tsv.gz`)

---

## 2. `identifier_mapping.tsv`

**Produced by:** `partition_gene_models.py` (line 110)

**Has header:** No (the `--include_header` flag is not passed by `eukaryotic_gene_modeling_wrapper.py`)

**Purpose:** Maps each gene/ORF to its contig and genome (MAG/bin). Used internally during gene model partitioning to associate genes with their source genomes. Only produced in batch mode when `--scaffolds_to_bins` is provided. Separate files are created for nuclear, mitochondrion, and plastid gene models.

**Columns (in order):**

| Column | Description |
|---|---|
| `id_orf` | Gene/ORF ID (index, unnamed in output) |
| `id_contig` | Contig/scaffold ID |
| `id_mag` | Genome/MAG/bin ID |

**Notes:**
- Rows with missing `id_mag` values (unbinned contigs) are dropped unless `--include_unbinned` is passed.
- This file is an internal intermediate and is not directly emitted as a Nextflow output channel.
- Created separately for each compartment:
  - Nuclear: in `2__metaeuk/` intermediate directory
  - Mitochondrion: in `3__pyrodigal-mitochondrion/` intermediate directory
  - Plastid: in `4__pyrodigal-plastid/` intermediate directory

---

## 3. `*.identifier_mapping.nuclear.tsv.gz`

**Produced by:** `main.nf` (lines 98 and 229) via an `awk` command that extracts columns from `identifier_mapping.metaeuk.tsv`:

```bash
awk -F"\t" 'NR>1 {print "${prefix}", $3, $5}' OFS="\t" \
  results/output/identifier_mapping.metaeuk.tsv \
  | gzip > ${prefix}.identifier_mapping.nuclear.tsv.gz
```

**Has header:** No (`NR>1` skips the header row from the input and no new header is written)

**Purpose:** A simplified three-column mapping of genome, contig, and gene identifiers for nuclear genes. This is the file emitted by the Nextflow process for downstream use.

**Columns (in order):**

| Column | Description |
|---|---|
| (column 1) | Genome/sample ID (the Nextflow `${prefix}`) |
| (column 2) | Contig ID (from `C_acc` in the metaeuk file) |
| (column 3) | Gene ID (from `gene_id` in the metaeuk file) |

**Nextflow output channel:** `nuclear_identifier_mapping`
