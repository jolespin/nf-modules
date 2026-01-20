#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SYLPH_PROFILE } from "../main"

workflow {
    // Inputs
    reads_ch = Channel
        .fromPath(params.reads_manifest)
        .splitCsv(header: true, sep: "\t")
        .map { row ->
            def meta = [id: row.id_sample, single_end:false]
            def files = [
                file(row.fastq_forward, checkIfExists: true), 
                file(row.fastq_reverse, checkIfExists: true),
            ]
            [meta, files]
        }

    // Parse the manifest
    db_ch = Channel
        .fromPath(params.database_manifest)
        // Shape: emits once -> String (filepath)
        .splitCsv(header: true, sep: '\t')
        // Shape: emits N times -> Map (one per row)
        // [name: 'plastisphere_prokaryotic', database: 'db/...', taxonomy: 'db/...']
        // [name: 'plastisphere_eukaryotic', database: 'db/...', taxonomy: 'db/...']
        // [name: 'plastisphere_viral', database: 'db/...', taxonomy: 'db/...']
        .map { row -> 
            tuple (row.name, file(row.database, checkIfExists: true), file(row.taxonomy, checkIfExists: true))
        }
        // Shape: emits N times -> Tuple of 3 elements
        // ('plastisphere_prokaryotic', Path(db1.syldb), Path(tax1.tsv))
        // ('plastisphere_eukaryotic', Path(db2.syldb), Path(tax2.tsv))
        // ('plastisphere_viral', Path(db3.syldb), Path(tax3.tsv))
        .toList()
        // Shape: emits ONCE -> List of 3 tuples
        // [
        //   ('plastisphere_prokaryotic', Path(db1.syldb), Path(tax1.tsv)),
        //   ('plastisphere_eukaryotic', Path(db2.syldb), Path(tax2.tsv)),
        //   ('plastisphere_viral', Path(db3.syldb), Path(tax3.tsv))
        // ]
        .map{
            rows ->
            // rows is the List of 3 tuples from above

            // Extract first element of each tuple (names)
            def names = rows.collect{ it[0] }
            // Shape: List of N Strings
            // ['plastisphere_prokaryotic', 'plastisphere_eukaryotic', 'plastisphere_viral']
            
            // Extract second element of each tuple (databases)
            def databases = rows.collect{ it[1] }
            // Shape: List of N Paths
            // [Path(db1.syldb), Path(db2.syldb), Path(db3.syldb)]

            // Extract third element of each tuple (taxonomies)
            def taxonomies = rows.collect{ it[2] }
            // [Path(tax1.tsv), Path(tax2.tsv), Path(tax3.tsv)]
            
            tuple(names, databases, taxonomies)

        }

    // Run the module
    SYLPH_PROFILE(
        reads_ch, 
        db_ch,
    )

    // View the output to confirm the pipeline ran successfully.
    SYLPH_PROFILE.out.results.view()
}


// workflow {
//     // Inputs
//     reads_ch = Channel
//         .fromPath(params.reads_manifest)
//         .splitCsv(header: true, sep: "\t")
//         .map { row ->
//             def meta = [id: row.id_sample, single_end:false]
//             def files = [
//                 file(row.fastq_forward, checkIfExists: true), 
//                 file(row.fastq_reverse, checkIfExists: true),
//             ]
//             [meta, files]
//         }
//         .view { "READS: ${it}" }  // DEBUG

//     // Parse the manifest
//     db_ch = Channel
//         .fromPath(params.database_manifest)
//         .splitCsv(header: true, sep: '\t')
//         .map { row -> 
//             tuple(row.name, file(row.database, checkIfExists: true), file(row.taxonomy, checkIfExists: true))
//         }
//         .toList()
//         .map { rows ->
//             tuple(
//                 rows.collect { it[0] },
//                 rows.collect { it[1] },
//                 rows.collect { it[2] }
//             )
//         }
//         .view { "DB: ${it}" }  // DEBUG

//     // Run the module
//     SYLPH_PROFILE(
//         reads_ch, 
//         db_ch,
//     )

//     SYLPH_PROFILE.out.results.view { "OUTPUT: ${it}" }
// }
