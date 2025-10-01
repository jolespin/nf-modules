#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.4"

process DIAMOND_BLASTP {
    tag "${meta.id}---${dbmeta.id}"
    label 'process_high'

    conda "bioconda::diamond=2.1.12"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/diamond:2.1.12--hdb4b4cc_1'
        : 'biocontainers/diamond:2.1.12--hdb4b4cc_1'}"

    input:
    tuple val(meta), path(fasta)
    tuple val(dbmeta), path(db)
    val outfmt
    val blast_columns
    
    output:
    tuple val(meta), val(dbmeta), path("*.{txt.gz,tsv.gz}"), emit: results
    path "versions.yml", emit: versions
    
    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}---${dbmeta.id}"
    def columns = blast_columns ? "${blast_columns}" : ''
    def extension = outfmt == 6 ? "tsv" : "txt"
    
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

    """
    ${concatenation_cmd}

    # Run DIAMOND BLASTP
    diamond \\
        blastp \\
        --threads ${task.cpus} \\
        --db ${db} \\
        --query concatenated_input.fasta \\
        --outfmt ${outfmt} ${columns} \\
        --max-target-seqs 1 \\
        ${args} \\
        --out ${prefix}.${extension} \\
        --header simple

    # Gzip the output
    gzip -n -f ${prefix}.${extension}

    # Clean up temporary file
    rm -f concatenated_input.fasta
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        diamond: \$(diamond --version 2>&1 | tail -n 1 | sed 's/^diamond version //')
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}---${dbmeta.id}"
    def extension = outfmt == 6 ? "tsv" : "txt"
    
    """
    touch ${prefix}.${extension}.gz
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        diamond: \$(diamond --version 2>&1 | tail -n 1 | sed 's/^diamond version //')
        module: ${module_version}
    END_VERSIONS
    """
}

// process DIAMOND_BLASTP_WITH_CONCATENATION {
//     tag "${meta.id}---${dbmeta.id}"
//     label 'process_high'

//     conda "bioconda::diamond=2.1.12"
//     container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
//         ? 'https://depot.galaxyproject.org/singularity/diamond:2.1.12--hdb4b4cc_1'
//         : 'biocontainers/diamond:2.1.12--hdb4b4cc_1'}"

//     input:
//     tuple val(meta), path(fasta)
//     tuple val(dbmeta), path(db)
//     val outfmt
//     val blast_columns
    
//     output:
//     tuple val(meta), val(dbmeta), path("*.{txt.gz,tsv.gz}"), emit: results
//     path "versions.yml", emit: versions
    
//     script:
//     def args = task.ext.args ?: ''
//     def prefix = task.ext.prefix ?: "${meta.id}---${dbmeta.id}"
//     def columns = blast_columns ? "${blast_columns}" : ''
//     def extension = outfmt == 6 ? "tsv" : "txt"
    
//     """
//     # Create temporary concatenated file (BusyBox compatible)
//     TEMP_FASTA=\$(mktemp)
    
//     # Concatenate all FASTA files (handle both gzipped and uncompressed)
//     for fasta in ${fasta.join(' ')}; do
//         if [[ \$fasta == *.gz ]]; then
//             zcat \$fasta >> \$TEMP_FASTA
//         else
//             cat \$fasta >> \$TEMP_FASTA
//         fi
//     done
    
//     # Run DIAMOND BLASTP
//     diamond \\
//         blastp \\
//         --threads ${task.cpus} \\
//         --db ${db} \\
//         --query \$TEMP_FASTA \\
//         --outfmt ${outfmt} ${columns} \\
//         --max-target-seqs 1 \\
//         ${args} \\
//         --out ${prefix}.${extension} \\
//         --header simple

//     # Gzip
//     gzip -n -f -v ${prefix}.${extension}

//     # Clean up temporary file
//     rm \$TEMP_FASTA
    
//     cat <<-END_VERSIONS > versions.yml
//     "${task.process}":
//         diamond: \$(diamond --version 2>&1 | tail -n 1 | sed 's/^diamond version //')
//         module: ${module_version}
//     END_VERSIONS
//     """

//     stub:
//     def prefix = task.ext.prefix ?: "${meta.id}---${dbmeta.id}"
//     def extension = outfmt == 6 ? "tsv" : "txt"
    
//     """
//     touch ${prefix}.${extension}.gz
    
//     cat <<-END_VERSIONS > versions.yml
//     "${task.process}":
//         diamond: \$(diamond --version 2>&1 | tail -n 1 | sed 's/^diamond version //')
//         module: ${module_version}
//     END_VERSIONS
//     """
// }