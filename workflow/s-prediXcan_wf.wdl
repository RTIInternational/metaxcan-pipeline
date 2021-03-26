import "metaxcan-pipeline/workflow/tasks/summary_gwas_imputation.wdl" as PREPROCESSING
import "metaxcan-pipeline/workflow/tasks/metaxcan.wdl" as METAXCAN
import "metaxcan-pipeline/workflow/postprocess_metaxcan_results_wf.wdl" as POSTPROCESSING
import "metaxcan-pipeline/workflow/tasks/utilities.wdl" as UTIL

workflow spredixcan_wf {

    # Analysis name to be appended to filenames
    String analysis_name

    ########### Inputs for standardizing GWAS/Meta-analysis output files for input to metaxcan preprocessing
    # GWAS/Meta-analysis output files that will be used for S-PrediXcan
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

    # Memory for gwas sumstat harmonization
    Int harmonize_mem_gb = 6

    # Whether to prepend 'chr' to chromosome names
    Boolean chr_format_out = true

    # Handle any whitespace character (tabs or spaces)
    String sumstats_in_separator = "ANY_WHITESPACE"

    # Optionally skip lines beginning with the specified character
    String? harmonize_skip_until_header

    ########### Inputs for s-predixcan
    # Tissue specific PredictDB expression models used by MetaXcan to predict gene expression from genotypes
    Array[File] model_db_files
    # Tissue specific PredictDB covariance files used by MetaXcan
    Array[File] covariance_files

    ########### Inputs for p-value correction
    String pvalue_adj_method
    # P-value thresholds for filtering s-PrediXcan results after multiple test correction
    Float adj_pvalue_filter_threshold_within_tissue
    Float adj_pvalue_filter_threshold_across_tissue

    # Basenames for final output files. Defaults can be changed as needed in the input json.
    String across_tissue_output_basename = "${analysis_name}_metaxcan_results_across_tissue_${pvalue_adj_method}_${adj_pvalue_filter_threshold_across_tissue}"
    String within_tissue_output_basename = "${analysis_name}_metaxcan_results_within_tissue_${pvalue_adj_method}_${adj_pvalue_filter_threshold_within_tissue}"

    ####################### MAIN PROGRAM ##############################

    # Standardize GWAS/Meta-analysis output files.
    #   Makes sure columns required by MetaXcan are present and in the correct order
    #   Replaces spaces with tabs
    #   Standardizes column names for input to metaxcan_preprocessing step
    scatter (chr_index in range(length(chrs))){
        # Scatter call runs input files in parallel by chromosome
        call PREPROCESSING.harmonize_sumstats{
            input:
                sumstats_in = gwas_input_files[chr_index],
                snp_ref_metadata = snp_ref_metadata_files[chr_index],
                liftover_key = liftover_key,
                id_colname_in = id_colname_in,
                pos_colname_in = pos_colname_in,
                chr_colname_in = chr_colname_in,
                effect_allele_colname_in = effect_allele_colname_in,
                non_effect_allele_colname_in = non_effect_allele_colname_in,
                effect_size_colname_in = effect_size_colname_in,
                pvalue_colname_in = pvalue_colname_in,
                chr_format_out = chr_format_out,
                separator = sumstats_in_separator,
                skip_until_header = harmonize_skip_until_header,
                mem_gb = harmonize_mem_gb
        }
    }

    # Run s-prediXcan in parallel across input tissue types
    scatter (model_index in range(length(model_db_files))){
        call METAXCAN.metaxcan as spredixcan{
            input:
                model_db_file = model_db_files[model_index],
                covariance_file = covariance_files[model_index],
                gwas_files = harmonize_sumstats.output_file,
                snp_column = "panel_variant_id",
                effect_allele_column = "effect_allele",
                non_effect_allele_column = "non_effect_allele",
                beta_column = "effect_size",
                pvalue_column = "pvalue",
                se_column = "standard_error",
                model_db_snp_key = "varID"

        }
    }

    # Adjust metaxcan p-values within and across tissue types and filter significant hits
    call POSTPROCESSING.postprocess_metaxcan_results_wf as postprocessing{
        input:
            # Metaxcan output files from one or more tissues
            metaxcan_output_files = spredixcan.metaxcan_output,
            pvalue_adj_method=pvalue_adj_method,
            pvalue_colname="pvalue",
            adj_pvalue_filter_threshold_across_tissue=adj_pvalue_filter_threshold_across_tissue,
            adj_pvalue_filter_threshold_within_tissue=adj_pvalue_filter_threshold_within_tissue,
            across_tissue_output_basename=across_tissue_output_basename,
            within_tissue_output_basename=within_tissue_output_basename
    }

    # Final output files
    output{

        # Input files used for running metaxcan
        Array[File] metaxcan_input = harmonize_sumstats.output_file

        # Raw s-prediXcan output CSVs for each tissue tested
        Array[File] metaxcan_output = spredixcan.metaxcan_output

        # Raw s-prediXcan output consolidated into single CSV
        File combined_metaxcan_output = postprocessing.combined_metaxcan_output

        # Significant gene hits after correcting for multiple tests ACROSS ALL tissues and filtering based on p-value
        File across_tissue_adj_metaxcan_output = postprocessing.across_tissue_adj_metaxcan_output

        # Significant gene hits after correcting for multilpe tests WITHIN EACH tissue and filtering based on p-value
        File within_tissue_adj_metaxcan_output = postprocessing.within_tissue_adj_metaxcan_output
    }

}