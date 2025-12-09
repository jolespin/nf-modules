#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { FLYE } from "../main"

workflow {
    // Define a dummy FASTA file for the pipeline to process.
    fasta_ch = Channel.fromPath(params.fasta)

    // The tuple format is required by the process input.
    fasta_with_meta = fasta_ch.map { file ->
        def meta = [id: file.baseName]
        return [meta, file]
    }

    // Run the process with the prepared channel.
    FLYE(
        fasta_with_meta,
        "--nano-hq",
	)

    // View the output to confirm the pipeline ran successfully.
    FLYE.out.fasta.view()
}