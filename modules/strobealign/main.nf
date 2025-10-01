#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.5"

process STROBEALIGN {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::strobealign=0.16.1 bioconda::samtools=1.22.1"
    container "docker.io/jolespin/strobealign-samtools:strobealign0.16.1-samtools1.22.1"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(reference)
    val mode

    output:
    tuple val(meta), path('*.sorted.bam')     , optional: true, emit: bam
    tuple val(meta), path('*.sorted.bam.bai') , optional: true, emit: bai
    tuple val(meta), path('*.depth.tsv')      , optional: true, emit: depth
    tuple val(meta), path('*.paf.gz')         , optional: true, emit: paf
    tuple val(meta), path('*.abundance.tsv.gz'), optional: true, emit: abundance
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reads_input = reads instanceof List ? reads.join(' ') : reads
    
    // Handle gzipped reference files
    def reference_prep = ""
    def reference_file = reference
    def cleanup_cmd = ""
    
    if (reference.toString().endsWith('.gz')) {
        reference_file = "temp_reference.fa"
        reference_prep = "gunzip -c ${reference} > ${reference_file}"
        cleanup_cmd = "rm -f ${reference_file}"
    }
    
    if (mode == "bam") {
        """
        ${reference_prep}
        
        strobealign \\
            -t ${task.cpus} \\
            ${args} \\
            ${reference_file} \\
            ${reads_input} \\
            | samtools sort -@ ${task.cpus} -o ${prefix}.sorted.bam -

        samtools index -@ ${task.cpus} ${prefix}.sorted.bam

        samtools depth -@ ${task.cpus} ${prefix}.sorted.bam | gzip -n -v -f > ${prefix}.depth.tsv.gz

        ${cleanup_cmd}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            strobealign: \$(strobealign --version 2>&1 | head -n1 | sed 's/strobealign //')
            samtools: \$(samtools --version | head -n1 | sed 's/samtools //')
            module: ${module_version}
        END_VERSIONS
        """
    } else if (mode == "paf") {
        """
        ${reference_prep}
        
        strobealign \\
            -x \\
            -t ${task.cpus} \\
            ${args} \\
            ${reference_file} \\
            ${reads_input} \\
            | gzip -n -v -f > ${prefix}.paf.gz

        ${cleanup_cmd}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            strobealign: \$(strobealign --version 2>&1 | head -n1 | sed 's/strobealign //')
            module: ${module_version}
        END_VERSIONS
        """
    } else if (mode == "tsv") {
        """
        ${reference_prep}
        
        strobealign \\
            --aemb \\
            -t ${task.cpus} \\
            ${args} \\
            ${reference_file} \\
            ${reads_input} \\
            | gzip -n -v -f > ${prefix}.abundance.tsv.gz

        ${cleanup_cmd}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            strobealign: \$(strobealign --version 2>&1 | head -n1 | sed 's/strobealign //')
            module: ${module_version}
        END_VERSIONS
        """
    } else {
        error "Invalid mode: ${mode}. Must be one of: bam, paf, tsv"
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if [ "${mode}" == "bam" ]; then
        touch ${prefix}.sorted.bam
        touch ${prefix}.sorted.bam.bai
        touch ${prefix}.depth.tsv
    elif [ "${mode}" == "paf" ]; then
        touch ${prefix}.paf.gz
    elif [ "${mode}" == "tsv" ]; then
        touch ${prefix}.abundance.tsv.gz
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strobealign: \$(strobealign --version 2>&1 | head -n1 | sed 's/strobealign //' || echo "0.16.1")
        samtools: \$(samtools --version | head -n1 | sed 's/samtools //' || echo "1.22.1")
        module: ${module_version}
    END_VERSIONS
    """
}