#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { DIAMOND_BLASTP } from "../main"

workflow {
    fasta_ch = Channel.of([
        [id: "e_coli"],
        file(params.fasta, checkIfExists: true),
    ])

    db_ch = Channel.of([
        [id: "uniref90"],
        file(params.db, checkIfExists: true),
    ])

    DIAMOND_BLASTP(
        fasta_ch,
        db_ch,
        params.outfmt,
        params.blast_columns,
    )

    DIAMOND_BLASTP.out.results.view()
}
