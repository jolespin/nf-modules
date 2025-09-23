#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.22"

process EUKARYOTIC_GENE_PREDICTION {
    tag "$meta.id"
    label 'process_medium'

    container "docker.io/jolespin/veba_eukaryotic-gene-prediction:2.5.1"


    input:
    tuple val(meta), path(fasta)
    tuple val(dbmeta), path(db)
    val(name)
    val(minimum_contig_length)
    // val(scaffolds_to_bins) // Future versions may support multi-fasta

    output:
    tuple val(meta), path("*.probabilities.tsv.gz")  , emit: probabilities
    tuple val(meta), path("*.log")      , emit: log
    tuple val(meta), path("*.predictions.tsv.gz")  , emit: predictions
    tuple val(meta), path("*.fasta.gz")          , emit: fasta, optional: true
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = fasta
    def decompress_fasta = ""
    def cleanup = ""

    if (fasta.toString().endsWith('.gz')) {
        input = "temporary.fasta"
        decompress_fasta = "gunzip -c ${fasta} > ${input}"
        cleanup = "rm -f ${input}"
    }
    
    """
    # Prepare fasta file if gzipped
    ${decompress_fasta}

    # Run VEBA Eukaryotic Gene Modeling Wrapper
    eukaryotic_gene_modeling_wrapper.py \\
        -p ${task.cpus} \\
        -n ${name} \\
        -f ${input} \\
        -d ${db} \\
        -o eukaryotic_gene_modeling_output \\
        ----tiara_minimum_length ${minimum_contig_length} \\
        ${args}

    # Move outputs to expected names
    for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
    do
        gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/${name}.${ext} > ${name}.nuclear.${ext}.gz
    done
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/identifier_mapping.tsv > ${name}.identifier_mapping.nuclear.tsv.gz
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/identifier_mapping.metaeuk.tsv > ${name}.identifier_mapping.metaeuk.tsv.gz

    # Mitochondrion
    for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
    do
        gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/mitochondrion/${name}.${ext} > ${name}.mitochondrion.${ext}.gz
    done
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/mitochondrion/identifier_mapping.tsv > ${name}.identifier_mapping.mitochondrion.tsv.gz

    # Plastid
    for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
    do
        gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/plastid/${name}.${ext} > ${name}.plastid.${ext}.gz
    done
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/plastid/identifier_mapping.tsv > ${name}.identifier_mapping.plastid.tsv.gz

    # Statistics
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/genome_statistics.tsv > ${name}.genome_statistics.tsv.gz
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/gene_statistics.cds.tsv > ${name}.gene_statistics.cds.tsv.gz
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/gene_statistics.rRNA.tsv > ${name}.gene_statistics.rRNA.tsv.gz
    gzip -f -v -c -n eukaryotic_gene_modeling_output/${name}/output/gene_statistics.tRNA.tsv > ${name}.gene_statistics.tRNA.tsv.gz

    # Cleanup
    ${cleanup}

    rm -rv eukaryotic_gene_modeling_output/${name}/output/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eukaryotic_gene_modeling_wrapper.py: \$(eukaryotic_gene_modeling_wrapper.py --version)
    END_VERSIONS
    """

    // stub:
    // def prefix = task.ext.prefix ?: "${meta.id}"
    // def VERSION = '1.0.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    // """
    // touch ${prefix}.probabilities.tsv.gz
    // touch ${prefix}.log
    // touch ${prefix}.bacteria.fasta.gz
    // touch ${prefix}.predictions.tsv.gz

    // cat <<-END_VERSIONS > versions.yml
    // "${task.process}":
    //     tiara: ${VERSION}
    // END_VERSIONS
    // """
}