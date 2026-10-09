#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process PREPEND_PREFIX_TO_FASTA_HEADERS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::sed"
    container "docker.io/ubuntu:22.04"

    input:
    tuple val(meta), path(fasta, stageAs: 'input/*')
    val(delimiter) // Recommended to use __ here

    output:
    tuple val(meta), path("output/*"), emit: fasta
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = fasta.name.endsWith('.gz')
    def output_name = fasta.toString().tokenize('/')[-1]
    """
    mkdir -p output

    if [ "${is_gzipped}" = "true" ]; then
        gunzip -c ${fasta} \\
            | sed 's/^>/>${meta.id}${delimiter}/' \\
            | gzip > output/${output_name}
    else
        sed 's/^>/>${meta.id}${delimiter}/' ${fasta} \\
            > output/${output_name}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        module: v2026.10.8
    END_VERSIONS
    """
}

process PREPEND_PREFIX_TO_GFA {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::agtools"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/agtools:1.1.2--pyhdfd78af_0' :
        'quay.io/biocontainers/agtools:1.1.2--pyhdfd78af_0' }"


    input:
    tuple val(meta), path(gfa, stageAs: 'input/*')
    val(delimiter) // Recommended to use __ here

    output:
    tuple val(meta), path("output/*"), emit: gfa
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = gfa.name.endsWith('.gz')
    def output_name = gfa.toString().tokenize('/')[-1]
    def gfa_name = output_name.replaceAll(/\.gz$/, '')
    """
    mkdir -p output

    if [ "${is_gzipped}" = "true" ]; then
        gunzip -c ${gfa} > input.gfa
        agtools rename ${args} -g input.gfa -p "${meta.id}${delimiter}" -o output/${gfa_name}
        rm input.gfa
    else
        agtools rename ${args} -g ${gfa} -p "${meta.id}${delimiter}" -o output/${gfa_name}
    fi

    gzip output/${gfa_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        module: v2026.10.8
        agtools: \$(agtools --version 2>&1)
    END_VERSIONS
    """
}

