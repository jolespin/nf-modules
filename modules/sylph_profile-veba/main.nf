#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "v2025.1.21"

process SYLPH_PROFILE {
    tag "${meta.id}"
    label 'process_high'

    container "docker.io/jolespin/sylph-veba:0.9.0"
    // container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
    //     ? 'https://depot.galaxyproject.org/singularity/sylph:0.9.0--ha6fb395_0'
    //     : 'quay.io/biocontainers/sylph:0.9.0--ha6fb395_0'}"

    input:
    tuple val(meta), path(reads)
    path(db)

    output:
    tuple val(meta), path('*.tsv.gz'), emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = meta.single_end ? "${reads}" : "-1 ${reads[0]} -2 ${reads[1]}"

    // Get databases
    def db_list = db.collect{ file -> file.name }.join(" ")

    """
    # Run Sylph profiling
    sylph profile \\
        -t ${task.cpus} \\
        ${args} \\
        ${db_list} \\
        ${input} \\
        -o ${prefix}_raw.tsv

    # Add Sample column with meta.id
    awk -F'\\t' 'BEGIN {OFS="\\t"}
    NR==1 {
        print "Sample", \$0
        next
    }
    {
        print "${meta.id}", \$0
    }' ${prefix}_raw.tsv > ${prefix}.tsv

    # Compress output
    gzip -n -v ${prefix}.tsv

    # Clean up
    rm ${prefix}_raw.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = meta.single_end ? "${reads}" : "-1 ${reads[0]} -2 ${reads[1]}"

    """
    touch ${prefix}.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """
}

process SYLPH_PROFILE_MANY {
    tag "${batch_meta.id}"
    label 'process_high'

    container "docker.io/jolespin/sylph-veba:0.9.0"

    input:
    tuple val(batch_meta), val(sample_metas), path(reads)
    path(db)

    output:
    tuple val(batch_meta), val(sample_metas), path('*.tsv.gz'), emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${batch_meta.id}"

    // Split reads into R1 and R2 lists (assumes paired-end with reads as [R1, R2, R1, R2, ...])
    def reads_list = reads instanceof List ? reads : [reads]
    def r1_files = []
    def r2_files = []
    for (int i = 0; i < reads_list.size(); i += 2) {
        r1_files.add(reads_list[i].name)
        r2_files.add(reads_list[i+1].name)
    }
    def r1_list = r1_files.join(' ')
    def r2_list = r2_files.join(' ')
    def db_list = db.collect{ file -> file.name }.join(' ')

    // Create mapping entries for bash printf
    def sample_ids = sample_metas.collect { it.id }
    def mapping_lines = [r1_files, sample_ids].transpose().collect { r1, id -> "printf '${r1}\\t${id}\\n' >> sample_mapping.tsv" }.join('\n')

    """
    # Create R1 filename -> Sample ID mapping file
    ${mapping_lines}

    # Run Sylph profiling
    sylph profile \\
        -t ${task.cpus} \\
        ${args} \\
        ${db_list} \\
        -1 ${r1_list} \\
        -2 ${r2_list} \\
        -o ${prefix}_raw.tsv

    # Add Sample column using awk
    awk -F'\\t' 'BEGIN {OFS="\\t"}
    NR==FNR {
        map[\$1] = \$2
        next
    }
    FNR==1 {
        print "Sample", \$0
        next
    }
    {
        sample_id = map[\$1]
        print sample_id, \$0
    }' sample_mapping.tsv ${prefix}_raw.tsv > ${prefix}.tsv    

    # Compress final output
    gzip -n -v ${prefix}.tsv

    # Clean up
    rm ${prefix}_raw.tsv sample_mapping.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${batch_meta.id}"
    """
    touch ${prefix}.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """
}

