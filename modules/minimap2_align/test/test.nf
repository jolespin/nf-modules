#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { MINIMAP2_ALIGN } from "../main"

workflow {
    reads_ch = Channel.of([
        [id: "ecoli"],
        file(params.reads, checkIfExists: true),
    ])

    reference_ch = Channel.of([
        [id: "ecoli_ref"],
        file(params.reference, checkIfExists: true),
    ])

    MINIMAP2_ALIGN(
        reads_ch,
        reference_ch,
        params.preset,
        params.mode,
    )

    MINIMAP2_ALIGN.out.bam.view()
    MINIMAP2_ALIGN.out.depth.view()
}
