#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { FLYE } from "../main"

workflow {
    // Define a dummy FASTA file for the pipeline to process.
    fastq_ch = Channel.fromPath(params.fastq)

    // The tuple format is required by the process input.
    fastq_with_meta = fastq_ch.map { file ->
        [[id: "ecoli"], file]
    }

    // Run the process with the prepared channel.
    FLYE(
        fastq_with_meta,
        "--nano-hq",
	)

    // View the output to confirm the pipeline ran successfully.
    FLYE.out.fasta.view()
}