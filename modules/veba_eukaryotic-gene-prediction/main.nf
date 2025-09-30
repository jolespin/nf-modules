#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

def module_version = "2025.9.30"


// # eukaryotic_gene_modeling_wrapper.py output structure:
// output_directory/
// ├── {bin_id_1}.fa                      # Nuclear sequences for bin 1
// ├── {bin_id_1}.faa                     # Nuclear proteins for bin 1
// ├── {bin_id_1}.ffn                     # Nuclear CDS for bin 1
// ├── {bin_id_1}.gff                     # Combined annotations for bin 1
// ├── {bin_id_1}.rRNA                    # Nuclear rRNA for bin 1
// ├── {bin_id_1}.tRNA                    # Nuclear tRNA for bin 1
// │
// ├── {bin_id_2}.fa                      # Nuclear sequences for bin 2
// ├── {bin_id_2}.faa                     # ... (same pattern)
// ├── ... (one set per bin ID)
// │
// ├── identifier_mapping.metaeuk.tsv     # MetaEuk identifier mapping (all bins)
// ├── identifier_mapping.tsv             # General identifier mapping (all bins)
// ├── genome_statistics.tsv              # Stats for all genomes
// ├── gene_statistics.cds.tsv            # CDS stats for all
// ├── gene_statistics.rRNA.tsv           # rRNA stats for all
// ├── gene_statistics.tRNA.tsv           # tRNA stats for all
// │
// ├── mitochondrion/
// │   ├── {bin_id_1}.fa                  # Each bin's mitochondrial sequences
// │   ├── {bin_id_1}.faa
// │   ├── {bin_id_1}.ffn
// │   ├── {bin_id_1}.gff
// │   ├── {bin_id_1}.rRNA
// │   ├── {bin_id_1}.tRNA
// │   ├── {bin_id_2}.fa                  # ... (one set per bin)
// │   └── ...
// │
// └── plastid/
//     ├── {bin_id_1}.fa                  # Each bin's plastid sequences
//     ├── {bin_id_1}.faa
//     ├── {bin_id_1}.ffn
//     ├── {bin_id_1}.gff
//     ├── {bin_id_1}.rRNA
//     ├── {bin_id_1}.tRNA
//     ├── {bin_id_2}.fa                  # ... (one set per bin)
//     └── ...


