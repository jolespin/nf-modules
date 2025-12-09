#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { PYHMMSEARCH } from "../main"

workflow {
    // Define a dummy FASTA file for the pipeline to process.
    fasta_ch = Channel.fromPath(params.fasta)
    db_ch = Channel.fromPath(params.db)
    
    // The tuple format is required by the process input.
    // We create a meta map for the process and pair it with the fasta file.
    fasta_with_meta = fasta_ch.map { file ->
        def meta = [id: file.baseName]
        return [meta, file]
    }
    db_with_meta = db_ch.map { files ->
        def meta = [id: file(params.db).baseName]
        return [meta, files]
    }

    // Run the process with the prepared channel.
    PYHMMSEARCH(
        fasta_with_meta,
        db_with_meta,
        true,
        true,
        true,
	)

    // View the output to confirm the pipeline ran successfully.
    PYHMMSEARCH.out.output.view()
    PYHMMSEARCH.out.reformatted_output.view()
    PYHMMSEARCH.out.tblout.view()
    PYHMMSEARCH.out.domtblout.view()
}