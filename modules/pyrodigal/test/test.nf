#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { PYRODIGAL } from "../main"

workflow {
    // Define a dummy FASTA file for the pipeline to process.
    // In a real scenario, this would be provided by the user.
    // We are just simulating the channel input here.
    // This assumes a file named 'test.fasta' exists in the same directory.
    // Replace 'test.fasta' with your actual input file name.
    fasta_ch = Channel.fromPath(params.fasta)

    // The tuple format is required by the process input.
    // We create a meta map for the process and pair it with the fasta file.
    // The `autolineage` parameter is also required.
    fasta_with_meta = fasta_ch.map { file ->
        def meta = [id: file.baseName]
        return [meta, file]
    }

    // Run the process with the prepared channel.
    PYRODIGAL(
	fasta_with_meta,
	)

    // View the output to confirm the pipeline ran successfully.
    PYRODIGAL.out.gff.view()
    PYRODIGAL.out.identifier_mapping.view()
}