process VEBA_EUKARYOTIC_GENE_PREDICTION {
    tag "$meta.id"
    label 'process_medium'

    container "docker.io/jolespin/veba_eukaryotic-gene-prediction:2.5.1"

    input:
    tuple val(meta), path(fasta)
    tuple val(dbmeta), path(db)
    path(tiara_probabilities)  // Optional: pass empty list if not used.
    val(minimum_contig_length) // Recommended: 3000

    output:
    // Identifier mappings
    tuple val(meta), path("*.identifier_mapping.metaeuk.tsv.gz")  , emit: metaeuk_identifier_mapping
    tuple val(meta), path("*.identifier_mapping.nuclear.tsv.gz")  , emit: nuclear_identifier_mapping
    // tuple val(meta), path("*.identifier_mapping.mitochondrion.tsv.gz")  , emit: mitochondrion_identifier_mapping
    // tuple val(meta), path("*.identifier_mapping.plastid.tsv.gz")  , emit: plastid_identifier_mapping

    // Statistics
    tuple val(meta), path("*.genome_statistics.tsv.gz")  , emit: stats_genome
    tuple val(meta), path("*.gene_statistics.cds.tsv.gz")  , emit: stats_cds
    tuple val(meta), path("*.gene_statistics.rRNA.tsv.gz")  , emit: stats_rRNA
    tuple val(meta), path("*.gene_statistics.tRNA.tsv.gz")  , emit: stats_tRNA

    // Gene Predictions
    tuple val(meta), path("*.fa.gz")  , emit: fa
    tuple val(meta), path("*.faa.gz")  , emit: faa
    tuple val(meta), path("*.ffn.gz")  , emit: ffn
    tuple val(meta), path("*.gff.gz")  , emit: gff
    tuple val(meta), path("*.rRNA.gz")  , emit: rRNA
    tuple val(meta), path("*.tRNA.gz")  , emit: tRNA

    // // Mitochondrion
    // tuple val(meta), path("*.mitochondrion.fa.gz")  , emit: mitochondrion_fa
    // tuple val(meta), path("*.mitochondrion.faa.gz")  , emit: mitochondrion_faa
    // tuple val(meta), path("*.mitochondrion.ffn.gz")  , emit: mitochondrion_ffn
    // tuple val(meta), path("*.mitochondrion.gff.gz")  , emit: mitochondrion_gff
    // tuple val(meta), path("*.mitochondrion.rRNA.gz")  , emit: mitochondrion_rRNA
    // tuple val(meta), path("*.mitochondrion.tRNA.gz")  , emit: mitochondrion_tRNA

    // // Plastid
    // tuple val(meta), path("*.plastid.fa.gz")  , emit: plastid_fa
    // tuple val(meta), path("*.plastid.faa.gz")  , emit: plastid_faa
    // tuple val(meta), path("*.plastid.ffn.gz")  , emit: plastid_ffn
    // tuple val(meta), path("*.plastid.gff.gz")  , emit: plastid_gff
    // tuple val(meta), path("*.plastid.rRNA.gz")  , emit: plastid_rRNA
    // tuple val(meta), path("*.plastid.tRNA.gz")  , emit: plastid_tRNA

    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def db_name = db[0].baseName.replaceAll(/\..*/, '')
    def tiara_probabilities_arg = tiara_probabilities ? "-t ${tiara_probabilities}" : ''

    def input = fasta
    def decompress_fasta = ""
    def cleanup = ""

    if (fasta.toString().endsWith('.gz')) {
        input = "temporary.fasta"
        decompress_fasta = "gunzip -c ${fasta} > ${input}"
        cleanup = "rm -f ${input}"
    }
    
    """
    # Prepare fasta file if gzipped
    ${decompress_fasta}

    # Run VEBA Eukaryotic Gene Modeling Wrapper
    eukaryotic_gene_modeling_wrapper.py \\
        -p ${task.cpus} \\
        -n ${prefix} \\
        -f ${input} \\
        -d ${db_name} \\
        -o results \\
        --tiara_minimum_length ${minimum_contig_length} \\
        ${tiara_probabilities_arg} \\
        ${args}

    # Move outputs to expected names
    for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
    do
        cat results/output/${prefix}.\${ext} results/output/mitochondrion/${prefix}.\${ext} results/output/plastid/${prefix}.\${ext}| gzip -f -v -c -n  > ${prefix}.\${ext}.gz
    done
    # gzip -f -v -c -n results/output/identifier_mapping.tsv > ${prefix}.identifier_mapping.nuclear.tsv.gz

    gzip -f -v -c -n results/output/identifier_mapping.metaeuk.tsv > ${prefix}.identifier_mapping.metaeuk.tsv.gz
    awk -F"\t" 'NR>1 {print "${prefix}", \$3, \$5}' OFS="\t" results/output/identifier_mapping.metaeuk.tsv | gzip -f -v -n > ${prefix}.identifier_mapping.nuclear.tsv.gz

    # Statistics
    gzip -f -v -c -n results/output/genome_statistics.tsv > ${prefix}.genome_statistics.tsv.gz
    gzip -f -v -c -n results/output/gene_statistics.cds.tsv > ${prefix}.gene_statistics.cds.tsv.gz
    gzip -f -v -c -n results/output/gene_statistics.rRNA.tsv > ${prefix}.gene_statistics.rRNA.tsv.gz
    gzip -f -v -c -n results/output/gene_statistics.tRNA.tsv > ${prefix}.gene_statistics.tRNA.tsv.gz

    # Cleanup
    ${cleanup}
    rm -rv results/tmp/
    rm -rv results/output/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eukaryotic_gene_modeling_wrapper.py: \$(eukaryotic_gene_modeling_wrapper.py --version | cut -f2 -d " ")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # Create stub identifier mapping files
    touch ${prefix}.identifier_mapping.metaeuk.tsv.gz
    touch ${prefix}.identifier_mapping.nuclear.tsv.gz
    
    # Create stub statistics files
    touch ${prefix}.genome_statistics.tsv.gz
    touch ${prefix}.gene_statistics.cds.tsv.gz
    touch ${prefix}.gene_statistics.rRNA.tsv.gz
    touch ${prefix}.gene_statistics.tRNA.tsv.gz
    
    # Create stub nuclear files
    touch ${prefix}.fa.gz
    touch ${prefix}.faa.gz
    touch ${prefix}.ffn.gz
    touch ${prefix}.gff.gz
    touch ${prefix}.rRNA.gz
    touch ${prefix}.tRNA.gz
    
    # Create versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eukaryotic_gene_modeling_wrapper.py: \$(eukaryotic_gene_modeling_wrapper.py --version | cut -f2 -d " ")
    END_VERSIONS
    """
}

