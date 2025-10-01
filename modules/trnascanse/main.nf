#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.1"

process TRNASCANSE {
    tag "${meta.id}"
    label "process_medium"

    conda "bioconda::trnascan-se=2.0.12"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trnascan-se:2.0.12--pl5321h7b50bb2_2':
        'biocontainers/trnascan-se:2.0.12--pl5321h7b50bb2_2' }"

    input:
    tuple val(meta), path(fasta)
    val mode

    output:
    tuple val(meta), path("*.tsv.gz")   , emit: tsv
    // tuple val(meta), path("*.log")   , emit: log
    tuple val(meta), path("*.stats.gz") , emit: stats
    tuple val(meta), path("*.tRNA.gz") , emit: fasta
    tuple val(meta), path("*.gff.gz")   , emit: gff
    path("versions.yml")             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def input = fasta.name.endsWith('.gz') ? fasta.baseName : fasta.name
    def unzip   = fasta.getExtension() == "gz" ? "gunzip -c ${fasta} > ${input}" : ""
    def cleanup = fasta.getExtension() == "gz" ? "rm ${input}" : ""
    """
    ${unzip}

    ## larger genomes can fill up the limited temp space in the singularity container
    ## expected location of the default config file is with the exectuable
    ## copy this and modify to use the working dir as the temp directory
    conf=\$(which tRNAscan-SE).conf
    cp \${conf} trnascan.conf
    sed -i s#/tmp#.#g trnascan.conf

    tRNAscan-SE \\
        --thread ${task.cpus} \\
        --forceow \\
        --progress \\
        --fasta ${prefix}.tRNA \\
        --gff ${prefix}.tRNA.gff \\
        --struct ${prefix}.tRNA.struct \\
        -o ${prefix}.tRNA.tsv \\
        // -l ${prefix}.tRNA.log \\
        -m ${prefix}.tRNA.stats \\
        -${mode} \\
        -c trnascan.conf \\
        ${args} \\
        ${input}

    gzip -n -f ${prefix}.tRNA ${prefix}.tRNA.gff ${prefix}.tRNA.struct ${prefix}.tRNA.stats ${prefix}.tRNA.tsv

    ${cleanup}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tRNAscan-SE: \$(tRNAscan-SE 2>&1 >/dev/null | awk 'NR==2 {print \$2}')
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tRNA.tsv.gz
    // touch ${prefix}.tRNA.log
    touch ${prefix}.tRNA.stats.gz
    echo '' | gzip > ${prefix}.tRNA.gz
    touch ${prefix}.tRNA.gff.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tRNAscan-SE: \$(tRNAscan-SE 2>&1 >/dev/null | awk 'NR==2 {print \$2}')
        module: ${module_version}
    END_VERSIONS
    """
}