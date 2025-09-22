#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.22"

process TIARA {
    tag "$meta.id"
    label 'process_medium'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    container "docker.io/jolespin/tiara-veba:1.0.3"


    input:
    tuple val(meta), path(fasta)
    val(write_fasta)
    val(minimum_contig_length)
    // val(scaffolds_to_bins) // Future versions may support multi-fasta

    output:
    tuple val(meta), path("*.probabilities.tsv.gz")  , emit: probabilities
    tuple val(meta), path("*.log")      , emit: log
    tuple val(meta), path("*.predictions.tsv.gz")  , emit: predictions
    tuple val(meta), path("*.fasta.gz")          , emit: fasta, optional: true
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def VERSION = '1.0.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def write_fasta_flag = write_fasta ? "--to_fasta all" : ""
    def input = fasta
    def decompress_fasta = ""
    def cleanup = ""

    if (fasta.toString().endsWith('.gz')) {
        input = "temporary.fasta"
        decompress_fasta = "gunzip -c ${fasta} > ${input}"
        cleanup = "rm -f ${input}"
    }
    
    """
    # Prepare fasta file if gzipped
    ${decompress_fasta}

    # Scaffolds to genome
    grep "^>" "${input}" | sed 's/^>//' | awk -v prefix="${prefix}" '{print \$1"\\t"prefix}' > scaffolds_to_genomes.tsv

    # Run Tiara
    tiara -i ${input} \\
        -o ${prefix}.probabilities.tsv \\
        --threads ${task.cpus} \\
        --probabilities \\
        -m ${minimum_contig_length} \\
        ${write_fasta_flag} \\
        ${args}

    # Check if Tiara did not gzip files and gzip them. Also change the log filename.
    if ! echo "${args}" | grep -q -- "--gz"; then

        # Change log filename
        mv -v log_${prefix}.probabilities.tsv ${prefix}.log

        # Gzip probabilities
        gzip -v -n -f ${prefix}.probabilities.tsv

        # Gzip fasta files if they were created
        if echo "${write_fasta_flag}" | grep -qE "to_fasta"; then
            # Look for actual fasta files created by Tiara
            shopt -s nullglob
            for fasta_file in *_${prefix}.fasta; do
                gzip -v -n -f "\$fasta_file"
            done
            shopt -u nullglob
        fi

    else
        # Change log filename
        mv -v log_${prefix}.probabilities.tsv.gz ${prefix}.log

    fi

    # Adjust gzip file extensions for fasta
    # Enable nullglob: makes globs that match no files expand to nothing instead of the literal pattern
    shopt -s nullglob
    for filepath in *_${prefix}.fasta.gz; do
        dir=\$(dirname "\$filepath")
        # Extract domain name (everything before _${prefix})
        domain=\$(basename "\$filepath" "_${prefix}.fasta.gz")
        mv -- "\$filepath" "\$dir/\${domain}.tiara.fasta.gz"
    done
    # Disable nullglob: restore default behavior where unmatched globs remain as literal strings
    shopt -u nullglob

    # Domain classification
    consensus_domain_classification.py -i scaffolds_to_genomes.tsv -t ${prefix}.probabilities.tsv.gz -l softmax -o domains
    mv  domains/predictions.tsv ${prefix}.predictions.tsv
    gzip -v -n -f ${prefix}.predictions.tsv

    # Remove temporary files
    ${cleanup}
    rm -v -f scaffolds_to_genomes.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiara: ${VERSION}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.0.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    touch ${prefix}.probabilities.tsv.gz
    touch ${prefix}.log
    touch ${prefix}.bacteria.fasta.gz
    touch ${prefix}.predictions.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiara: ${VERSION}
    END_VERSIONS
    """
}