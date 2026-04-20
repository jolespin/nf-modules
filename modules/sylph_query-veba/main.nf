#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "v2026.4.20"

process SYLPH_QUERY {
    tag "${meta.id}"
    label 'process_high'

    container "docker.io/jolespin/sylph-veba:0.9.0"

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
    def is_single = meta.single_end
    
    // Safely create symlinks (checks to prevent linking a file to itself if names randomly match)
    def rename_bash = is_single 
        ? "[ \"${reads}\" != \"${prefix}.fastq.gz\" ] && ln -sf ${reads} ${prefix}.fastq.gz || true"
        : "[ \"${reads[0]}\" != \"${prefix}_1.fastq.gz\" ] && ln -sf ${reads[0]} ${prefix}_1.fastq.gz || true\n    [ \"${reads[1]}\" != \"${prefix}_2.fastq.gz\" ] && ln -sf ${reads[1]} ${prefix}_2.fastq.gz || true"
    
    // Construct tool arguments based on library type
    def input_args = is_single 
        ? "${prefix}.fastq.gz" 
        : "-1 ${prefix}_1.fastq.gz -2 ${prefix}_2.fastq.gz"

    // Get databases
    def db_list = db.collect{ file -> file.name }.join(" ")

    """
    # Stage files with sample prefix names
    ${rename_bash}

    # Run Sylph querying
    sylph query \\
        -t ${task.cpus} \\
        --estimate-unknown \\
        --debug \\
        ${args} \\
        ${db_list} \\
        ${input_args} \\
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
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """
}

