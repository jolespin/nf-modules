#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { STROBEALIGN_WRAPPER } from "../main"

workflow {
    // -------------------------------------
    // Test STROBEALIGN_WRAPPER
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
    STROBEALIGN_WRAPPER(
        reads_ch, 
        reference_ch,
        true,
        true,
        true,
        )
    
    STROBEALIGN_WRAPPER.out.bam.view()
    STROBEALIGN_WRAPPER.out.mapped_fastq.view()
    STROBEALIGN_WRAPPER.out.unmapped_fastq.view()
    STROBEALIGN_WRAPPER.out.coverage.view()
    STROBEALIGN_WRAPPER.out.depth.view()

}
