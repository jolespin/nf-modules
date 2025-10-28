# GTDB-Tk ClassifyWf
## Unique Features
* Stages gzipped fasta files from `SPAdes` and `Flye`
* Merges bacteria and archaea summary into a single file called `${prefix}.gtdbtk_taxonomy.tsv`

## Limitations:
* Input must be gzipped
* Only accepts fa.gz/fasta.gz/fna.gz/fas.gz/fsa.gz
* Cannot use with `--extension` flag
