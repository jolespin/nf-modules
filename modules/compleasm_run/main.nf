#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.18"

process COMPLEASM_RUN{
    tag "$meta.id"
    label "process_medium"

    // conda "bioconda::compleasm=0.2.7" // This won't work because it needs the reformatting script
    container "docker.io/jolespin/compleasm-veba:0.2.7"

    input:
    tuple val(meta), path(fasta)
    val(autolineage)
    // val(db)

    output:
    tuple val(meta), path("*.tsv")  , emit: tsv
    path "versions.yml"             , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = fasta.name.endsWith('.gz') ? fasta.baseName : fasta.name
    def unzip   = fasta.getExtension() == "gz" ? "gunzip -c ${fasta} > ${input}" : ""
    def autolineage   = autolineage ? "--autolineage" : ""

    """
    ${unzip}
    mkdir -p ${prefix}/db
    compleasm run \\
        --threads ${task.cpus} \\
        --assembly_path ${input} \\
        --output_dir ${prefix} \\
        --library_path ${prefix}/db \\
        ${autolineage} \\
        ${args}
    rm -rv ${prefix}/db

    # Reformat output to VEBA standards
    reformat_compleasm_results.py \\
        -n ${prefix} \\
        -i ${prefix}/summary.txt \\
        -o ${prefix}.compleasm_results.tsv

    # Need to add cleanup of decompressed fasta if applicable

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        compleasm: \$(compleasm --version | cut -d' ' -f2)
        module: ${module_version}
    END_VERSIONS
"""
}
