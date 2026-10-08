#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

process AUTOCYCLER {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::autocycler=0.8.0 bioconda::flye=2.9.6 bioconda::raven-assembler=1.8.3 bioconda::miniasm=0.3 bioconda::minipolish=0.2.1 bioconda::racon=1.5.0 bioconda::myloasm=0.7.0 bioconda::metamdbg=1.4 bioconda::plassembler=1.8.5 bioconda::minimap2=2.31 bioconda::samtools=1.24 conda-forge::parallel=20170422"
    container "docker.io/jolespin/autocycler:0.8.0"

    input:
    tuple val(meta), path(reads)
    val read_type                   // ont_r10, ont_r9, pacbio_hifi, pacbio_clr
    val assemblers                  // default: "flye,raven,miniasm,myloasm,plassembler,metamdbg"
    val subsample_count             // default: 2
    val min_depth_rel               // default: 0.1
    val min_contig_length           // default: 1000

    output:
    tuple val(meta), path("*.assembly.fa.gz")         , emit: fasta
    tuple val(meta), path("*.assembly.gfa.gz")        , emit: gfa
    tuple val(meta), path("*.assembly.yaml")          , emit: stats
    tuple val(meta), path("*.discarded-contigs.fa.gz"), emit: discarded_contigs
    tuple val(meta), path("*.autocycler.log")         , emit: log
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def assembler_tokens = assemblers.toString().split(',').collect { it.trim() }

    def assembler_list = assembler_tokens.join(' ')
    def subsample_indices = (1..subsample_count.toInteger()).collect { String.format('%02d', it) }.join(' ')

    """
    #!/usr/bin/env bash
    set -euo pipefail

    # Handle gzipped input reads
    if [[ "${reads}" == *.gz ]]; then
        gunzip -c ${reads} > reads.fastq
        reads_file=reads.fastq
    else
        reads_file=${reads}
    fi

    # Cap threads at 100 (AutoCycler limitation)
    threads=\$(( ${task.cpus} > 100 ? 100 : ${task.cpus} ))

    # Step 1: Estimate genome size via quick Raven assembly
    genome_size=\$(autocycler helper genome_size --reads \$reads_file --threads \$threads)
    echo "Estimated genome size: \$genome_size" | tee ${prefix}.autocycler.log

    # Step 2: Subsample reads
    autocycler subsample \\
        --reads \$reads_file \\
        --out_dir subsampled_reads \\
        --genome_size \$genome_size \\
        --count ${subsample_count} \\
        --seed 42 \\
        2>> ${prefix}.autocycler.log

    # Step 3: Build assembly jobs and run in parallel
    mkdir -p assemblies

    # Calculate parallelism: ensure each job gets at least 4 threads
    min_threads_per_job=4
    assembler_count=\$(echo "${assembler_list}" | wc -w)
    total_jobs=\$(( assembler_count * ${subsample_count} ))

    if [ \$threads -lt \$min_threads_per_job ]; then
        # Fewer CPUs than the minimum per job — run 1 job at a time with all CPUs
        parallel_jobs=1
        threads_per_job=\$threads
    else
        # Max concurrent jobs such that each gets at least min_threads_per_job
        max_by_threads=\$(( \$threads / \$min_threads_per_job ))
        parallel_jobs=\$(( max_by_threads < total_jobs ? max_by_threads : total_jobs ))
        parallel_jobs=\$(( parallel_jobs < 1 ? 1 : parallel_jobs ))
        threads_per_job=\$(( \$threads / \$parallel_jobs ))
    fi

    for assembler in ${assembler_list}; do
        for i in ${subsample_indices}; do
            echo "autocycler helper \$assembler --reads subsampled_reads/sample_\$i.fastq --out_prefix assemblies/\${assembler}_\$i --threads \$threads_per_job --genome_size \$genome_size --read_type ${read_type} --min_depth_rel ${min_depth_rel}"
        done
    done > assemblies/jobs.txt

    set +e
    nice -n 19 parallel \\
        --jobs \$parallel_jobs \\
        --joblog assemblies/joblog.tsv \\
        --results assemblies/logs \\
        < assemblies/jobs.txt
    set -e

    echo "Assembly jobs completed" >> ${prefix}.autocycler.log

    # Step 4: Weight adjustments
    shopt -s nullglob
    for f in assemblies/plassembler*.fasta; do
        sed -i 's/circular=True/circular=True Autocycler_cluster_weight=3/' "\$f"
    done
    for f in assemblies/flye*.fasta; do
        sed -i 's/^>.*\$/& Autocycler_consensus_weight=2/' "\$f"
    done
    shopt -u nullglob

    # Clean up subsampled reads to save space
    rm -f subsampled_reads/*.fastq

    # Step 5: Compress
    autocycler compress -i assemblies -a autocycler_out -t \$threads 2>> ${prefix}.autocycler.log

    # Step 6: Cluster
    autocycler cluster -a autocycler_out 2>> ${prefix}.autocycler.log

    # Steps 7-8: Trim and resolve per QC-pass cluster
    for c in autocycler_out/clustering/qc_pass/cluster_*; do
        autocycler trim -c "\$c" -t \$threads 2>> ${prefix}.autocycler.log
        autocycler resolve -c "\$c" 2>> ${prefix}.autocycler.log
    done

    # Step 9: Combine resolved clusters into final assembly
    autocycler combine \\
        -a autocycler_out \\
        -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa \\
        -r \$reads_file \\
        -t \$threads \\
        2>> ${prefix}.autocycler.log

    # Verify output exists
    if [ ! -s autocycler_out/consensus_assembly.fasta ]; then
        echo "ERROR: AutoCycler did not produce a consensus assembly" >> ${prefix}.autocycler.log
        exit 1
    fi

    # Step 10: Filter short contigs and gzip outputs
    awk -v min_len=${min_contig_length} -v pass=/dev/stdout -v fail=${prefix}.discarded-contigs.fa '
        /^>/ {
            if (header) {
                if (len >= min_len) { printf "%s\\n%s\\n", header, seq > pass }
                else { printf "%s\\n%s\\n", header, seq > fail }
            }
            header = \$0; seq = ""; len = 0; next
        }
        { seq = (seq == "" ? \$0 : seq "\\n" \$0); len += length(\$0) }
        END {
            if (header) {
                if (len >= min_len) { printf "%s\\n%s\\n", header, seq > pass }
                else { printf "%s\\n%s\\n", header, seq > fail }
            }
        }
    ' autocycler_out/consensus_assembly.fasta | gzip > ${prefix}.assembly.fa.gz
    touch ${prefix}.discarded-contigs.fa
    gzip -f ${prefix}.discarded-contigs.fa
    gzip -c autocycler_out/consensus_assembly.gfa > ${prefix}.assembly.gfa.gz
    cp autocycler_out/consensus_assembly.yaml ${prefix}.assembly.yaml

    # Clean up decompressed reads
    if [[ "${reads}" == *.gz ]]; then
        rm -f reads.fastq
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        autocycler: \$(autocycler --version 2>&1 | sed 's/^[^ ]* //')
    END_VERSIONS
    """
}