process VEBA_EUKARYOTIC_GENE_PREDICTION_MANY {
    tag "$meta.id"
    label 'process_medium'

    container "docker.io/jolespin/veba_eukaryotic-gene-prediction:2.5.1"

    input:
    tuple val(meta), path(fasta)
    tuple val(dbmeta), path(db)
    path(contigs_to_genomes) // TSV mapping contig IDs to genome/bin IDs (no header)
    path(tiara_probabilities)  // Optional: pass empty list if not used.
    val(minimum_contig_length) // Recommended: 3000

    output:
    // Identifier mappings
    tuple val(meta), path("*.identifier_mapping.metaeuk.tsv.gz")  , emit: metaeuk_identifier_mapping
    tuple val(meta), path("*.identifier_mapping.nuclear.tsv.gz")  , emit: nuclear_identifier_mapping

    // Statistics
    tuple val(meta), path("*.genome_statistics.tsv.gz")  , emit: stats_genome
    tuple val(meta), path("*.gene_statistics.cds.tsv.gz")  , emit: stats_cds
    tuple val(meta), path("*.gene_statistics.rRNA.tsv.gz")  , emit: stats_rRNA
    tuple val(meta), path("*.gene_statistics.tRNA.tsv.gz")  , emit: stats_tRNA

    // Gene Predictions
    tuple val(meta), path("*.fa.gz")  , emit: fa
    tuple val(meta), path("*.faa.gz")  , emit: faa
    tuple val(meta), path("*.ffn.gz")  , emit: ffn
    tuple val(meta), path("*.gff.gz")  , emit: gff
    tuple val(meta), path("*.rRNA.gz")  , emit: rRNA
    tuple val(meta), path("*.tRNA.gz")  , emit: tRNA

    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def tiara_probabilities_arg = tiara_probabilities ? "-t ${tiara_probabilities}" : ''

    def input = fasta
    def decompress_fasta = ""
    def cleanup = ""

    if (fasta.toString().endsWith('.gz')) {
        input = "temporary.fasta"
        decompress_fasta = "gunzip -c ${fasta} > ${input}"
        cleanup = "rm -f ${input}"
    }
    
    """
    # Prepare fasta file if gzipped
    ${decompress_fasta}

    # Run VEBA Eukaryotic Gene Modeling Wrapper
    eukaryotic_gene_modeling_wrapper.py \\
        -p ${task.cpus} \\
        -i ${contigs_to_genomes} \\
        -f ${input} \\
        -d ${db_name} \\
        -o results \\
        --tiara_minimum_length ${minimum_contig_length} \\
        ${tiara_probabilities_arg} \\
        ${args}

    # Move outputs to expected names
    for id_genome in \$(cut -f2 ${contigs_to_genomes} | sort -u); do
        for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; 
        do
            cat results/output/\${id_genome}.\${ext} results/output/mitochondrion/\${id_genome}.\${ext} results/output/plastid/\${id_genome}.\${ext}| gzip -f -v -c -n  > \${id_genome}.\${ext}.gz
        done
    done

    # gzip -f -v -c -n results/output/identifier_mapping.tsv > ${prefix}.identifier_mapping.nuclear.tsv.gz

    gzip -f -v -c -n results/output/identifier_mapping.metaeuk.tsv > ${prefix}.identifier_mapping.metaeuk.tsv.gz
    awk -F"\t" 'NR>1 {print "${prefix}", \$3, \$5}' OFS="\t" results/output/identifier_mapping.metaeuk.tsv | gzip -f -v -n > ${prefix}.identifier_mapping.nuclear.tsv.gz

    # Statistics
    gzip -f -v -c -n results/output/genome_statistics.tsv > ${prefix}.genome_statistics.tsv.gz
    gzip -f -v -c -n results/output/gene_statistics.cds.tsv > ${prefix}.gene_statistics.cds.tsv.gz
    gzip -f -v -c -n results/output/gene_statistics.rRNA.tsv > ${prefix}.gene_statistics.rRNA.tsv.gz
    gzip -f -v -c -n results/output/gene_statistics.tRNA.tsv > ${prefix}.gene_statistics.tRNA.tsv.gz

    # Cleanup
    ${cleanup}
    rm -rv results/tmp/
    rm -rv results/output/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eukaryotic_gene_modeling_wrapper.py: \$(eukaryotic_gene_modeling_wrapper.py --version | cut -f2 -d " ")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # Create stub identifier mapping files
    touch ${prefix}.identifier_mapping.metaeuk.tsv.gz
    touch ${prefix}.identifier_mapping.nuclear.tsv.gz
    
    # Create stub statistics files
    touch ${prefix}.genome_statistics.tsv.gz
    touch ${prefix}.gene_statistics.cds.tsv.gz
    touch ${prefix}.gene_statistics.rRNA.tsv.gz
    touch ${prefix}.gene_statistics.tRNA.tsv.gz
    
    # Create stub nuclear files
    touch ${prefix}.fa.gz
    touch ${prefix}.faa.gz
    touch ${prefix}.ffn.gz
    touch ${prefix}.gff.gz
    touch ${prefix}.rRNA.gz
    touch ${prefix}.tRNA.gz
    
    # Create versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eukaryotic_gene_modeling_wrapper.py: \$(eukaryotic_gene_modeling_wrapper.py --version | cut -f2 -d " ")
    END_VERSIONS
    """
}


