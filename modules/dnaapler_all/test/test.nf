#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { DNAAPLER_ALL } from "../main"

workflow {
    gfa_ch = Channel.fromPath(params.gfa)

    gfa_with_meta = gfa_ch.map { file ->
        [[id: "test"], file]
    }

    DNAAPLER_ALL(
        gfa_with_meta,
        params.min_contig_length,   // default: 1000
    )

    DNAAPLER_ALL.out.fasta.view()
}
