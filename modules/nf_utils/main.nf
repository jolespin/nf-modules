#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2026.10.7"

process PREPEND_PREFIX_TO_FASTA_HEADERS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::sed"
    container "ubuntu:22.04"

    input:
    tuple val(meta), path(fasta, stageAs: 'input/*')
    val(delimiter)

    output:
    tuple val(meta), path("output/*"), emit: fasta
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = fasta.name.endsWith('.gz')
    def output_name = fasta.name
    """
    mkdir -p output

    if [ "${is_gzipped}" = "true" ]; then
        gunzip -c input/${fasta.name} \\
            | sed 's/^>/>${meta.id}${delimiter}/' \\
            | gzip > output/${output_name}
    else
        sed 's/^>/>${meta.id}${delimiter}/' input/${fasta.name} \\
            > output/${output_name}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        module: ${module_version}
    END_VERSIONS
    """
}
