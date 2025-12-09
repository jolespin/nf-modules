process MEDAKA {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda:medaka=1.4.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:1.4.4--py38h130def0_0' :
        'quay.io/biocontainers/medaka:1.4.4--py38h130def0_0' }"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.fa.gz"), emit: assembly
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Handle gzipped reference files
    def decompress_cmd = ""
    def input_file = assembly
    def cleanup_cmd = ""
    
    if (assembly.toString().endsWith('.gz')) {
        basename = assembly.baseName
        input_file = basename
        decompress_cmd = "gunzip -c ${assembly} > ${input_file}"
        cleanup_cmd = "rm -f ${input_file}"
    }

    """
    ${decompress_cmd}

    medaka_consensus \\
        -t $task.cpus \\
        $args \\
        -i $reads \\
        -d $input_file \\
        -o ./

    mv consensus.fasta ${prefix}.fa
    gzip -n -f ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
