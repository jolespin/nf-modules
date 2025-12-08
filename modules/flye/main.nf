#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.10.28"

process FLYE {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::flye=2.9.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/fa/fa1c1e961de38d24cf36c424a8f4a9920ddd07b63fdb4cfa51c9e3a593c3c979/data' :
        'community.wave.seqera.io/library/flye:2.9.5--d577924c8416ccd8' }"

    input:
    tuple val(meta), path(reads)
    val mode

    output:
    tuple val(meta), path("*.assembly.fa.gz"), emit: fasta
    tuple val(meta), path("*.gfa.gz")  , emit: gfa
    tuple val(meta), path("*.gv.gz")   , emit: gv
    tuple val(meta), path("*.txt")     , emit: txt
    tuple val(meta), path("*.log")     , emit: log
    tuple val(meta), path("*.json")    , emit: json
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def valid_mode = ["--pacbio-raw", "--pacbio-corr", "--pacbio-hifi", "--nano-raw", "--nano-corr", "--nano-hq"]

    if ( !valid_mode.contains(mode) )  { error "Unrecognised mode to run Flye. Options: ${valid_mode.join(', ')}" }
    """
    flye \\
        $mode \\
        $reads \\
        --out-dir . \\
        --threads $task.cpus \\
        $args

    # Process assembly.fasta with ID prefix
    if [ -f assembly.fasta ]; then
        # Add sample ID prefix to contig names
        sed 's/^>/>'"${meta.id}"'__/' assembly.fasta > ${prefix}.assembly.fa
        gzip -f ${prefix}.assembly.fa
    fi

    # Process other files (no sequence ID modification needed)
    if [ -f assembly_graph.gfa ]; then
        gzip -c assembly_graph.gfa > ${prefix}.assembly_graph.gfa.gz
    fi
    
    if [ -f assembly_graph.gv ]; then
        gzip -c assembly_graph.gv > ${prefix}.assembly_graph.gv.gz
    fi
    
    if [ -f assembly_info.txt ]; then
        mv assembly_info.txt ${prefix}.assembly_info.txt
    fi
    
    if [ -f flye.log ]; then
        mv flye.log ${prefix}.flye.log
    fi
    
    if [ -f params.json ]; then
        mv params.json ${prefix}.params.json
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$( flye --version )
        module: ${module_version}
    END_VERSIONS
    """

}