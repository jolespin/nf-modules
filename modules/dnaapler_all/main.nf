#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process DNAAPLER_ALL {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::dnaapler=1.4.0 bioconda::seqkit=2.14.0"
    container "docker.io/jolespin/dnaapler:1.4.0"

    input:
    tuple val(meta), path(assembly_graph)
    val min_contig_length           // default: 1000

    output:
    tuple val(meta), path("*.dnaapler.fa.gz")                    , emit: fasta
    tuple val(meta), path("*.dnaapler.gfa.gz")                   , emit: gfa
    tuple val(meta), path("*.dnaapler.discarded-contigs.fa.gz")  , emit: discarded_contigs
    tuple val(meta), path("*.log")                               , emit: log
    path "versions.yml"                                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    # Run
    dnaapler all \\
         $args \\
         -i ${assembly_graph} \\
         -p ${meta.id} \\
         -o output \\
         -f \\
         -t ${task.cpus}

    # Move files
    mv -v output/* .

    # Filter
    seqkit seq -M \$((${min_contig_length} - 1)) ${meta.id}_reoriented.fasta > ${meta.id}.dnaapler.discarded-contigs.fa    
    seqkit seq -m ${min_contig_length} ${meta.id}_reoriented.fasta > ${meta.id}.dnaapler.fa

    # Rename
    mv -v ${meta.id}_reoriented.gfa ${meta.id}.dnaapler.gfa
    mv -v ${meta.id}_MMseqs2_output.txt ${meta.id}.mmseqs2_output.tsv
    mv -v ${meta.id}_all_reorientation_summary.tsv ${meta.id}.dnaapler_reorientation_summary.tsv



    # Gzip
    gzip -v -n *.tsv *.gfa *.fa

    # Cleanup
    rm -v ${meta.id}_reoriented.fasta
    rm -rv output/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dnaapler: \$(dnaapler --version 2>&1 | sed 's/.*version //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.dnaapler.fa.gz
    touch ${prefix}.dnaapler.gfa.gz
    touch ${prefix}.dnaapler.discarded-contigs.fa.gz
    touch ${prefix}.dnaapler.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dnaapler: \$(dnaapler --version 2>&1 | sed 's/.*version //')
    END_VERSIONS
    """
}
