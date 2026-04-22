#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { STROBEALIGN } from "../main"

workflow {
    reads_ch = Channel.of([
        [id: "S1"],
        [
            file(params.r1, checkIfExists: true),
            file(params.r2, checkIfExists: true),
        ],
    ])

    reference_ch = Channel.of([
        [id: "S1__metagenome"],
        file(params.reference, checkIfExists: true),
    ])

    STROBEALIGN(
        reads_ch,
        reference_ch,
        params.mode,
    )

    STROBEALIGN.out.bam.view()
    STROBEALIGN.out.depth.view()
}