process SYLPH_QUERY_MANY {
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

    // Process reads to generate renaming commands and arguments mapping
    def reads_list = reads instanceof List ? reads : [reads]
    def r1_files = []
    def r2_files = []
    def rename_cmds = []

    int read_idx = 0
    for (int i = 0; i < sample_metas.size(); i++) {
        def sample_id = sample_metas[i].id
        if (sample_metas[i].single_end) {
            def r1 = reads_list[read_idx]
            def new_name = "${sample_id}.fastq.gz"
            rename_cmds << "[ \"${r1}\" != \"${new_name}\" ] && ln -sf ${r1} ${new_name} || true"
            r1_files.add(new_name)
            read_idx += 1
        } else {
            def r1 = reads_list[read_idx]
            def r2 = reads_list[read_idx + 1]
            def new_r1 = "${sample_id}_1.fastq.gz"
            def new_r2 = "${sample_id}_2.fastq.gz"
            rename_cmds << "[ \"${r1}\" != \"${new_r1}\" ] && ln -sf ${r1} ${new_r1} || true"
            rename_cmds << "[ \"${r2}\" != \"${new_r2}\" ] && ln -sf ${r2} ${new_r2} || true"
            r1_files.add(new_r1)
            r2_files.add(new_r2)
            read_idx += 2
        }
    }
    
    def rename_bash = rename_cmds.join('\n    ')
    def db_list = db.collect{ file -> file.name }.join(' ')

    // Build input arguments safely supporting a fully single-end vs paired-end batch
    def input_args = r2_files.isEmpty() ? "${r1_files.join(' ')}" : "-1 ${r1_files.join(' ')} -2 ${r2_files.join(' ')}"

    // Create mapping entries for bash printf. r1_files now correctly holds the new prefixed names.
    def sample_ids = sample_metas.collect { it.id }
    def mapping_lines = [r1_files, sample_ids].transpose().collect { r1, id -> "printf '${r1}\\t${id}\\n' >> sample_mapping.tsv" }.join('\n')

    """
    # Stage files with sample prefix names
    ${rename_bash}

    # Create R1 filename -> Sample ID mapping file
    ${mapping_lines}

    # Run Sylph querying
    sylph query \\
        -t ${task.cpus} \\
        --estimate-unknown \\
        --debug \\
        ${args} \\
        ${db_list} \\
        ${input_args} \\
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

process SYLPH_QUERY_WITH_TAXONOMY {
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
    def is_single = meta.single_end
    
    // Safely create symlinks
    def rename_bash = is_single 
        ? "[ \"${reads}\" != \"${prefix}.fastq.gz\" ] && ln -sf ${reads} ${prefix}.fastq.gz || true"
        : "[ \"${reads[0]}\" != \"${prefix}_1.fastq.gz\" ] && ln -sf ${reads[0]} ${prefix}_1.fastq.gz || true\n    [ \"${reads[1]}\" != \"${prefix}_2.fastq.gz\" ] && ln -sf ${reads[1]} ${prefix}_2.fastq.gz || true"
    
    def input_args = is_single 
        ? "${prefix}.fastq.gz" 
        : "-1 ${prefix}_1.fastq.gz -2 ${prefix}_2.fastq.gz"

    // Get databases
    def db_name_list = db_name.join(" ")
    def db_list = db.collect{ file -> file.name }.join(" ")
    def taxonomy_list = taxonomy.collect{ file -> file.name }.join(" ")

    """
    # Stage files with sample prefix names
    ${rename_bash}

    # Run Sylph querying
    sylph query \\
        -t ${task.cpus} \\
        --estimate-unknown \\
        --debug \\
        ${args} \\
        ${db_list} \\
        ${input_args} \\
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
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.tsv.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sylph: \$(sylph -V | awk '{print \$2}')
    END_VERSIONS
    """
}

process SYLPH_QUERY_MANY_WITH_TAXONOMY {
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

    // Process reads to generate renaming commands
    def reads_list = reads instanceof List ? reads : [reads]
    def r1_files = []
    def r2_files = []
    def rename_cmds = []

    int read_idx = 0
    for (int i = 0; i < sample_metas.size(); i++) {
        def sample_id = sample_metas[i].id
        if (sample_metas[i].single_end) {
            def r1 = reads_list[read_idx]
            def new_name = "${sample_id}.fastq.gz"
            rename_cmds << "[ \"${r1}\" != \"${new_name}\" ] && ln -sf ${r1} ${new_name} || true"
            r1_files.add(new_name)
            read_idx += 1
        } else {
            def r1 = reads_list[read_idx]
            def r2 = reads_list[read_idx + 1]
            def new_r1 = "${sample_id}_1.fastq.gz"
            def new_r2 = "${sample_id}_2.fastq.gz"
            rename_cmds << "[ \"${r1}\" != \"${new_r1}\" ] && ln -sf ${r1} ${new_r1} || true"
            rename_cmds << "[ \"${r2}\" != \"${new_r2}\" ] && ln -sf ${r2} ${new_r2} || true"
            r1_files.add(new_r1)
            r2_files.add(new_r2)
            read_idx += 2
        }
    }
    
    def rename_bash = rename_cmds.join('\n    ')
    def db_name_list = db_name.join(" ")
    def db_list = db.collect{ file -> file.name }.join(' ')
    def taxonomy_list = taxonomy.collect{ file -> file.name }.join(" ")

    // Build input arguments
    def input_args = r2_files.isEmpty() ? "${r1_files.join(' ')}" : "-1 ${r1_files.join(' ')} -2 ${r2_files.join(' ')}"

    // Create mapping entries for bash printf
    def sample_ids = sample_metas.collect { it.id }
    def mapping_lines = [r1_files, sample_ids].transpose().collect { r1, id -> "printf '${r1}\\t${id}\\n' >> sample_mapping.tsv" }.join('\n')

    """
    # Stage files with sample prefix names
    ${rename_bash}

    # Create R1 filename -> Sample ID mapping file
    ${mapping_lines}

    # Run Sylph querying
    sylph query \\
        -t ${task.cpus} \\
        --estimate-unknown \\
        --debug \\
        ${args} \\
        ${db_list} \\
        ${input_args} \\
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