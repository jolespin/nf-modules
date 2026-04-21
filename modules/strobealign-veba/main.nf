#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2026.4.20"

process STROBEALIGN_WRAPPER {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::strobealign=0.17.0 jolespin::fastq_preprocess=2026.4.20"
    container "docker.io/jolespin/fastq_preprocessor:2026.4.20"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(reference)
    val save_mapped_reads
    val save_unmapped_reads
    val save_bam
    path contigs_to_genomes

    output:
    tuple val(meta), path('*.sorted.bam')         , optional: true, emit: bam
    tuple val(meta), path('*.sorted.bam.bai')     , optional: true, emit: bai
    tuple val(meta), path('*.depth.tsv')          , optional: true, emit: depth
    tuple val(meta), path('*.coverage.tsv')       , optional: true, emit: coverage
    tuple val(meta), path('*.breadth.tsv')       , optional: true, emit: breadth
    tuple val(meta), path('*.mapped_*.fastq.gz')  , optional: true, emit: mapped_fastq
    tuple val(meta), path('*.unmapped_*.fastq.gz'), optional: true, emit: unmapped_fastq

    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bam_args = save_bam ? "--bam ${prefix}.mapped.sorted.bam --depth --coverage" : ""
    def mapped_args = save_mapped_reads ? "--mapped_fastq ${prefix}.mapped_%.fastq.gz" : ""
    def unmapped_args = save_unmapped_reads ? "--unmapped_fastq ${prefix}.unmapped_%.fastq.gz" : ""
    def reads_input = [reads].flatten().join(' ')
    def contigs_arg = contigs_to_genomes ? "--contigs_to_genomes ${contigs_to_genomes}" : ""
    def breadth_command = save_bam ? "coverage_breadth --depth ${prefix}.mapped.sorted.bam.depth.tsv -o ${prefix}.mapped.sorted.bam.breadth.tsv ${contigs_arg}" : ""
    """
    # strobealign
    strobealign_wrapper \\
        ${bam_args} \\
        ${mapped_args} \\
        ${unmapped_args} \\
        -t ${task.cpus} \\
        --temporary_directory tmp \\
        ${args} \\
        ${reference} \\
        ${reads_input}

    # coverage breadth
    ${breadth_command}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strobealign: \$(strobealign --version 2>&1 | head -n1 | sed 's/strobealign //')
        fastq_preprocessor: \$(fastq_preprocessor --version | head -n1 | sed 's/fastq_preprocessor //')
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def stub_bam = save_bam ? "touch ${prefix}.sorted.bam ${prefix}.sorted.bam.bai ${prefix}.sorted.bam.depth.tsv ${prefix}.sorted.bam.coverage.tsv ${prefix}.sorted.bam.breadth.tsv" : ""
    def stub_mapped = save_mapped_reads ? "touch ${prefix}.mapped_1.fastq.gz ${prefix}.mapped_2.fastq.gz" : ""
    def stub_unmapped = save_unmapped_reads ? "touch ${prefix}.unmapped_1.fastq.gz ${prefix}.unmapped_2.fastq.gz" : ""
    """
    ${stub_bam}
    ${stub_mapped}
    ${stub_unmapped}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strobealign: 0.17.0
        fastq_preprocessor: 2026.4.17
        module: ${module_version}
    END_VERSIONS
    """
}