#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { TRNASCANSE } from "../main"

workflow {
    fasta_ch = Channel.fromPath(params.fasta).map { file ->
        [[id: "e_coli"], file]
    }

    TRNASCANSE(
        fasta_ch,
        params.mode,
    )

    TRNASCANSE.out.tsv.view()
    TRNASCANSE.out.gff.view()
    TRNASCANSE.out.fasta.view()
}
