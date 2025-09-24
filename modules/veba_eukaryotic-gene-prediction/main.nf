#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.24"

process EUKARYOTIC_GENE_PREDICTION {
    tag "$meta.id"
    label 'process_medium'

    container "docker.io/jolespin/veba_eukaryotic-gene-prediction:2.5.1"

    input:
    tuple val(meta), path(fasta)
    tuple val(dbmeta), path(db)
    val(name)
    val(minimum_contig_length)
    // val(scaffolds_to_bins) // Future versions may support multiple fasta

    output:
    // Identifier mappings
    tuple val(meta), path("*.identifier_mapping.metaeuk.tsv.gz")  , emit: metaeuk_identifier_mapping
    tuple val(meta), path("*.identifier_mapping.nuclear.tsv.gz")  , emit: nuclear_identifier_mapping
    // tuple val(meta), path("*.identifier_mapping.mitochondrion.tsv.gz")  , emit: mitochondrion_identifier_mapping
    // tuple val(meta), path("*.identifier_mapping.plastid.tsv.gz")  , emit: plastid_identifier_mapping

    // Statistics
    tuple val(meta), path("*.genome_statistics.tsv.gz")  , emit: stats_genome
    tuple val(meta), path("*.gene_statistics.cds.tsv.gz")  , emit: stats_cds
    tuple val(meta), path("*.gene_statistics.rRNA.tsv.gz")  , emit: stats_rRNA
    tuple val(meta), path("*.gene_statistics.tRNA.tsv.gz")  , emit: stats_tRNA

    // Nuclear
    tuple val(meta), path("*.nuclear.fa.gz")  , emit: nuclear_fa
    tuple val(meta), path("*.nuclear.faa.gz")  , emit: nuclear_faa
    tuple val(meta), path("*.nuclear.ffn.gz")  , emit: nuclear_ffn
    tuple val(meta), path("*.nuclear.gff.gz")  , emit: nuclear_gff
    tuple val(meta), path("*.nuclear.rRNA.gz")  , emit: nuclear_rRNA
    tuple val(meta), path("*.nuclear.tRNA.gz")  , emit: nuclear_tRNA

    // Mitochondrion
    tuple val(meta), path("*.mitochondrion.fa.gz")  , emit: mitochondrion_fa
    tuple val(meta), path("*.mitochondrion.faa.gz")  , emit: mitochondrion_faa
    tuple val(meta), path("*.mitochondrion.ffn.gz")  , emit: mitochondrion_ffn
    tuple val(meta), path("*.mitochondrion.gff.gz")  , emit: mitochondrion_gff
    tuple val(meta), path("*.mitochondrion.rRNA.gz")  , emit: mitochondrion_rRNA
    tuple val(meta), path("*.mitochondrion.tRNA.gz")  , emit: mitochondrion_tRNA

    // Plastid
    tuple val(meta), path("*.plastid.fa.gz")  , emit: plastid_fa
    tuple val(meta), path("*.plastid.faa.gz")  , emit: plastid_faa
    tuple val(meta), path("*.plastid.ffn.gz")  , emit: plastid_ffn
    tuple val(meta), path("*.plastid.gff.gz")  , emit: plastid_gff
    tuple val(meta), path("*.plastid.rRNA.gz")  , emit: plastid_rRNA
    tuple val(meta), path("*.plastid.tRNA.gz")  , emit: plastid_tRNA

    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def db_name = db[0].baseName.replaceAll(/\..*/, '')

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
        -d ${db_name} \\
        -o eukaryotic_gene_modeling_output \\
        --tiara_minimum_length ${minimum_contig_length} \\
        ${args}

    # Move outputs to expected names
    for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
    do
        gzip -f -v -c -n eukaryotic_gene_modeling_output/output/${name}.\${ext} > ${name}.nuclear.\${ext}.gz
    done
    # gzip -f -v -c -n eukaryotic_gene_modeling_output/output/identifier_mapping.tsv > ${name}.identifier_mapping.nuclear.tsv.gz

    gzip -f -v -c -n eukaryotic_gene_modeling_output/output/identifier_mapping.metaeuk.tsv > ${name}.identifier_mapping.metaeuk.tsv.gz
    awk -F"\t" 'NR>1 {print "${name}", $3, $5}' OFS="\t" identifier_mapping.metaeuk.tsv | gzip -f -v -n > ${name}.identifier_mapping.nuclear.tsv.gz


    # Mitochondrion
    for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
    do
        gzip -f -v -c -n eukaryotic_gene_modeling_output/output/mitochondrion/${name}.\${ext} > ${name}.mitochondrion.\${ext}.gz
    done
    gzip -f -v -c -n eukaryotic_gene_modeling_output/output/mitochondrion/identifier_mapping.tsv > ${name}.identifier_mapping.mitochondrion.tsv.gz

    # Plastid
    for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
    do
        gzip -f -v -c -n eukaryotic_gene_modeling_output/output/plastid/${name}.\${ext} > ${name}.plastid.\${ext}.gz
    done
    gzip -f -v -c -n eukaryotic_gene_modeling_output/output/plastid/identifier_mapping.tsv > ${name}.identifier_mapping.plastid.tsv.gz

    # Statistics
    gzip -f -v -c -n eukaryotic_gene_modeling_output/output/genome_statistics.tsv > ${name}.genome_statistics.tsv.gz
    gzip -f -v -c -n eukaryotic_gene_modeling_output/output/gene_statistics.cds.tsv > ${name}.gene_statistics.cds.tsv.gz
    gzip -f -v -c -n eukaryotic_gene_modeling_output/output/gene_statistics.rRNA.tsv > ${name}.gene_statistics.rRNA.tsv.gz
    gzip -f -v -c -n eukaryotic_gene_modeling_output/output/gene_statistics.tRNA.tsv > ${name}.gene_statistics.tRNA.tsv.gz

    # Cleanup
    ${cleanup}

    rm -rv eukaryotic_gene_modeling_output/output/

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