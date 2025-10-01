#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.1"

process CHECKM2_PREDICT {
    tag "${meta.id}"
    label 'process_medium'

    conda "bioconda::checkm2-1.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0a/0af812c983aeffc99c0fca9ed2c910816b2ddb9a9d0dcad7b87dab0c9c08a16f/data':
        'community.wave.seqera.io/library/checkm2:1.1.0--60f287bc25d7a10d' }"

    input:
    tuple val(meta), path(fasta, stageAs: "input_bins/*")
    tuple val(dbmeta), path(db)
    val genes

    output:
    tuple val(meta), path("${prefix}")                   , emit: checkm2_output
    tuple val(meta), path("${prefix}_checkm2_report.tsv"), emit: checkm2_tsv
    path("versions.yml")                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def genes_flag = genes ? '--genes' : ''
    prefix = task.ext.prefix ?: "${meta.id}"
    
    // Determine file extension and processing based on genes flag
    def target_extension = genes ? '.faa' : '.fa'
    def extension_flag = genes ? '--extension .faa' : '--extension .fa'
    
    """
    # Process files in-place in the input_bins directory
    for file in input_bins/*; do
        if [[ -f "\$file" ]]; then
            basename_file=\$(basename "\$file")
            
            # Check if file is gzipped
            if [[ "\$basename_file" == *.gz ]]; then
                # Remove .gz extension to get base name
                base_name=\${basename_file%.gz}
                # Remove existing extension and add target extension
                new_name=\${base_name%.*}${target_extension}
                
                # Decompress and rename
                gunzip -c "\$file" > "input_bins/\$new_name"
                # Remove original gzipped file
                rm "\$file"
            else
                # File is not gzipped, check if it already has the correct extension
                if [[ "\$basename_file" != *${target_extension} ]]; then
                    base_name=\${basename_file%.*}
                    new_name=\${base_name}${target_extension}
                    
                    # Copy to new name and remove original
                    cp "\$file" "input_bins/\$new_name"
                    rm "\$file"
                fi
            fi
        fi
    done

    checkm2 \\
        predict \\
        --input input_bins \\
        --output-directory ${prefix} \\
        --threads ${task.cpus} \\
        --database_path ${db} \\
        ${genes_flag} \\
        ${extension_flag} \\
        ${args}

    cp ${prefix}/quality_report.tsv ${prefix}_checkm2_report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$(checkm2 --version)
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}/
    touch ${prefix}_checkm2_report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$(checkm2 --version)
        module: ${module_version}
    END_VERSIONS
    """
}