process SYLPH_PROFILE_WITH_TAXONOMY {
    tag "${meta.id}"
    label 'process_high'

    container "docker.io/jolespin/sylph-veba:0.9.0"

    input:
    tuple val(meta), path(reads)
    tuple val(db_name), path(db), path(taxonomy)

    output:
    tuple val(meta), path('*.tsv.gz'), emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = meta.single_end ? "${reads}" : "-1 ${reads[0]} -2 ${reads[1]}"

    // Get databases
    def db_name_list = db_name.join(" ")
    def db_list = db.collect{ file -> file.name }.join(" ")
    def taxonomy_list = taxonomy.collect{ file -> file.name }.join(" ")

    """
    # Run Sylph profiling
    sylph profile \\
        -t ${task.cpus} \\
        ${args} \\
        ${db_list} \\
        ${input} \\
        -o ${prefix}_raw.tsv

    # Add Sample column with meta.id
    awk -F'\\t' 'BEGIN {OFS="\\t"}
    NR==1 {
        print "Sample", \$0
        next
    }
    {
        print "${meta.id}", \$0
    }' ${prefix}_raw.tsv > ${prefix}.tsv

    # Append taxonomy and overwrite
    append_taxonomy_to_sylph_profile.py -i ${prefix}.tsv -o ${prefix}.tsv -t ${taxonomy_list} -n ${db_name_list}

    # Compress output
    gzip -n -v ${prefix}.tsv

    # Clean up
    rm ${prefix}_raw.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input = meta.single_end ? "${reads}" : "-1 ${reads[0]} -2 ${reads[1]}"

    """
    touch ${prefix}.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """
}

process SYLPH_PROFILE_MANY_WITH_TAXONOMY {
    tag "${batch_meta.id}"
    label 'process_high'

    container "docker.io/jolespin/sylph-veba:0.9.0"

    input:
    tuple val(batch_meta), val(sample_metas), path(reads)
    tuple val(db_name), path(db), path(taxonomy)

    output:
    tuple val(batch_meta), val(sample_metas), path('*.tsv.gz'), emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${batch_meta.id}"

    // Split reads into R1 and R2 lists
    def reads_list = reads instanceof List ? reads : [reads]
    def r1_files = []
    def r2_files = []
    for (int i = 0; i < reads_list.size(); i += 2) {
        r1_files.add(reads_list[i].name)
        r2_files.add(reads_list[i+1].name)
    }
    def r1_list = r1_files.join(' ')
    def r2_list = r2_files.join(' ')
    def db_name_list = db_name.join(" ")
    def db_list = db.collect{ file -> file.name }.join(' ')
    def taxonomy_list = taxonomy.collect{ file -> file.name }.join(" ")

    // Create mapping entries for bash printf
    def sample_ids = sample_metas.collect { it.id }
    def mapping_lines = [r1_files, sample_ids].transpose().collect { r1, id -> "printf '${r1}\\t${id}\\n' >> sample_mapping.tsv" }.join('\n')

    """
    # Create R1 filename -> Sample ID mapping file
    ${mapping_lines}

    # Run Sylph profiling
    sylph profile \\
        -t ${task.cpus} \\
        ${args} \\
        ${db_list} \\
        -1 ${r1_list} \\
        -2 ${r2_list} \\
        -o ${prefix}_raw.tsv

    # Add Sample column using awk
    awk -F'\\t' 'BEGIN {OFS="\\t"}
    NR==FNR {
        map[\$1] = \$2
        next
    }
    FNR==1 {
        print "Sample", \$0
        next
    }
    {
        sample_id = map[\$1]
        print sample_id, \$0
    }' sample_mapping.tsv ${prefix}_raw.tsv > ${prefix}.tsv

    # Append taxonomy and overwrite
    append_taxonomy_to_sylph_profile.py -i ${prefix}.tsv -o ${prefix}.tsv -t ${taxonomy_list} -n ${db_name_list}

    # Compress final output
    gzip -n -v ${prefix}.tsv

    # Clean up
    rm ${prefix}_raw.tsv sample_mapping.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${batch_meta.id}"
    """
    touch ${prefix}.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """
}