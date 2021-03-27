import "metaxcan-pipeline/workflow/tasks/adj_csv_pvalue.wdl" as ADJPVALUES
import "metaxcan-pipeline/workflow/s-prediXcan_wf.wdl" as METAXCAN
import "metaxcan-pipeline/workflow/tasks/metaxcan.wdl" as MULTIXCAN

workflow smultixcan_wf {

    # Analysis name to be appended to filenames
    String analysis_name

    ########### Inputs for S-PrediXcan pipeline
    Array[File] gwas_input_files
    Array[File] snp_ref_metadata_files
    File? liftover_key
    Array[Int] chrs

    # Names of columns to standardize from input
    String id_colname_in
    String pos_colname_in
    String chr_colname_in
    String effect_allele_colname_in
    String non_effect_allele_colname_in
    String effect_size_colname_in
    String pvalue_colname_in

    # Whether to prepend 'chr' to chromosome names
    Boolean chr_format_out = true

    # Handle any whitespace character (tabs or spaces)
    String sumstats_in_separator = "ANY_WHITESPACE"

    # Optionally skip lines beginning with the specified character
    String? harmonize_skip_until_header

    ########### Inputs for imputation
    Array[File] parquet_genotypes
    File parquet_genotype_metadata
    File impute_region_file

    Int impute_window = 100000
    Float impute_frequency_filter = 0.01
    Float impute_regularization = 0.1
    Boolean impute_standardize_dosages = true
    Boolean impute_keep_all_observed = true

    # Compute resources per chr
    Int harmonize_cpu = 1
    Int harmonize_mem_gb = 6
    Int impute_cpu = 1
    Int impute_mem_gb = 10
    Int postprocess_cpu = 1
    Int postprocess_mem_gb = 2

    ########### Inputs for s-predixcan
    Array[File] model_db_files
    Array[File] metaxcan_covariance_files
    Float adj_pvalue_filter_threshold_within_tissue
    Float adj_pvalue_filter_threshold_across_tissue

    ########### Inputs for S-MulTiXcan
    File smultixcan_covariance_file
    String model_name_pattern
    String metaxcan_file_name_parse_pattern
    Float smultixcan_cutoff_threshold

    ########### Inputs for p-value correction
    String pvalue_adj_method
    Float adj_pvalue_filter_threshold

    # Basenames for final output files. Defaults can be changed as needed in the input json.
    String smultixcan_output_basename = "${analysis_name}_s-MulTiXcan_results"
    String sig_smultixcan_hits_basename = "${analysis_name}_s-MulTiXcan_results_${pvalue_adj_method}_${adj_pvalue_filter_threshold}"

    ####################### MAIN PROGRAM ##############################


    # Run s-prediXcan in parallel across each input tissue types. These outputs will be combined by MulTiXcan
    call METAXCAN.spredixcan_wf as metaxcan{
        input:
            analysis_name = analysis_name,
            gwas_input_files = gwas_input_files,
            model_db_files = model_db_files,
            snp_ref_metadata_files = snp_ref_metadata_files,
            liftover_key = liftover_key,
            covariance_files = metaxcan_covariance_files,
            chrs = chrs,
            id_colname_in = id_colname_in,
            chr_colname_in = chr_colname_in,
            pos_colname_in = pos_colname_in,
            effect_allele_colname_in = effect_allele_colname_in,
            non_effect_allele_colname_in = non_effect_allele_colname_in,
            effect_size_colname_in = effect_size_colname_in,
            pvalue_colname_in = pvalue_colname_in,
            harmonize_mem_gb = harmonize_mem_gb,
            chr_format_out = chr_format_out,
            sumstats_in_separator = sumstats_in_separator,
            harmonize_skip_until_header = harmonize_skip_until_header,
            parquet_genotypes = parquet_genotypes,
            parquet_genotype_metadata = parquet_genotype_metadata,
            impute_region_file = impute_region_file,
            impute_window = impute_window,
            impute_frequency_filter = impute_frequency_filter,
            impute_regularization = impute_regularization,
            impute_standardize_dosages = impute_standardize_dosages,
            impute_keep_all_observed = impute_keep_all_observed,
            pvalue_adj_method = pvalue_adj_method,
            adj_pvalue_filter_threshold_within_tissue = adj_pvalue_filter_threshold_within_tissue,
            adj_pvalue_filter_threshold_across_tissue = adj_pvalue_filter_threshold_across_tissue,
            harmonize_cpu = harmonize_cpu,
            harmonize_mem_gb = harmonize_mem_gb,
            impute_cpu = impute_cpu,
            impute_mem_gb = impute_mem_gb,
            postprocess_cpu = postprocess_cpu,
            postprocess_mem_gb = postprocess_mem_gb
    }

    # Run s-MulTiXcan on s-PrediXcan results to test for associations across multiple tissue types
    call MULTIXCAN.smultixcan as smultixcan{
        input:
            model_db_files = model_db_files,
            metaxcan_output_files = metaxcan.metaxcan_output,
            gwas_files = metaxcan.metaxcan_input,
            covariance_file = smultixcan_covariance_file,
            model_name_pattern = model_name_pattern,
            metaxcan_file_name_parse_pattern = metaxcan_file_name_parse_pattern,
            output_base = smultixcan_output_basename,
            snp_column = "panel_variant_id",
            effect_allele_column = "effect_allele",
            non_effect_allele_column = "non_effect_allele",
            zscore_column = "zscore",
            pvalue_column = "pvalue",
            se_column = "standard_error",
            cutoff_threshold=smultixcan_cutoff_threshold,
            model_db_snp_key = "varID"
     }

    # Correct S-MulTiXcan gene p-values for multiple tests (Num tests = num genes)
    call ADJPVALUES.adj_csv_pvalue as adj_pvalue{
        input:
            input_file = smultixcan.smultixcan_output,
            pvalue_colname = "pvalue",
            filter_threshold = adj_pvalue_filter_threshold,
            method = pvalue_adj_method,
            output_file_base = sig_smultixcan_hits_basename,
            tab_delimited=true
    }

    # Output files
    output{
        # Raw s-prediXcan output CSVs for each tissue tested
        Array[File] metaxcan_output = metaxcan.metaxcan_output

        # Raw s-mulTiXcan output CSV
        File smultixcan_output = smultixcan.smultixcan_output

        # Significant s-mulTiXcan gene hits after correcting for multiple tests
        File smultixcan_corrected_output = adj_pvalue.adj_output_file

        # Raw s-prediXcan output consolidated into single CSV
        File combined_metaxcan_output = metaxcan.combined_metaxcan_output

        # Significant gene hits after correcting for multiple tests ACROSS ALL tissues and filtering based on p-value
        File across_tissue_adj_metaxcan_output = metaxcan.across_tissue_adj_metaxcan_output

        # Significant gene hits after correcting for multilpe tests WITHIN EACH tissue and filtering based on p-value
        File within_tissue_adj_metaxcan_output = metaxcan.within_tissue_adj_metaxcan_output
    }

}