#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { FASTQ_PREPROCESSOR_SHORT } from "../main"

workflow {
    // -------------------------------------
    // Test FASTQ_PREPROCESSOR_SHORT
    // -------------------------------------
    reads_ch = Channel.of([
        [id:"S1"],
        [
            file(params.r1, checkIfExists:true), 
            file(params.r2, checkIfExists:true),
        ],
    ])

    reference_ch = Channel.of([
        [id:"S1__genomes"],
        file(params.reference, checkIfExists:true),
    ])

    // Run batched profiling
    FASTQ_PREPROCESSOR_SHORT(
        reads_ch, 
        reference_ch,
        [],
        [],
        )
    
    FASTQ_PREPROCESSOR_SHORT.out.decontaminated_reads.view()
    FASTQ_PREPROCESSOR_SHORT.out.seqkit_stats.view()
    FASTQ_PREPROCESSOR_SHORT.out.fastp_html.view()
    FASTQ_PREPROCESSOR_SHORT.out.reads.view()

}
