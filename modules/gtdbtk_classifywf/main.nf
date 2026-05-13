#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2026.5.13"

process GTDBTK_CLASSIFYWF {
    tag "${meta.id}"
    label 'process_high_memory'
    conda "bioconda:gtdbtk=2.7.2"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/fa/fa734cc7e63b0f7d0c04788ec61de5e6a101a07e966d3dde24384d54a9d75e85/data' :
        'community.wave.seqera.io/library/gtdbtk:2.7.2--64b0fd171db01270' }"

    input:
    tuple val(meta)   , path("bins/*")
    tuple val(db_name), path(db)
    val use_pplacer_scratch_dir
    val extension

    output:
    tuple val(meta), path("${prefix}")                               , emit: gtdb_outdir
    tuple val(meta), path("${prefix}/*.taxonomy.tsv")                , emit: summary
    tuple val(meta), path("${prefix}/classify/*.classify.tree")      , emit: tree       , optional: true
    tuple val(meta), path("${prefix}/identify/*.markers_summary.tsv"), emit: markers    , optional: true
    tuple val(meta), path("${prefix}/align/*.msa.fasta.gz")          , emit: msa        , optional: true
    tuple val(meta), path("${prefix}/align/*.user_msa.fasta.gz")     , emit: user_msa   , optional: true
    tuple val(meta), path("${prefix}/align/*.filtered.tsv")          , emit: filtered   , optional: true
    tuple val(meta), path("${prefix}/identify/*.failed_genomes.tsv") , emit: failed     , optional: true
    tuple val(meta), path("${prefix}/${prefix}.log")                 , emit: log
    tuple val(meta), path("${prefix}/${prefix}.warnings.log")        , emit: warnings
    path ("versions.yml")                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args            = task.ext.args ?: ''
    prefix              = task.ext.prefix ?: "${meta.id}"
    def pplacer_scratch = use_pplacer_scratch_dir ? "--scratch_dir pplacer_tmp" : ""

    """
    export GTDBTK_DATA_PATH="\$(find -L ${db} -maxdepth 3 -name 'metadata' -type d -exec dirname {} \\;)"

    if [ "${pplacer_scratch}" != "" ] ; then
        mkdir pplacer_tmp
    fi

    gtdbtk classify_wf \\
        ${args} \\
        --genome_dir bins \\
        --prefix "${prefix}" \\
        --out_dir ${prefix} \\
        --cpus ${task.cpus} \\
        --extension ${extension} \\
        ${pplacer_scratch}

    mv ${prefix}/gtdbtk.log "${prefix}/${prefix}.log"
    mv ${prefix}/gtdbtk.warnings.log "${prefix}/${prefix}.warnings.log"

    # Merge taxonomy results
    if [ -f "${prefix}/classify/${prefix}.bac120.summary.tsv" ] && [ -f "${prefix}/classify/${prefix}.ar53.summary.tsv" ]; then
        # Both files exist - merge them
        cat "${prefix}/classify/${prefix}.bac120.summary.tsv" > "${prefix}/${prefix}.taxonomy.tsv"
        tail -n +2 "${prefix}/classify/${prefix}.ar53.summary.tsv" >> "${prefix}/${prefix}.taxonomy.tsv"
    elif [ -f "${prefix}/classify/${prefix}.bac120.summary.tsv" ]; then
        # Only bac120 exists
        cp "${prefix}/classify/${prefix}.bac120.summary.tsv" "${prefix}/${prefix}.taxonomy.tsv"
    elif [ -f "${prefix}/classify/${prefix}.ar53.summary.tsv" ]; then
        # Only ar53 exists
        cp "${prefix}/classify/${prefix}.ar53.summary.tsv" "${prefix}/${prefix}.taxonomy.tsv"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version 2>/dev/null) | sed "s/gtdbtk: version //; s/ Copyright.*//")
        gtdb_db: \$(grep VERSION_DATA \$GTDBTK_DATA_PATH/metadata/metadata.txt | sed "s/VERSION_DATA=//")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    mkdir ${prefix}/identify
    mkdir ${prefix}/classify
    mkdir ${prefix}/align

    touch ${prefix}/classify/${prefix}.ar53.summary.tsv
    touch ${prefix}/classify/${prefix}.bac120.summary.tsv
    touch ${prefix}/classify/${prefix}.ar53.classify.tree
    touch ${prefix}/classify/${prefix}.bac120.classify.tree

    touch ${prefix}/identify/${prefix}.ar53.markers_summary.tsv
    touch ${prefix}/identify/${prefix}.bac120.markers_summary.tsv

    echo "" | gzip > ${prefix}/align/${prefix}.ar53.msa.fasta.gz
    echo "" | gzip > ${prefix}/align/${prefix}.bac120.user_msa.fasta.gz
    touch ${prefix}/align/${prefix}.ar53.filtered.tsv
    touch ${prefix}/align/${prefix}.bac120.filtered.tsv

    touch ${prefix}/${prefix}.log
    touch ${prefix}/${prefix}.warnings.log
    touch ${prefix}/${prefix}.failed_genomes.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version 2>/dev/null) | sed "s/gtdbtk: version //; s/ Copyright.*//")
    END_VERSIONS
    """
}

