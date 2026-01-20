#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SYLPH_PROFILE } from "../main"

workflow {
    // Inputs
    reads_ch = Channel
        .fromPath(params.reads_manifest)
        .splitCsv(header: true, sep: "\t")
        .map { row ->
            def meta = [id: row.id_sample, single_end:false],
            def files = [
                file(row.fastq_forward, checkIfExists: true), 
                file(row.fastq_reverse, checkIfExists: true),
            ]
            [meta, files]
        }

    // Parse the manifest
    db_ch = Channel
        .fromPath(params.database_manifest)
        .splitCsv(header: true, sep: '\t')
        .map { row -> 
            [row.db_name, file(row.database_path, checkIfExists: true), file(row.taxonomy_path, checkIfExists: true)]
        }
        .collect()  // Collect all rows into a single list
        .map { rows ->
            // Transpose: list of tuples -> tuple of lists
            def db_names = rows.collect { it[0] }
            def db_files = rows.collect { it[1] }
            def tax_files = rows.collect { it[2] }
            [db_names, db_files, tax_files]
        }


    // Run the module
    SYLPH_PROFILE(
        reads_ch, 
        db_ch,
    )

    // View the output to confirm the pipeline ran successfully.
    SYLPH_PROFILE.out.results.view()

}