// process VEBA_EUKARYOTIC_GENE_PREDICTION_MANY { // This takes in multiple genomes but is not operational
//     tag "$meta.id"
//     label 'process_medium'

//     container "docker.io/jolespin/veba_eukaryotic-gene-prediction:2.5.1"

//     input:
//     tuple val(metas), path(fastas, arity: "1..*") // List of [meta, fasta] tuples
//     tuple val(dbmeta), path(db)
//     path(tiara_probabilities, arity: "0..*")  // Optional: pass empty list if not used
//     val(minimum_contig_length) // Recommended: 3000

//     output:
//     // All outputs use the group-level meta
//     tuple val(meta), path("*.identifier_mapping.metaeuk.tsv.gz")  , emit: metaeuk_identifier_mapping
//     tuple val(meta), path("*.identifier_mapping.nuclear.tsv.gz")  , emit: nuclear_identifier_mapping
//     tuple val(meta), path("*.genome_statistics.tsv.gz")  , emit: stats_genome
//     tuple val(meta), path("*.gene_statistics.cds.tsv.gz")  , emit: stats_cds
//     tuple val(meta), path("*.gene_statistics.rRNA.tsv.gz")  , emit: stats_rRNA
//     tuple val(meta), path("*.gene_statistics.tRNA.tsv.gz")  , emit: stats_tRNA
//     tuple val(meta), path("*.nuclear.fa.gz")  , emit: nuclear_fa
//     tuple val(meta), path("*.nuclear.faa.gz")  , emit: nuclear_faa
//     tuple val(meta), path("*.nuclear.ffn.gz")  , emit: nuclear_ffn
//     tuple val(meta), path("*.nuclear.gff.gz")  , emit: nuclear_gff
//     tuple val(meta), path("*.nuclear.rRNA.gz")  , emit: nuclear_rRNA
//     tuple val(meta), path("*.nuclear.tRNA.gz")  , emit: nuclear_tRNA
//     tuple val(meta), path("*.mitochondrion.fa.gz")  , emit: mitochondrion_fa
//     tuple val(meta), path("*.mitochondrion.faa.gz")  , emit: mitochondrion_faa
//     tuple val(meta), path("*.mitochondrion.ffn.gz")  , emit: mitochondrion_ffn
//     tuple val(meta), path("*.mitochondrion.gff.gz")  , emit: mitochondrion_gff
//     tuple val(meta), path("*.mitochondrion.rRNA.gz")  , emit: mitochondrion_rRNA
//     tuple val(meta), path("*.mitochondrion.tRNA.gz")  , emit: mitochondrion_tRNA
//     tuple val(meta), path("*.plastid.fa.gz")  , emit: plastid_fa
//     tuple val(meta), path("*.plastid.faa.gz")  , emit: plastid_faa
//     tuple val(meta), path("*.plastid.ffn.gz")  , emit: plastid_ffn
//     tuple val(meta), path("*.plastid.gff.gz")  , emit: plastid_gff
//     tuple val(meta), path("*.plastid.rRNA.gz")  , emit: plastid_rRNA
//     tuple val(meta), path("*.plastid.tRNA.gz")  , emit: plastid_tRNA
//     path "versions.yml", emit: versions

