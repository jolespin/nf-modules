#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { PYKOFAMSEARCH } from "../main"

workflow {
    fasta_ch = Channel.of([
        [id: "e_coli"],
        file(params.fasta, checkIfExists: true),
    ])

    db_ch = Channel.of([
        [id: "kofam"],
        file(params.db, checkIfExists: true),
    ])

    PYKOFAMSEARCH(
        fasta_ch,
        db_ch,
        params.write_reformatted_output,
        params.is_serialized_database,
    )

    PYKOFAMSEARCH.out.output.view()
}
