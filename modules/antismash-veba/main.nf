process ANTISMASH {
    tag "${meta.id}"
    label 'process_medium'

    container "docker.io/jolespin/antismash-veba:8.0.4"

    input:
    tuple val(meta), path(assembly_fasta), path(gff)
    val taxon                                                             // Taxonomic classification of input sequence. {bacteria,fungi}
    path databases                                                        // Path to antiSMASH database
    val cc_mibig                                                          // Run a comparison against the MIBiG dataset
    val cb_general                                                        // Compare identified clusters against a database of antiSMASH-predicted clusters.
    val cb_subclusters                                                    // Compare identified clusters against known subclusters responsible for synthesising precursors.
    val cb_knownclusters                                                  // Compare identified clusters against known gene clusters from the MIBiG database.
    val reformat_with_veba                                                // Reformat the output to be compatible with VEBA
  
    output:
    tuple val(meta), path("${prefix}/{css,images,js}")                    , emit: html_accessory_files
    tuple val(meta), path("${prefix}/*.gbk.gz")                           , emit: gbk_input
    tuple val(meta), path("${prefix}/*.json.gz")                          , emit: json_results
    tuple val(meta), path("${prefix}/*.log")                              , emit: log
    tuple val(meta), path("${prefix}/*.zip")                              , emit: zip
    tuple val(meta), path("${prefix}/index.html")                         , emit: html
    tuple val(meta), path("${prefix}/regions.js")                         , emit: json_sideloading

    // Clusterblast Files
    tuple val(meta), path("${prefix}/clusterblast_results.tsv.gz")        , emit: clusterblast_results       , optional: true
    tuple val(meta), path("${prefix}/clusterblast.tar.gz")                , emit: clusterblast_archive       , optional: true
    tuple val(meta), path("${prefix}/knownclusterblast.tar.gz")           , emit: knownclusterblast_archive  , optional: true
    tuple val(meta), path("${prefix}/subclusterblast.tar.gz")             , emit: subclusterblast_archive    , optional: true
    tuple val(meta), path("${prefix}/bgc_genbanks/*region*.gbk.gz")       , emit: gbk_results                , optional: true

    // VEBA Files
    tuple val(meta), path("${prefix}/veba_reformatted/identifier_mapping.components.tsv.gz"), emit: identifier_mapping_components, optional: true
    tuple val(meta), path("${prefix}/veba_reformatted/identifier_mapping.bgcs.tsv.gz")      , emit: identifier_mapping_bgcs, optional: true
    tuple val(meta), path("${prefix}/veba_reformatted/bgc_protocluster-types.tsv.gz")       , emit: protoclusters, optional: true
    tuple val(meta), path("${prefix}/veba_reformatted/fasta/components.faa.gz")             , emit: protein_fasta, optional: true
    tuple val(meta), path("${prefix}/veba_reformatted/fasta/bgcs.fasta.gz")                 , emit: bgc_fasta, optional: true


    path "versions.yml"                                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"

    // Handle clusterblast and knownclusterblast options
    def cc_mibig_flag = cc_mibig ? "--cc-mibig" : ""
    def cb_general_flag = cb_general ? "--cb-general" : ""
    def cb_subclusters_flag = cb_subclusters ? "--cb-subclusters" : ""
    def cb_knownclusters_flag = cb_knownclusters ? "--cb-knownclusters" : ""
    def veba_reformat_flag = reformat_with_veba ? "biosynthetic_genbanks_to_table.py -i ${prefix} -n ${prefix} -o ${prefix}/veba_reformatted --sample ${prefix}" : ""
    def cb_general_cleanup = cb_general ? "tar zcfv clusterblast.tar.gz clusterblast" : ""
    def cb_knownclusters_cleanup = cb_general ? "tar zcfv knownclusterblast.tar.gz knownclusterblast" : ""
    def cb_subclusters_cleanup = cb_general ? "tar zcfv subclusterblast.tar.gz subclusterblast" : ""
    def cb_flags = [
        cb_general ? "--cb-general" : "",
        cb_subclusters ? "--cb-subclusters" : "",
        cb_knownclusters ? "--cb-knownclusters" : ""
    ].findAll { it }.join(" ")

    def cluster_reformatter = cb_flags ? "reformat_antismash_clusterblast.py -i ${prefix} -o ${prefix}/clusterblast_results.tsv.gz" : ""

    // Handle assembly_fasta decompression
    def assembly_fasta_file = ""
    def sequence_decompress_cmd = ""
    def sequence_cleanup = ""

    if (assembly_fasta.toString().endsWith('.gz')) {
        assembly_fasta_file = "${prefix}.fasta"
        sequence_decompress_cmd = "gunzip -c ${assembly_fasta} > ${assembly_fasta_file}"
        sequence_cleanup = "rm -fv ${assembly_fasta_file}"
    }
    else {
        assembly_fasta_file = "${assembly_fasta}"
    }

    // Handle GFF decompression
    def gff_input = ""
    def gff_cleanup = ""
    def gff_decompress_cmd = ""

    if (gff) {
        if (gff.toString().endsWith('.gz')) {
            gff_input = "${prefix}.gff"
            gff_decompress_cmd = "gunzip -c ${gff} > ${gff_input}"
            gff_cleanup = "rm -fv ${gff_input}"
        }
        else {
            gff_input = "${gff}"
        }
    }

    def gff_flag = gff ? "--genefinding-gff3 ${gff_input}" : ""

    """
    # Decompress inputs
    ${sequence_decompress_cmd}
    ${gff_decompress_cmd}

    # antiSMASH
    antismash \\
        ${args} \\
        ${gff_flag} \\
        -c ${task.cpus} \\
        --html-title ${prefix} \\
        --output-dir ${prefix} \\
        --output-basename ${prefix} \\
        --genefinding-tool none \\
        --logfile ${prefix}/${prefix}.log \\
        --databases ${databases} \\
        ${cc_mibig_flag} \\
        ${cb_general_flag} \\
        ${cb_subclusters_flag} \\
        ${cb_knownclusters_flag} \\
        ${assembly_fasta_file}

    # VEBA reformat
    ${veba_reformat_flag} 2>/dev/null || true

    # Move BGC genbanks (if any exist)
    mkdir -p ${prefix}/bgc_genbanks/
    gzip -v -f -n ${prefix}/*.gbk
    mv -v ${prefix}/*.region*.gbk.gz ${prefix}/bgc_genbanks/ 2>/dev/null || true

    # Reformat clusterblast
    ${cluster_reformatter}
    ${cb_general_cleanup}
    ${cb_knownclusters_cleanup}
    ${cb_subclusters_cleanup}

    # Clean up
    gzip -v -f -n ${prefix}/*.json
    ${gff_cleanup}
    ${sequence_cleanup}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        antismash: \$(echo \$(antismash --version) | sed 's/antiSMASH //;s/-.*//g')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}/css
    mkdir ${prefix}/images
    mkdir ${prefix}/js
    touch ${prefix}/bgc_genbanks/NZ_CP069563.1.region001.gbk.gz
    touch ${prefix}/bgc_genbanks/NZ_CP069563.1.region002.gbk.gz
    touch ${prefix}/css/bacteria.css
    touch ${prefix}/genome.gbk.gz
    touch ${prefix}/genome.json.gz
    touch ${prefix}/genome.zip
    touch ${prefix}/images/about.svg
    touch ${prefix}/index.html
    touch ${prefix}/js/antismash.js
    touch ${prefix}/js/jquery.js
    touch ${prefix}/regions.js
    touch ${prefix}/test.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        antismash: \$(echo \$(antismash --version) | sed 's/antiSMASH //;s/-.*//g')
    END_VERSIONS
    """
}