process GTDBTK_CLASSIFYWF_WITH_STAGING {
    tag "${meta.id}"
    label 'process_high_memory'
    conda "bioconda:gtdbtk=2.7.2"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/fa/fa734cc7e63b0f7d0c04788ec61de5e6a101a07e966d3dde24384d54a9d75e85/data' :
        'community.wave.seqera.io/library/gtdbtk:2.7.2--64b0fd171db01270' }"

    input:
    tuple val(meta)   , path("bins/*")
    tuple val(db_name), path(db)
    val use_pplacer_scratch_dir
    val extension

    output:
    tuple val(meta), path("${prefix}")                               , emit: gtdb_outdir
    tuple val(meta), path("${prefix}/*.taxonomy.tsv")                , emit: summary
    tuple val(meta), path("${prefix}/classify/*.classify.tree")      , emit: tree       , optional: true
    tuple val(meta), path("${prefix}/identify/*.markers_summary.tsv"), emit: markers    , optional: true
    tuple val(meta), path("${prefix}/align/*.msa.fasta.gz")          , emit: msa        , optional: true
    tuple val(meta), path("${prefix}/align/*.user_msa.fasta.gz")     , emit: user_msa   , optional: true
    tuple val(meta), path("${prefix}/align/*.filtered.tsv")          , emit: filtered   , optional: true
    tuple val(meta), path("${prefix}/identify/*.failed_genomes.tsv") , emit: failed     , optional: true
    tuple val(meta), path("${prefix}/${prefix}.log")                 , emit: log
    tuple val(meta), path("${prefix}/${prefix}.warnings.log")        , emit: warnings
    path ("versions.yml")                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args            = task.ext.args ?: ''
    prefix              = task.ext.prefix ?: "${meta.id}"
    def pplacer_scratch = use_pplacer_scratch_dir ? "--scratch_dir pplacer_tmp" : ""

    """
    export GTDBTK_DATA_PATH="\$(find -L ${db} -maxdepth 3 -name 'metadata' -type d -exec dirname {} \\;)"

    if [ "${pplacer_scratch}" != "" ] ; then
        mkdir pplacer_tmp
    fi

    # Stage genomes
    mkdir staged_bins
    for f in bins/*.${extension}; do
        genome_id=\$(basename "\$f" ".${extension}")
        ln -s "\$(readlink -f "\$f")" "staged_bins/\${genome_id}__GTDB-Tk_staging.${extension}"
    done

    gtdbtk classify_wf \\
        ${args} \\
        --genome_dir staged_bins \\
        --prefix "${prefix}" \\
        --out_dir ${prefix} \\
        --cpus ${task.cpus} \\
        --extension ${extension} \\
        ${pplacer_scratch}

    mv ${prefix}/gtdbtk.log "${prefix}/${prefix}.log"
    mv ${prefix}/gtdbtk.warnings.log "${prefix}/${prefix}.warnings.log"

    # Merge taxonomy results
    if [ -f "${prefix}/classify/${prefix}.bac120.summary.tsv" ] && [ -f "${prefix}/classify/${prefix}.ar53.summary.tsv" ]; then
        cat "${prefix}/classify/${prefix}.bac120.summary.tsv" > "${prefix}/${prefix}.taxonomy.tsv"
        tail -n +2 "${prefix}/classify/${prefix}.ar53.summary.tsv" >> "${prefix}/${prefix}.taxonomy.tsv"
    elif [ -f "${prefix}/classify/${prefix}.bac120.summary.tsv" ]; then
        cp "${prefix}/classify/${prefix}.bac120.summary.tsv" "${prefix}/${prefix}.taxonomy.tsv"
    elif [ -f "${prefix}/classify/${prefix}.ar53.summary.tsv" ]; then
        cp "${prefix}/classify/${prefix}.ar53.summary.tsv" "${prefix}/${prefix}.taxonomy.tsv"
    fi

    # Remove staging suffix from output file contents
    shopt -s nullglob

    for f in ${prefix}/*.taxonomy.tsv \\
             ${prefix}/classify/*.classify.tree \\
             ${prefix}/identify/*.markers_summary.tsv \\
             ${prefix}/align/*.filtered.tsv \\
             ${prefix}/identify/*.failed_genomes.tsv; do
        sed -i 's/__GTDB-Tk_staging//g' "\$f"
    done

    for f in ${prefix}/align/*.msa.fasta.gz \\
             ${prefix}/align/*.user_msa.fasta.gz; do
        gunzip "\$f"
        sed -i 's/__GTDB-Tk_staging//g' "\${f%.gz}"
        gzip "\${f%.gz}"
    done

    shopt -u nullglob

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version 2>/dev/null) | sed "s/gtdbtk: version //; s/ Copyright.*//")
        gtdb_db: \$(grep VERSION_DATA \$GTDBTK_DATA_PATH/metadata/metadata.txt | sed "s/VERSION_DATA=//")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    mkdir ${prefix}/identify
    mkdir ${prefix}/classify
    mkdir ${prefix}/align

    touch ${prefix}/classify/${prefix}.ar53.summary.tsv
    touch ${prefix}/classify/${prefix}.bac120.summary.tsv
    touch ${prefix}/classify/${prefix}.ar53.classify.tree
    touch ${prefix}/classify/${prefix}.bac120.classify.tree

    touch ${prefix}/identify/${prefix}.ar53.markers_summary.tsv
    touch ${prefix}/identify/${prefix}.bac120.markers_summary.tsv

    echo "" | gzip > ${prefix}/align/${prefix}.ar53.msa.fasta.gz
    echo "" | gzip > ${prefix}/align/${prefix}.bac120.user_msa.fasta.gz
    touch ${prefix}/align/${prefix}.ar53.filtered.tsv
    touch ${prefix}/align/${prefix}.bac120.filtered.tsv

    touch ${prefix}/${prefix}.log
    touch ${prefix}/${prefix}.warnings.log
    touch ${prefix}/${prefix}.failed_genomes.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version 2>/dev/null) | sed "s/gtdbtk: version //; s/ Copyright.*//")
    END_VERSIONS
    """
}
