#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.12.8"

process PYKOFAMSEARCH {
    tag "$meta.id---$dbmeta.id"
    label 'process_medium'

    conda "bioconda::pykofamsearch=2025.9.5"
    container "docker.io/jolespin/pykofamsearch:2025.9.5"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/pykofamsearch:2024.11.9--pyhdfd78af_0' :
    //     'biocontainers/pykofamsearch:2024.11.9--pyhdfd78af_0' }"

    input:
    tuple(val(meta), path(fasta))
    tuple(val(dbmeta), path(db))
    val(write_reformatted_output)
    val(is_serialized_database)


    output:
    tuple val(meta), val(dbmeta), path('*.output.tsv.gz')               , emit: output
    tuple val(meta), val(dbmeta), path('*.reformatted.tsv.gz')   , emit: reformatted_output    , optional: true
    path "versions.yml"                                                  , emit: versions

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

    def database_argument = is_serialized_database ? "-b ${db}" : "-d ${db}"
    def reformat_command = write_reformatted_output ? "reformat_pykofamsearch -i ${prefix}.output.tsv -o ${prefix}.reformatted.tsv.gz" : ''

    """
    # Create temporary file
    ${concatenation_cmd}

    # Run PyKOfamSearch
    pykofamsearch \\
        $args \\
        --n_jobs $task.cpus \\
        ${database_argument} \\
        -i concatenated_input.fasta \\
        -o ${prefix}.output.tsv

    # Remove temporary file
    rm -v concatenated_input.fasta

    # Run reformat script
    ${reformat_command}

    # Gzip main output
    gzip -n -f ${prefix}.output.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pykofamsearch: \$(pykofamsearch --version)
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}--${dbmeta.id}"
    """
    touch "${prefix}.output.tsv.gz"
    ${write_reformatted_output ? "touch ${prefix}.reformatted.tsv.gz" : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pykofamsearch: \$(pykofamsearch --version)
        module: ${module_version}
    END_VERSIONS
    """
}