//     when:
//     task.ext.when == null || task.ext.when

//     script:
//     def args = task.ext.args ?: ''
//     def db_name = db[0].baseName.replaceAll(/\..*/, '')
    
//     // Create group-level metadata for outputs
//     // Use task.ext.prefix if provided, otherwise combine genome IDs
//     def prefix = task.ext.prefix ?: metas.collect{ it.id }.join('_')
//     meta = [
//         id: prefix,
//         genome_count: metas.size(),
//         genome_ids: metas.collect{ it.id }
//     ]
    
//     // Create space-separated list of genome IDs for bash array
//     def genome_ids = metas.collect { it.id }.join(' ')
    
//     """
//     # Create contigs_to_genomes.tsv mapping
//     genome_ids=($genome_ids)
//     fastas_array=(${fastas})
    
//     > contigs_to_genomes.tsv
    
//     for i in "\${!fastas_array[@]}"; do
//         fasta="\${fastas_array[\$i]}"
//         genome_id="\${genome_ids[\$i]}"
        
//         if [[ \$fasta == *.gz ]]; then
//             gunzip -c "\$fasta" | grep "^>" | sed 's/^>//' | awk -v gid="\$genome_id" '{print \$1"\\t"gid}' >> contigs_to_genomes.tsv
//         else
//             grep "^>" "\$fasta" | sed 's/^>//' | awk -v gid="\$genome_id" '{print \$1"\\t"gid}' >> contigs_to_genomes.tsv
//         fi
//     done
    
//     # Merge all fasta files into temporary.fasta
//     > temporary.fasta
    
//     for fasta in ${fastas}; do
//         if [[ \$fasta == *.gz ]]; then
//             gunzip -c "\$fasta" >> temporary.fasta
//         else
//             cat "\$fasta" >> temporary.fasta
//         fi
//     done
    
//     # Handle tiara_probabilities if provided
//     tiara_probabilities_arg=""
//     if [ -n "${tiara_probabilities}" ] && [ "${tiara_probabilities}" != "[]" ]; then
//         tiara_files=(${tiara_probabilities})
        
//         # First file with header
//         if [[ \${tiara_files[0]} == *.gz ]]; then
//             gunzip -c "\${tiara_files[0]}" > tiara_merged.tsv
//         else
//             cat "\${tiara_files[0]}" > tiara_merged.tsv
//         fi
        
