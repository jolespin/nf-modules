#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SYLPH_PROFILE } from "../main"
include { SYLPH_PROFILE_MANY } from "../main"
include { SYLPH_PROFILE_WITH_TAXONOMY } from "../main"
include { SYLPH_PROFILE_MANY_WITH_TAXONOMY } from "../main"

workflow {
    // ------------------
    // Test SYLPH_PROFILE
    // ------------------
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
        .map { row -> 
            file(row.database, checkIfExists: true)
        }
        .collect()
    

    // Run the module
    SYLPH_PROFILE(
        reads_ch, 
        db_ch,
    )

    // View the output to confirm the pipeline ran successfully.
    SYLPH_PROFILE.out.results.view()

    // -----------------------
    // Test SYLPH_PROFILE_MANY
    // -----------------------
    // Individual samples
    reads_ch = Channel
        .fromPath(params.reads_manifest)
        .splitCsv(header: true, sep: "\t")
        .map { row ->
            [
                [id: row.id_sample, single_end: false],
                [
                    file(row.fastq_forward, checkIfExists: true),
                    file(row.fastq_reverse, checkIfExists: true)
                ]
            ]
        }
    
    // Batch all samples together
    reads_ch_batched = reads_ch
        .toList()
        .map { all_samples ->
            // Extract components
            def sample_metas = all_samples.collect { it[0] }
            def r1s = all_samples.collect { it[1][0] }
            def r2s = all_samples.collect { it[1][1] }
            
            // Create batch metadata
            def batch_meta = [
                id: 'all_samples',
                n_samples: sample_metas.size()
            ]
            
            tuple(batch_meta, sample_metas, r1s, r2s)
        }
    
    // Database channel (same as before)
    db_ch = Channel
        .fromPath(params.database_manifest)
        // Shape: emits once -> String (filepath)
        .splitCsv(header: true, sep: '\t')
        // Shape: emits N times -> Map (one per row)
        .map { row -> 
            file(row.database, checkIfExists: true)
        }
        .collect()
    
    // Run batched profiling
    SYLPH_PROFILE_MANY(reads_ch_batched, db_ch)
    
    SYLPH_PROFILE_MANY.out.results.view()

    // --------------------------------
    // Test SYLPH_PROFILE_WITH_TAXONOMY
    // --------------------------------
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
    SYLPH_PROFILE_WITH_TAXONOMY(
        reads_ch, 
        db_ch,
    )

    // View the output to confirm the pipeline ran successfully.
    SYLPH_PROFILE_WITH_TAXONOMY.out.results.view()

    // -------------------------------------
    // Test SYLPH_PROFILE_MANY_WITH_TAXONOMY
    // -------------------------------------
    // Individual samples
    reads_ch = Channel
        .fromPath(params.reads_manifest)
        .splitCsv(header: true, sep: "\t")
        .map { row ->
            [
                [id: row.id_sample, single_end: false],
                [
                    file(row.fastq_forward, checkIfExists: true),
                    file(row.fastq_reverse, checkIfExists: true)
                ]
            ]
        }
    
    // Batch all samples together
    reads_ch_batched = reads_ch
        .toList()
        .map { all_samples ->
            // Extract components
            def sample_metas = all_samples.collect { it[0] }
            def r1s = all_samples.collect { it[1][0] }
            def r2s = all_samples.collect { it[1][1] }
            
            // Create batch metadata
            def batch_meta = [
                id: 'all_samples',
                n_samples: sample_metas.size()
            ]
            
            tuple(batch_meta, sample_metas, r1s, r2s)
        }
    
    // Database channel (same as before)
    db_ch = Channel
        .fromPath(params.database_manifest)
        .splitCsv(header: true, sep: '\t')
        .map { row -> 
            tuple(row.name, file(row.database, checkIfExists: true), file(row.taxonomy, checkIfExists: true))
        }
        .toList()
        .map { rows ->
            tuple(
                rows.collect { it[0] },
                rows.collect { it[1] },
                rows.collect { it[2] }
            )
        }
    
    // Run batched profiling
    SYLPH_PROFILE_MANY_WITH_TAXONOMY(reads_ch_batched, db_ch)
    
    SYLPH_PROFILE_MANY_WITH_TAXONOMY.out.results.view()
}
