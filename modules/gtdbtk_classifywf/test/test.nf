#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { GTDBTK_CLASSIFYWF } from "../main"

workflow {
    // Create a channel with both test genomes (bacteria and archaea)
    // These will be staged as bins/* in the process
    genome_files = Channel.fromPath([
        params.bacteria_genome,
        params.archaea_genome
    ]).collect()

    // Create meta map and pair with genome files
    // The genomes will be staged in bins/* directory
    input_ch = genome_files.map { files ->
        def meta = [id: 'testing']
        return [meta, files]
    }

    // Create database channel with db_name and path
    // GTDB database should be a directory containing the GTDB-Tk reference data
    db_ch = Channel.of([
        'GTDB',  // db_name
        file(params.gtdb_database, checkIfExists: true)
    ])

    // Set whether to use pplacer scratch directory
    // Set to false for testing to speed things up
    use_pplacer_scratch = Channel.value(false)

    // Create mash database channel
    // This is optional - if not using ANI screening, pass empty list
    mash_ch = params.gtdbmash_database 
        ? Channel.fromPath(params.gtdbmash_database, checkIfExists: true)
        : Channel.value([])

    // Run the GTDBTK_CLASSIFYWF process
    GTDBTK_CLASSIFYWF(
        input_ch,
        db_ch,
        use_pplacer_scratch,
        mash_ch
    )

    // View the outputs to confirm the pipeline ran successfully
    GTDBTK_CLASSIFYWF.out.summary.view { meta, file -> 
        "Summary: ${file}" 
    }
    GTDBTK_CLASSIFYWF.out.tree.view { meta, file -> 
        "Tree: ${file}" 
    }
    GTDBTK_CLASSIFYWF.out.versions.view { file ->
        "Versions: ${file}"
    }
}