//         # Remaining files without headers
//         for i in "\${tiara_files[@]:1}"; do
//             if [[ \$i == *.gz ]]; then
//                 gunzip -c "\$i" | tail -n +2 >> tiara_merged.tsv
//             else
//                 tail -n +2 "\$i" >> tiara_merged.tsv
//             fi
//         done
        
//         tiara_probabilities_arg="-t tiara_merged.tsv"
//     fi

//     # Run VEBA Eukaryotic Gene Modeling Wrapper
//     eukaryotic_gene_modeling_wrapper.py \\
//         -p ${task.cpus} \\
//         -i contigs_to_genomes.tsv \\
//         -f temporary.fasta \\
//         -d ${db_name} \\
//         -o results \\
//         --tiara_minimum_length ${minimum_contig_length} \\
//         \${tiara_probabilities_arg} \\
//         ${args}

//     # Move outputs to expected names
//     for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; do
//         gzip -c -n results/output/${prefix}.\${ext} > ${prefix}.nuclear.\${ext}.gz
//     done

//     gzip -c -n results/output/identifier_mapping.metaeuk.tsv > ${prefix}.identifier_mapping.metaeuk.tsv.gz
//     awk -F"\\t" 'NR>1 {print "${prefix}", \$3, \$5}' OFS="\\t" results/output/identifier_mapping.metaeuk.tsv | gzip -n > ${prefix}.identifier_mapping.nuclear.tsv.gz

//     # Mitochondrion
//     for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; do
//         gzip -c -n results/output/mitochondrion/${prefix}.\${ext} > ${prefix}.mitochondrion.\${ext}.gz
//     done

//     # Plastid
//     for ext in "fa" "faa" "ffn" "gff" "rRNA" "tRNA"; do
//         gzip -c -n results/output/plastid/${prefix}.\${ext} > ${prefix}.plastid.\${ext}.gz
//     done

//     # Statistics
//     gzip -c -n results/output/genome_statistics.tsv > ${prefix}.genome_statistics.tsv.gz
//     gzip -c -n results/output/gene_statistics.cds.tsv > ${prefix}.gene_statistics.cds.tsv.gz
//     gzip -c -n results/output/gene_statistics.rRNA.tsv > ${prefix}.gene_statistics.rRNA.tsv.gz
//     gzip -c -n results/output/gene_statistics.tRNA.tsv > ${prefix}.gene_statistics.tRNA.tsv.gz

//     # Cleanup temporary files
//     rm -f temporary.fasta
//     rm -f tiara_merged.tsv
//     rm -rf results/tmp/
//     rm -rf results/output/

//     cat <<-END_VERSIONS > versions.yml
//     "${task.process}":
//         eukaryotic_gene_modeling_wrapper.py: \$(eukaryotic_gene_modeling_wrapper.py --version 2>&1 | cut -f2 -d " " || echo "unknown")
//     END_VERSIONS
//     """

//     stub:
//     def prefix = task.ext.prefix ?: metas.collect{ it.id }.join('_')
//     meta = [
//         id: prefix,
//         genome_count: metas.size(),
//         genome_ids: metas.collect{ it.id }
//     ]
    
//     """
//     touch ${prefix}.identifier_mapping.metaeuk.tsv.gz
//     touch ${prefix}.identifier_mapping.nuclear.tsv.gz
//     touch ${prefix}.genome_statistics.tsv.gz
//     touch ${prefix}.gene_statistics.cds.tsv.gz
//     touch ${prefix}.gene_statistics.rRNA.tsv.gz
//     touch ${prefix}.gene_statistics.tRNA.tsv.gz
//     touch ${prefix}.nuclear.{fa,faa,ffn,gff,rRNA,tRNA}.gz
//     touch ${prefix}.mitochondrion.{fa,faa,ffn,gff,rRNA,tRNA}.gz
//     touch ${prefix}.plastid.{fa,faa,ffn,gff,rRNA,tRNA}.gz
    
//     cat <<-END_VERSIONS > versions.yml
//     "${task.process}":
//         eukaryotic_gene_modeling_wrapper.py: stub
//     END_VERSIONS
//     """
// }