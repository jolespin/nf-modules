#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { GTDBTK_CLASSIFYWF } from "../main"

workflow {
    // Collect all genome files into single channel with meta
    all_genomes_ch = Channel.fromPath(params.genome_1)
        .mix(Channel.fromPath(params.genome_2))
        .collect()
        .map { files ->
            def meta = [id: "all_genomes"]
            return [meta, files]
        }

    // Database channel - note the input expects tuple val(db_name), path(db)
    // db_name should be a string identifier, NOT a meta map
    db_ch = Channel.fromPath(params.db, type: "dir")
        .map { db_path -> ["gtdb", db_path] }

    // Mash DB - just a path channel, no tuple needed
    mash_db_ch = Channel.fromPath("${params.db}/mash/gtdb.msh")

    // Run the process
    GTDBTK_CLASSIFYWF(
        all_genomes_ch,
        db_ch,
        false,                  // use_pplacer_scratch_dir
        mash_db_ch,
        "fa.gz"                 // extension
    )

    // View output
    GTDBTK_CLASSIFYWF.out.summary.view()
}