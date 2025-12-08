#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.12.5"

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
    tuple val(meta), path("*.identifier_mapping.proteins.tsv.gz"), emit: identifier_mapping
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def attribute = task.ext.attribute ?: "gene_id"
    """
    # Run pyrodigal and modify GFF in one pipe
    gzip -c -d -f ${fasta} | \\
    pyrodigal \\
        -j ${task.cpus} \\
        $args \\
        -f gff \\
        -d ${prefix}.ffn \\
        -a ${prefix}.faa \\
        -s ${prefix}.score | \\
    awk -F'\\t' -v prefix="${prefix}" '
        /^#/ {
            print
            next
        }
        {
            contig_id = \$1
            
            # Extract ID from attributes (column 9) using string manipulation
            gene_id = \$9
            sub(/.*ID=/, "", gene_id)
            sub(/;.*/, "", gene_id)
            
            # Add contig_id, gene_id, and gene_biotype to attributes
            \$9 = \$9 "contig_id=" contig_id ";gene_id=" gene_id ";gene_biotype=protein_coding"
            
            # Write to identifier mapping file (no header, explicit tabs)
            print gene_id "\\t" contig_id "\\t" prefix >> prefix ".identifier_mapping.proteins.tsv"
            
            # Print modified GFF line
            print \$0
        }
    ' OFS='\\t' > ${prefix}.gff

    # Compress all output files
    gzip -n -f ${prefix}.ffn \\
               ${prefix}.faa \\
               ${prefix}.gff \\
               ${prefix}.score \\
               ${prefix}.identifier_mapping.proteins.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyrodigal: \$(echo \$(pyrodigal --version 2>&1 | sed 's/pyrodigal v//'))
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "" | gzip > ${prefix}.gff.gz
    echo "" | gzip > ${prefix}.ffn.gz
    echo "" | gzip > ${prefix}.faa.gz
    echo "" | gzip > ${prefix}.score.gz
    echo "" | gzip > ${prefix}.identifier_mapping.proteins.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyrodigal: \$(echo \$(pyrodigal --version 2>&1 | sed 's/pyrodigal v//'))
        module: ${module_version}
    END_VERSIONS
    """
}