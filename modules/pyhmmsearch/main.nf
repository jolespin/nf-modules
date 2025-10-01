#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.4"

process PYHMMSEARCH {
    tag "$meta.id---$dbmeta.id"
    label 'process_medium'

    conda "bioconda::pyhmmsearch=2025.9.5"
    container "docker.io/jolespin/pyhmmsearch:2025.9.5"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/pyhmmsearch:2025.9.4.post1--pyh7e72e81_0' :
    //     'biocontainers/pyhmmsearch:2025.9.4.post1--pyh7e72e81_0' }"

    input:
    tuple(val(meta), path(fasta))
    tuple(val(dbmeta), path(db))
    val(write_reformatted_output)
    val(write_target)
    val(write_domain)

    output:
    tuple val(meta), val(dbmeta), path('*.tsv.gz')   , emit: output
    tuple val(meta), val(dbmeta), path('*.reformatted.tsv.gz')   , emit: reformatted_output    , optional: true
    tuple val(meta), val(dbmeta), path('*.tblout.gz'), emit: tblout, optional: true
    tuple val(meta), val(dbmeta), path('*.domtblout.gz'), emit: domtblout, optional: true
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}---${dbmeta.id}"
    
    // Handle different input scenarios for FASTA files
    def concatenation_cmd = ""
    if (fasta instanceof List) {
        // Multiple files - determine if they're compressed and create appropriate concatenation command
        def compressed_files = fasta.findAll { it.name.endsWith('.gz') }
        def uncompressed_files = fasta.findAll { !it.name.endsWith('.gz') }
        
        if (compressed_files.size() > 0 && uncompressed_files.size() > 0) {
            // Mixed compressed and uncompressed files
            concatenation_cmd = """
            # Handle mixed compressed and uncompressed files
            for fasta in ${compressed_files.join(' ')}; do
                zcat \$fasta >> concatenated_input.fasta
            done
            for fasta in ${uncompressed_files.join(' ')}; do
                cat \$fasta >> concatenated_input.fasta
            done
            """
        } else if (compressed_files.size() > 0) {
            // All compressed files
            concatenation_cmd = """
            # Handle all compressed files
            zcat ${compressed_files.join(' ')} > concatenated_input.fasta
            """
        } else {
            // All uncompressed files
            concatenation_cmd = """
            # Handle all uncompressed files
            cat ${uncompressed_files.join(' ')} > concatenated_input.fasta
            """
        }
    } else {
        // Single file
        if (fasta.name.endsWith('.gz')) {
            concatenation_cmd = """
            # Handle single compressed file
            zcat ${fasta} > concatenated_input.fasta
            """
        } else {
            concatenation_cmd = """
            # Handle single uncompressed file
            cat ${fasta} > concatenated_input.fasta
            """
        }
    }


    def tblout_argument = write_target ? "--tblout ${prefix}.tblout.gz" : ""
    def domtblout_argument = write_target ? "--domtblout ${prefix}.domtblout.gz" : ""
    def reformat_command = write_reformatted_output ? "reformat_pyhmmsearch -i ${prefix}.tsv -o ${prefix}.reformatted.tsv.gz" : ''

    """
    # Create temporary file
    ${concatenation_cmd}

    # Run PyHMMSearch
    pyhmmsearch \\
        $args \\
        --n_jobs $task.cpus \\
        -d $db \\
        -i concatenated_input.fasta \\
        ${tblout_argument} \\
        ${domtblout_argument} \\
        -o ${prefix}.tsv

    # Remove temporary file
    rm -v concatenated_input.fasta

    # Run reformat script
    ${reformat_command}

    # Gzip main output
    gzip -n -f ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyhmmsearch: \$(pyhmmsearch --version)
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}--${dbmeta.id}"
    """
    touch "${prefix}.tsv.gz"
    ${write_reformatted_output ? "touch ${prefix}.reformatted.tsv.gz" : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pyhmmsearch: \$(pyhmmsearch --version)
        module: ${module_version}
    END_VERSIONS
    """
}