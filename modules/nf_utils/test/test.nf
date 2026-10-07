#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { PREPEND_PREFIX_TO_FASTA_HEADERS } from "../main"

workflow {
    fasta_ch = Channel.of([
        [id: "ecoli"],
        file(params.fasta, checkIfExists: true),
    ])

    PREPEND_PREFIX_TO_FASTA_HEADERS(
        fasta_ch,
        params.delimiter,
    )

    PREPEND_PREFIX_TO_FASTA_HEADERS.out.fasta.view()
}
