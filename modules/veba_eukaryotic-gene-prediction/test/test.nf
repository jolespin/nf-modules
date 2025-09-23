#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { EUKARYOTIC_GENE_PREDICTION } from "../main"

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
        def meta = [id: file.baseName]
        return [meta, file]
    }
    db_with_meta = db_ch.map { files ->
        def meta = [id: file(params.db).baseName]
        return [meta, files]
    }

    // Run the process with the prepared channel.
    EUKARYOTIC_GENE_PREDICTION(
	fasta_with_meta,
	db_with_meta,
	"test",
        3000,
	)

    // View the output to confirm the pipeline ran successfully.
    EUKARYOTIC_GENE_PREDICTION.out.nuclear_fa
    EUKARYOTIC_GENE_PREDICTION.out.nuclear_faa
    EUKARYOTIC_GENE_PREDICTION.out.nuclear_ffn
    EUKARYOTIC_GENE_PREDICTION.out.nuclear_gff
}