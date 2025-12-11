#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { MEDAKA } from "../main"

workflow {
    // Define a dummy FASTA file for the pipeline to process.
    fastq_ch = Channel.fromPath(params.fastq)
    fasta_ch = Channel.fromPath(params.fasta)


    // The tuple format is required by the process input.
    fastq_with_meta = fastq_ch.map { file ->
        [[id: "ecoli"], file]
    }
    fasta_with_meta = fasta_ch.map { file ->
        [[id: "ecoli"], file]
    }
    combined_ch = fastq_with_meta.join(fasta_with_meta)

    // Run the process with the prepared channel.
    MEDAKA(
        combined_ch,
	)

    // View the output to confirm the pipeline ran successfully.
    MEDAKA.out.assembly.view()
}