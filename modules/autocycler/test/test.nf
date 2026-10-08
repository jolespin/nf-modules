#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { AUTOCYCLER } from "../main"

workflow {
    fastq_ch = Channel.fromPath(params.fastq)

    fastq_with_meta = fastq_ch.map { file ->
        [[id: "test"], file]
    }

    AUTOCYCLER(
        fastq_with_meta,
        params.read_type,                    // ont_r10, ont_r9, pacbio_hifi, pacbio_clr
        params.autocycler_assemblers,        // default: "flye,raven,miniasm,myloasm,plassembler,metamdbg"
        params.autocycler_subsample_count,   // default: 4
        params.autocycler_min_read_depth,    // default: 25
        params.autocycler_min_depth_rel,     // default: 0.1
        params.autocycler_min_contig_length, // default: 1000
    )

    AUTOCYCLER.out.fasta.view()
}
