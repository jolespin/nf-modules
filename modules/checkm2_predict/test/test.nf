#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { CHECKM2_PREDICT } from "../main"

workflow {
    bins_ch = Channel.of([
        [id: "e_coli"],
        [file(params.fasta, checkIfExists: true)],
    ])

    db_ch = Channel.of([
        [id: "checkm2_db"],
        file(params.db, checkIfExists: true),
    ])

    CHECKM2_PREDICT(
        bins_ch,
        db_ch,
        params.genes,
    )

    CHECKM2_PREDICT.out.checkm2_tsv.view()
}
