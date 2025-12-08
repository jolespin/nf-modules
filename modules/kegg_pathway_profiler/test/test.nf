#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { PROFILE_PATHWAY_COVERAGE_FROM_PYKOFAMSEARCH } from "../main"

workflow {
    // Inputs
    identifier_mapping_ch = Channel.fromPath(params.identifier_mapping, checkIfExists: true)
    pykofamsearch_results_ch = Channel.fromPath(params.pykofamsearch_results, checkIfExists: true)
    db_ch = Channel.fromPath(params.db, checkIfExists: true)

    // Add meta
    identifier_mapping_with_meta_ch = identifier_mapping_ch.map { file ->
        def meta = [id: "all_samples"]
        return [meta, file]
    }
    pykofamsearch_results_with_meta_ch = pykofamsearch_results_ch.map { file ->
        def meta = [id: "all_samples"]
        return [meta, file]
    }
    db_with_meta = db_ch.map { files ->
        def meta = [id: file(params.db).baseName]
        return [meta, files]
    }

    // Run the process with the prepared channel.
    PROFILE_PATHWAY_COVERAGE_FROM_PYKOFAMSEARCH(
        identifier_mapping_with_meta_ch,
        pykofamsearch_results_with_meta_ch,
        db_with_meta,
        3,
	)

    // View the output to confirm the pipeline ran successfully.
    PROFILE_PATHWAY_COVERAGE_FROM_PYKOFAMSEARCH.out.coverage_report.view()
    PROFILE_PATHWAY_COVERAGE_FROM_PYKOFAMSEARCH.out.serialized_results.view()

}