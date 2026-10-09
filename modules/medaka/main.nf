nextflow.enable.dsl = 2

process MEDAKA {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda:medaka=2.2.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:2.2.2--py312h3050eb1_0' :
        'quay.io/biocontainers/medaka:2.2.2--py312h3050eb1_0' }"

    input:
    tuple val(meta), path(reads), path(assembly)
    val model // "auto" for basecaller auto-detection, or an explicit medaka model name

    output:
    tuple val(meta), path("*.medaka.fa.gz"), emit: assembly
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
    export HOME=\$PWD
    ${decompress_cmd}

    if [ "${model}" = "auto" ]; then
        echo "Attempting to auto-detect basecalling model from reads..."
        MEDAKA_MODEL=\$(medaka tools resolve_model --auto_model consensus ${reads} 2>/dev/null || true)
        if [ -z "\$MEDAKA_MODEL" ]; then
            echo "ERROR: Failed to auto-detect basecalling model from reads."
            echo "This can happen when FASTQ headers lack basecaller metadata."
            echo ""
            echo "Available medaka models:"
            medaka tools list_models 2>&1 | head -1 | sed 's/^Available: //' | tr ',' '\\n' | sed 's/^ *//'
            echo ""
            echo "Please specify a model explicitly instead of 'auto'."
            exit 1
        fi
        echo "Auto-detected model: \$MEDAKA_MODEL"
        MODEL_ARG="-m \$MEDAKA_MODEL"
    else
        MODEL_ARG="-m ${model}"
    fi

    medaka_consensus \\
        -t $task.cpus \\
        \$MODEL_ARG \\
        $args \\
        -i $reads \\
        -d $input_file \\
        -o ./

    mv consensus.fasta ${prefix}.medaka.fa
    gzip -n -f ${prefix}.medaka.fa

    ${cleanup_cmd}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
