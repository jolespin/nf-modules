#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.1"

process PYRODIGAL {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::pyrodigal=3.6.3.post1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pyrodigal:3.6.3.post1--py310h1fe012e_1' :
        'quay.io/biocontainers/pyrodigal:3.6.3.post1--py310h1fe012e_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.gff.gz")                   , emit: gff
    tuple val(meta), path("*.ffn.gz")                   , emit: ffn
    tuple val(meta), path("*.faa.gz")                   , emit: faa
    tuple val(meta), path("*.score.gz")                 , emit: score
    tuple val(meta), path("*identifier_mapping.proteins.tsv.gz"), emit: identifier_mapping
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def attribute = task.ext.attribute ?: "gene_id"
    """
    gzip -c -d -f ${fasta} | \\
    pyrodigal \\
        -j ${task.cpus} \\
        $args \\
        -f gff \\
        -d ${prefix}.ffn \\
        -a ${prefix}.faa \\
        -s ${prefix}.score | \\
    awk -v attr="${attribute}" '
    BEGIN { FS=OFS="\\t" }
    /^#/ { 
        print; next 
    }
    {
        if (NF >= 9 && \$9 ~ /ID=/) {
            contig_id = \$1
            match(\$9, /ID=([^;]+)/, id_match)
            if (id_match[1]) {
                gene_id = id_match[1]
                \$9 = \$9 ";contig_id=" contig_id ";gene_biotype=protein_coding;" attr "=" gene_id ";"
            }
        }
        print
    }' > ${prefix}.gff

    # Create identifier mapping file
    awk -v genome_id="${prefix}" '
    BEGIN { FS=OFS="\\t" }
    !/^#/ && NF >= 9 && \$9 ~ /ID=/ {
        contig_id = \$1
        match(\$9, /ID=([^;]+)/, id_match)
        if (id_match[1]) {
            gene_id = id_match[1]
            print gene_id, contig_id, genome_id
        }
    }' ${prefix}.gff > ${prefix}.identifier_mapping.proteins.tsv

    gzip -n -f ${prefix}.ffn \\