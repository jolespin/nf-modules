#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SYLPH_QUERY } from "../main"
include { SYLPH_QUERY_MANY } from "../main"
include { SYLPH_QUERY_WITH_TAXONOMY } from "../main"
include { SYLPH_QUERY_MANY_WITH_TAXONOMY } from "../main"

workflow {
    // ------------------
    // Test SYLPH_QUERY
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
    SYLPH_QUERY(
        reads_ch, 
        db_ch,
    )

    // View the output to confirm the pipeline ran successfully.
    SYLPH_QUERY.out.results.view()

    // -----------------------
    // Test SYLPH_QUERY_MANY
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
            
            // Interleave R1 and R2 files: [S1_R1, S1_R2, S2_R1, S2_R2, ...]
            def all_reads = all_samples.collectMany { sample ->
                [sample[1][0], sample[1][1]]  // [R1, R2] for each sample
            }
            
            // Create batch metadata
            def batch_meta = [
                id: 'all_samples',
                n_samples: sample_metas.size()
            ]
            
            tuple(batch_meta, sample_metas, all_reads)
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
    SYLPH_QUERY_MANY(reads_ch_batched, db_ch)
    
    SYLPH_QUERY_MANY.out.results.view()

    // --------------------------------
    // Test SYLPH_QUERY_WITH_TAXONOMY
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
    SYLPH_QUERY_WITH_TAXONOMY(
        reads_ch, 
        db_ch,
    )

    // View the output to confirm the pipeline ran successfully.
    SYLPH_QUERY_WITH_TAXONOMY.out.results.view()

    // -------------------------------------
    // Test SYLPH_QUERY_MANY_WITH_TAXONOMY
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

    reads_ch_batched = reads_ch
        .toList()
        .map { all_samples ->
            def sample_metas = all_samples.collect { it[0] }
            
            // Interleave R1 and R2 files
            def all_reads = all_samples.collectMany { sample ->
                [sample[1][0], sample[1][1]]
            }
            
            def batch_meta = [
                id: 'all_samples',
                n_samples: sample_metas.size()
            ]
            
            tuple(batch_meta, sample_metas, all_reads)
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
    SYLPH_QUERY_MANY_WITH_TAXONOMY(reads_ch_batched, db_ch)
    
    SYLPH_QUERY_MANY_WITH_TAXONOMY.out.results.view()
}
