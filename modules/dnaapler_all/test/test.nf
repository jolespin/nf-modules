#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { DNAAPLER_ALL } from "../main"

workflow {
    fasta_ch = Channel.fromPath(params.fasta)

    fasta_with_meta = fasta_ch.map { file ->
        [[id: "test"], file]
    }

    DNAAPLER_ALL(
        fasta_with_meta,
        params.min_contig_length,   // default: 1000
    )

    DNAAPLER_ALL.out.fasta.view()
}
