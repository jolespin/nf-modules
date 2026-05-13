#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process FASTQ_PREPROCESSOR_SHORT {
    tag "$meta.id"
    label 'process_medium'

    conda "jolespin::fastq_preprocessor=2026.4.21"
    container "docker.io/jolespin/fastq_preprocessor:2026.4.21"

    input:
    tuple val(meta), path(reads)
    path  contamination_reference       // optional: set to [] to skip decontamination
    path  kmer_database                 // optional: set to [] to skip BBDuk
    path  adapters                      // optional: set to [] for auto-detect

    output:
    tuple val(meta), path("${prefix}/output/*.fastq.gz")              , emit: reads
    tuple val(meta), path("${prefix}/output/fastp.html")              , emit: fastp_html
    tuple val(meta), path("${prefix}/output/fastp.json")              , emit: fastp_json
    tuple val(meta), path("${prefix}/output/seqkit_stats.concatenated.tsv"), emit: seqkit_stats
    tuple val(meta), path("${prefix}/intermediate/1__fastp/trimmed_*.fastq.gz")       , optional: true, emit: trimmed_reads
    tuple val(meta), path("${prefix}/intermediate/2__strobealign/contaminated_*.fastq.gz"), optional: true, emit: contaminated_reads
    tuple val(meta), path("${prefix}/intermediate/2__strobealign/cleaned_*.fastq.gz")     , optional: true, emit: decontaminated_reads
    tuple val(meta), path("${prefix}/intermediate/*__bbduk/kmer_hits_*.fastq.gz")         , optional: true, emit: kmer_hits
    tuple val(meta), path("${prefix}/intermediate/*__bbduk/non-kmer_hits_*.fastq.gz")     , optional: true, emit: non_kmer_hits
    path "versions.yml"                                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    prefix     = task.ext.prefix ?: "${meta.id}"
    def r1     = reads[0]
    def r2     = reads[1]

    // Optional flags
    def contam_arg = contamination_reference ? "-x ${contamination_reference}" : ""
    def index_arg  = contamination_reference && meta.use_index ? "-i" : ""
    def kmer_arg   = kmer_database           ? "-k ${kmer_database}" : ""
    def adapt_arg  = adapters                ? "-a ${adapters}" : ""

    // Retention flags — default to retaining everything so Nextflow can
    // selectively publish via the optional output channels above.
    def retain_trimmed       = meta.retain_trimmed_reads       != null ? meta.retain_trimmed_reads       : (contamination_reference ? 1 : 0)
    def retain_contaminated  = meta.retain_contaminated_reads  != null ? meta.retain_contaminated_reads  : 0
    def retain_kmer_hits     = meta.retain_kmer_hits           != null ? meta.retain_kmer_hits           : 0
    def retain_non_kmer_hits = meta.retain_non_kmer_hits       != null ? meta.retain_non_kmer_hits       : 0

    """
    fastq_preprocessor short \\
        -1 ${r1} \\
        -2 ${r2} \\
        -n ${prefix} \\
        -o preprocessed \\
        -p ${task.cpus} \\
        ${contam_arg} \\
        ${index_arg} \\
        ${kmer_arg} \\
        ${adapt_arg} \\
        --retain_trimmed_reads ${retain_trimmed} \\
        --retain_contaminated_reads ${retain_contaminated} \\
        --retain_kmer_hits ${retain_kmer_hits} \\
        --retain_non_kmer_hits ${retain_non_kmer_hits} \\
        ${args}

    # The pipeline writes to preprocessed/<name>/{output,intermediate,...}
    # Move the sample directory up so Nextflow output globs resolve cleanly.
    mv preprocessed/${prefix} ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_preprocessor: \$(fastq_preprocessor --version | head -n1 | sed 's/fastq_preprocessor //')
        fastp: \$(fastp --version 2>&1 | sed 's/fastp //')
        strobealign: \$(strobealign --version 2>&1 | head -n1 | sed 's/strobealign //')
        bbduk: \$(bbduk.sh --version 2>&1 | head -n2 | tail -n1 | sed 's/BBMap version //')
        seqkit: \$(seqkit version | sed 's/seqkit v//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    def has_contam = contamination_reference ? true : false
    def has_kmer   = kmer_database           ? true : false
    // Determine which step produces final reads
    def final_step = has_kmer ? "bbduk" : (has_contam ? "strobealign" : "fastp")

    """
    # Build directory tree
    mkdir -p ${prefix}/output
    mkdir -p ${prefix}/intermediate/1__fastp

    # fastp outputs
    touch ${prefix}/intermediate/1__fastp/trimmed_1.fastq.gz
    touch ${prefix}/intermediate/1__fastp/trimmed_2.fastq.gz
    touch ${prefix}/output/fastp.html
    touch ${prefix}/output/fastp.json

    # strobealign outputs
    if [ "${has_contam}" = "true" ]; then
        mkdir -p ${prefix}/intermediate/2__strobealign
        touch ${prefix}/intermediate/2__strobealign/cleaned_1.fastq.gz
        touch ${prefix}/intermediate/2__strobealign/cleaned_2.fastq.gz
        touch ${prefix}/intermediate/2__strobealign/contaminated_1.fastq.gz
        touch ${prefix}/intermediate/2__strobealign/contaminated_2.fastq.gz
    fi

    # bbduk outputs
    if [ "${has_kmer}" = "true" ]; then
        step=\$( [ "${has_contam}" = "true" ] && echo 3 || echo 2 )
        mkdir -p ${prefix}/intermediate/\${step}__bbduk
        touch ${prefix}/intermediate/\${step}__bbduk/non-kmer_hits_1.fastq.gz
        touch ${prefix}/intermediate/\${step}__bbduk/non-kmer_hits_2.fastq.gz
        touch ${prefix}/intermediate/\${step}__bbduk/kmer_hits_1.fastq.gz
        touch ${prefix}/intermediate/\${step}__bbduk/kmer_hits_2.fastq.gz
    fi

    # Symlink final reads into output (mirrors synopsis step)
    if [ "${final_step}" = "fastp" ]; then
        ln -sf ../intermediate/1__fastp/trimmed_1.fastq.gz ${prefix}/output/trimmed_1.fastq.gz
        ln -sf ../intermediate/1__fastp/trimmed_2.fastq.gz ${prefix}/output/trimmed_2.fastq.gz
    elif [ "${final_step}" = "strobealign" ]; then
        ln -sf ../intermediate/2__strobealign/cleaned_1.fastq.gz ${prefix}/output/cleaned_1.fastq.gz
        ln -sf ../intermediate/2__strobealign/cleaned_2.fastq.gz ${prefix}/output/cleaned_2.fastq.gz
    elif [ "${final_step}" = "bbduk" ]; then
        step=\$( [ "${has_contam}" = "true" ] && echo 3 || echo 2 )
        ln -sf ../intermediate/\${step}__bbduk/non-kmer_hits_1.fastq.gz ${prefix}/output/non-kmer_hits_1.fastq.gz
        ln -sf ../intermediate/\${step}__bbduk/non-kmer_hits_2.fastq.gz ${prefix}/output/non-kmer_hits_2.fastq.gz
    fi

    # Stats placeholder
    echo -e "file\\tformat\\tnum_seqs" > ${prefix}/output/seqkit_stats.concatenated.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_preprocessor: 2026.4.17
        fastp: 0.23.4
        strobealign: 0.17.0
        bbduk: 39.10
        seqkit: 2.8.0
    END_VERSIONS
    """
}
