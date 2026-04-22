#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { BARRNAP } from "../main"

workflow {
    fasta_ch = Channel.fromPath(params.fasta).map { file ->
        [[id: "e_coli"], file, params.dbname]
    }

    BARRNAP(fasta_ch)

    BARRNAP.out.gff.view()
    BARRNAP.out.fasta.view()
}
