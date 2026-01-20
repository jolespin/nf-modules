# sylph_profile-veba
## Unique Features
* Adds `Sample` column
* Contains 4 `nextflow` processes: 
    * `SYLPH_PROFILE` - Use when there are many samples and small-ish databases
    * `SYLPH_PROFILE_MANY` - Use when there are large databases (e.g., `GlobDB`)
    * `SYLPH_PROFILE_WITH_TAXONOMY` - Use when there are many samples and small-ish databases.  Must provide taxonomy mappings.
    * `SYLPH_PROFILE_MANY_WITH_TAXONOMY` - Use when there are large databases (e.g., `GlobDB`).  Must provide taxonomy mappings.
* When taxonomy is provided, `append_taxonomy_to_sylph_profile.py` from `VEBA` adds `Database` and `Taxonomy` fields
