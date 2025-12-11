#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { ANTISMASH } from "../main"

workflow {
    // Define a dummy FASTA file for the pipeline to process.
    fasta_ch = Channel.fromPath(params.fasta)
    gff_ch = Channel.fromPath(params.gff)
    db_ch = file(params.db, type: 'dir')


    // The tuple format is required by the process input.

    fasta_with_meta = fasta_ch.map { file ->
        [[id: "ecoli"], file]
    }


    // Run the process with the prepared channel.
    ANTISMASH(
        fasta_with_meta,
        db_ch,
        gff_ch,
	true,
	true,
	true,
	true,
	true,
	)

    // View the output to confirm the pipeline ran successfully.
    ANTISMASH.out.gbk_input.view()
}
