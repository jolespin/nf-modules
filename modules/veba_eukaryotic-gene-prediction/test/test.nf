#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { VEBA_EUKARYOTIC_GENE_PREDICTION } from "../main"

workflow {
    // Define a dummy FASTA file for the pipeline to process.
    // In a real scenario, this would be provided by the user.
    // We are just simulating the channel input here.
    // This assumes a file named 'test.fasta' exists in the same directory.
    // Replace 'test.fasta' with your actual input file name.
    fasta_ch = Channel.fromPath(params.fasta)
    db_ch = Channel.fromPath("${params.db}*")
        .collect()  // Collect all database files into a single list

    // The tuple format is required by the process input.
    // We create a meta map for the process and pair it with the fasta file.
    // The `autolineage` parameter is also required.
    fasta_with_meta = fasta_ch.map { file ->
        def meta = [id: "test"]
        return [meta, file]
    }
    db_with_meta = db_ch.map { files ->
        def meta = [id: file(params.db).baseName]
        return [meta, files]
    }
    //tiara_probabilities_ch = Channel.fromPath(params.tiara_probabilities, checkIfExists: true)

    // Run the process with the prepared channel.
    VEBA_EUKARYOTIC_GENE_PREDICTION(
        fasta_with_meta,
        db_with_meta,
        [], //tiara_probabilities_ch,
        3000,
        )

    // View the output to confirm the pipeline ran successfully.
    VEBA_EUKARYOTIC_GENE_PREDICTION.out.fa
    VEBA_EUKARYOTIC_GENE_PREDICTION.out.faa
    VEBA_EUKARYOTIC_GENE_PREDICTION.out.ffn
    VEBA_EUKARYOTIC_GENE_PREDICTION.out.gff
}