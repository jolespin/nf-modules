#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.12.5"

process PROFILE_PATHWAY_COVERAGE_FROM_PYKOFAMSEARCH {
    tag "$meta.id"
    label 'process_low'

    container "docker.io/jolespin/kegg_pathway_profiler:2025.12.4"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/pyhmmsearch:2025.9.4.post1--pyh7e72e81_0' :
    //     'biocontainers/pyhmmsearch:2025.9.4.post1--pyh7e72e81_0' }"

    input:
    tuple(val(meta), path(identifier_mapping))
    tuple(val(meta), path(pykofamsearch_results))
    tuple(val(dbmeta), path(db))
    val(identifier_mapping_format)

    output:
    tuple val(meta), path("pathway_coverage.tsv.gz"), emit: coverage_report
    tuple val(meta), path("pathway_output.pkl.gz")  , emit: serialized_results
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # Build KO table
    get-kos-from-pykofamsearch.py \\
        -i ${pykofamsearch_results} \\
        -o kos.tsv.gz \\
        -m ${identifier_mapping} \\
        -f ${identifier_mapping_format}

    # Run profile-pathway-coverage
    profile-pathway-coverage.py \\
        $args \\
        --n_jobs $task.cpus \\
        -d $db \\
        -i kos.tsv.gz \\
        -o .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kegg_pathway_profiler: \$(python -c 'import kegg_pathway_profiler as kpp; print(kpp.__version__)')
        module: ${module_version}
    END_VERSIONS
    """

    stub:
    // def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "pathway_coverage.tsv.gz"
    touch "pathway_output.pkl.gz"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kegg_pathway_profiler: \$(python -c 'import kegg_pathway_profiler as kpp; print(kpp.__version__)')
        module: ${module_version}
    END_VERSIONS
    """
}