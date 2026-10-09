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
    val genome_size                  // "auto" or size value (e.g., "4m", "4.5M", "5000k", "5000000")
    val subsample_count             // default: 4
    val min_read_depth              // default: 25
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

    # Step 1: Determine genome size
    if [ "${genome_size}" = "auto" ]; then
        genome_size=\$(autocycler helper genome_size --reads \$reads_file --threads \$threads)
        echo "Estimated genome size: \$genome_size" | tee ${prefix}.autocycler.log
    else
        # Convert suffixed values (e.g. 4m, 5.5M, 100k, 1g) to integer
        genome_size_raw="${genome_size}"
        genome_size=\$(echo "\$genome_size_raw" | awk '{
            s = tolower(\$0);
            if (match(s, /^[0-9.]+[kmg]\$/)) {
                num = substr(s, 1, length(s)-1) + 0;
                suffix = substr(s, length(s));
                if (suffix == "k") num *= 1000;
                else if (suffix == "m") num *= 1000000;
                else if (suffix == "g") num *= 1000000000;
                printf "%d", num;
            } else {
                printf "%d", s + 0;
            }
        }')
        echo "User-provided genome size: \$genome_size (from \$genome_size_raw)" | tee ${prefix}.autocycler.log
    fi

    # Step 2: Calculate read depth and determine subsampling strategy
    total_bases=\$(awk 'NR%4==2 {sum += length(\$0)} END {print sum}' \$reads_file)
    read_depth=\$(( total_bases / genome_size ))
    echo "Total read bases: \$total_bases" >> ${prefix}.autocycler.log
    echo "Estimated read depth: \${read_depth}x" >> ${prefix}.autocycler.log

    requested_count=${subsample_count}
    min_depth=${min_read_depth}

    if [ \$read_depth -lt \$min_depth ]; then
        actual_count=1
        echo "WARNING: Read depth (\${read_depth}x) is below minimum read depth (\${min_depth}x) for subsampling." >> ${prefix}.autocycler.log
        echo "Skipping subsampling — using all reads with each assembler (count=1)." >> ${prefix}.autocycler.log
        mkdir -p subsampled_reads
        cp \$reads_file subsampled_reads/sample_01.fastq
    else
        actual_count=\$requested_count
        echo "Read depth (\${read_depth}x) meets minimum (\${min_depth}x). Subsampling into \$actual_count subsets." >> ${prefix}.autocycler.log
        autocycler subsample \\
            --reads \$reads_file \\
            --out_dir subsampled_reads \\
            --genome_size \$genome_size \\
            --count \$actual_count \\
            --min_read_depth \$min_depth \\
            --seed 42 \\
            2>> ${prefix}.autocycler.log
    fi

    subsample_indices=\$(seq -f '%02g' 1 \$actual_count)

    # Step 3: Build assembly jobs and run in parallel
    mkdir -p assemblies

    min_threads_per_job=4
    assembler_count=\$(echo "${assembler_list}" | wc -w)
    total_jobs=\$(( assembler_count * actual_count ))
    echo "Assembly jobs: \$total_jobs (\$assembler_count assemblers x \$actual_count subsets)" >> ${prefix}.autocycler.log

    if [ \$threads -lt \$min_threads_per_job ]; then
        parallel_jobs=1
        threads_per_job=\$threads
    else
        max_by_threads=\$(( \$threads / \$min_threads_per_job ))
        parallel_jobs=\$(( max_by_threads < total_jobs ? max_by_threads : total_jobs ))
        parallel_jobs=\$(( parallel_jobs < 1 ? 1 : parallel_jobs ))
        threads_per_job=\$(( \$threads / \$parallel_jobs ))
    fi

    for assembler in ${assembler_list}; do
        for i in \$subsample_indices; do
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
