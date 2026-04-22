#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SPADES } from "../main"

workflow {
    input_ch = Channel.of([
        [id: "S1", single_end: false],
        [
            file(params.r1, checkIfExists: true),
            file(params.r2, checkIfExists: true),
        ],
        [],
        [],
    ])

    SPADES(
        input_ch,
        [],
        [],
        params.program,
    )

    SPADES.out.scaffolds.view()
    SPADES.out.contigs.view()
    SPADES.out.log.view()
}
