#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.1"

process BARRNAP {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::barrnap=0.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/barrnap:0.9--hdfd78af_4':
        'biocontainers/barrnap:0.9--hdfd78af_4' }"

    input:
    tuple val(meta), path(fasta), val(dbname)

    output:
    tuple val(meta), path("*.gff.gz"), emit: gff
    tuple val(meta), path("*.rRNA.gz"), emit: fasta
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def db = dbname ? "${dbname}" : 'bac'
    def input_cmd = fasta.name.endsWith('.gz') ? "gzip -d -c ${fasta}" : "cat ${fasta}"
    """
    ${input_cmd} | \\
    barrnap \\
        $args \\
        --threads $task.cpus \\
        --kingdom $db \\
        --outseq ${prefix}.rRNA | \\
    awk '
    BEGIN { FS=OFS="\\t" }
    /^#/ { 
        print; next 
    }
    {
        # Extract fields
        contig_id = \$1
        start = \$4
        end = \$5
        strand = \$7
        description = \$9
        
        # Extract name from Name= field
        if (match(description, /Name=([^;]+)/, arr)) {
            name = arr[1]
        } else {
            name = "unknown"
        }
        
        # Create gene ID
        gene_id = name "::" contig_id ":" start "-" end "(" strand ")"
        
        # Print original line with additional attributes
        print \$0 ";ID=" gene_id ";contig_id=" contig_id ";gene_biotype=rRNA;"
    }' > ${prefix}.rRNA.gff

    # Compress both output files
    gzip -n -f ${prefix}.rRNA.gff ${prefix}.rRNA

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        barrnap: \$(echo \$(barrnap --version 2>&1) | sed 's/barrnap//; s/Using.*\$//' )
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.rRNA.gff.gz
    touch ${prefix}.rRNA.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        barrnap: \$(echo \$(barrnap --version 2>&1) | sed 's/barrnap//; s/Using.*\$//' )
        module: ${module_version}
    END_VERSIONS
    """
}