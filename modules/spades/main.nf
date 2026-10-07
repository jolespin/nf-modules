#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process SPADES {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::spades=4.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/7b/7b7b68c7f8471d9111841dbe594c00a41cdd3b713015c838c4b22705cfbbdfb2/data' :
        'community.wave.seqera.io/library/spades:4.1.0--77799c52e1d1054a' }"

    input:
    tuple val(meta), path(illumina), path(pacbio), path(nanopore)
    path hmm
    path yml
    val program

    output:
    tuple val(meta), path('*.scaffolds.fa.gz')    , emit: scaffolds, optional: true
    tuple val(meta), path('*.contigs.fa.gz')      , emit: contigs, optional: true
    tuple val(meta), path('*.transcripts.fa.gz')  , emit: transcripts, optional: true
    tuple val(meta), path('*.gene_clusters.fa.gz'), emit: gene_clusters, optional: true
    tuple val(meta), path('*.assembly.gfa.gz')    , emit: gfa, optional: true
    tuple val(meta), path('*.spades.log')         , emit: log
    tuple val(meta), path('*.warnings.log')       , emit: warnings, optional: true
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def maxmem = task.memory.toGiga()
    def illumina_reads = illumina ? ( meta.single_end ? "-s $illumina" : "-1 ${illumina[0]} -2 ${illumina[1]}" ) : ""
    def pacbio_reads = pacbio ? "--pacbio $pacbio" : ""
    def nanopore_reads = nanopore ? "--nanopore $nanopore" : ""
    def custom_hmms = hmm ? "--custom-hmms $hmm" : ""
    def reads = yml ? "--dataset $yml" : "$illumina_reads $pacbio_reads $nanopore_reads"
    def spades_program = program ?: 'spades.py' 
    """
    ${spades_program} \\
        $args \\
        --threads $task.cpus \\
        --memory $maxmem \\
        $custom_hmms \\
        $reads \\
        -o ./

    mv spades.log ${prefix}.spades.log

    # Rename scaffolds
    if [ -f scaffolds.fasta ]; then
        # // Add sample ID prefix to scaffold names
        # sed 's/^>/>'"${meta.id}"'__/' scaffolds.fasta > ${prefix}.scaffolds.fa

        mv -v scaffolds.fasta ${prefix}.scaffolds.fa
        gzip -f ${prefix}.scaffolds.fa
    fi
    
    # Rename contigs
    if [ -f contigs.fasta ]; then
        # // Add sample ID prefix to contig names
        # sed 's/^>/>'"${meta.id}"'__/' contigs.fasta > ${prefix}.contigs.fa

        mv -v contigs.fasta ${prefix}.contigs.fa
        gzip -f ${prefix}.contigs.fa

    fi

    # Rename transcripts
    if [ -f transcripts.fasta ]; then
        # sed 's/^>/>'"${meta.id}"'__/' transcripts.fasta > ${prefix}.transcripts.fa
        # gzip -f ${prefix}.transcripts.fa

        mv -v transcripts.fasta ${prefix}.transcripts.fa
        gzip -f ${prefix}.transcripts.fa
    fi

    # Rename gene clusters
    if [ -f gene_clusters.fasta ]; then
        # sed 's/^>/>'"${meta.id}"'__/' gene_clusters.fasta > ${prefix}.gene_clusters.fa
        # gzip -f ${prefix}.gene_clusters.fa

        mv -v gene_clusters.fasta ${prefix}.gene_clusters.fa
        gzip -f ${prefix}.gene_clusters.fa
    fi

    # Rename assembly graph
    if [ -f assembly_graph_with_scaffolds.gfa ]; then
        mv -v assembly_graph_with_scaffolds.gfa ${prefix}.assembly.gfa
        gzip -f ${prefix}.assembly.gfa
    fi

    # Process warnings (if exists)
    if [ -f warnings.log ]; then
        mv -v warnings.log ${prefix}.warnings.log
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed -n 's/^.*SPAdes genome assembler v//p')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.scaffolds.fa
    gzip ${prefix}.scaffolds.fa
    touch ${prefix}.contigs.fa
    gzip ${prefix}.contigs.fa
    touch ${prefix}.transcripts.fa
    gzip ${prefix}.transcripts.fa
    touch ${prefix}.gene_clusters.fa
    gzip ${prefix}.gene_clusters.fa
    touch ${prefix}.assembly.gfa
    gzip ${prefix}.assembly.gfa
    touch ${prefix}.spades.log
    touch ${prefix}.warnings.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed -n 's/^.*SPAdes genome assembler v//p')
    END_VERSIONS
    """
}