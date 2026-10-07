
# NF Utils
General-purpose utility processes for the pipeline.

## Processes

### PREPEND_PREFIX_TO_FASTA_HEADERS
* Prepends `${meta.id}${delimiter}` to every FASTA header line
* Accepts both gzipped and uncompressed FASTA files (`.fa`, `.fasta`, `.fna`, `.fa.gz`, etc.)
* Preserves the original filename and extension in the output
* Configurable delimiter (default: `__`)
* Input is staged to `input/` and output is written to `output/` to avoid filename collisions since the output retains the original filename
