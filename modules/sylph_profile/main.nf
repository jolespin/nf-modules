#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "v2025.1.19"

process SYLPH_PROFILE {
    tag "${meta.id}"
    label 'process_high'

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/sylph:0.9.0--ha6fb395_0'
        : 'biocontainers/sylph:0.9.0--ha6fb395_0'}"

    input:
    tuple val(meta), path(reads)
    tuple val(db_name), path(db, stageAs: "db/*"), path(taxonomy, stageAs: "tax/*")

    output:
    tuple val(meta), path('*.tsv.gz'), emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = meta.single_end ? "${reads}" : "-1 ${reads[0]} -2 ${reads[1]}"

    // Get databases
    def db_names = db_name
    def db_list = db.collect{ it -> "db/${it.name}"}.join(" ")
    def tax_list = taxonomy.collect{ it -> "tax/${it.name}"}.join(" ")

    """
    echo $db_names
    echo $db_list
    echo $tax_list

    # Run Sylph profiling
    # -------------------
    sylph profile \\
        -t ${task.cpus} \\
        ${args} \\
        ${db_list}\\
        ${input} \\
        -o ${prefix}.tsv

    # Compress output files
    # ---------------------
    gzip -n -v ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = meta.single_end ? "${reads}" : "-1 ${reads[0]} -2 ${reads[1]}"

    """
    touch ${prefix}.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """
}

// process SYLPH_PROFILE_MANY{

// }

