import "metaxcan-pipeline/workflow/tasks/adj_csv_pvalue.wdl" as ADJPVALUES
import "metaxcan-pipeline/workflow/s-prediXcan_wf.wdl" as METAXCAN
import "metaxcan-pipeline/workflow/tasks/metaxcan.wdl" as MULTIXCAN

workflow smultixcan_wf {

    # Analysis name to be appended to filenames
    String analysis_name

    ########### Inputs for S-PrediXcan pipeline
    Array[File] gwas_input_files
    Int input_id_col
    Int input_chr_col
    Int input_pos_col
    Int input_a1_col
    Int input_a2_col
    Int input_beta_col
    Int input_se_col
    Int input_pvalue_col
    Array[Int] chrs
    Array[File] legend_files_1000g
    File gtex_variant_file
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
            legend_files_1000g = legend_files_1000g,
            covariance_files = metaxcan_covariance_files,
            gtex_variant_file = gtex_variant_file,
            chrs = chrs,
            adj_pvalue_filter_threshold_within_tissue = adj_pvalue_filter_threshold_within_tissue,
            adj_pvalue_filter_threshold_across_tissue = adj_pvalue_filter_threshold_across_tissue,
            input_id_col = input_id_col,
            input_chr_col = input_chr_col,
            input_pos_col = input_pos_col,
            input_a1_col = input_a1_col,
            input_a2_col = input_a2_col,
            input_beta_col = input_beta_col,
            input_se_col = input_se_col,
            input_pvalue_col = input_pvalue_col,
            pvalue_adj_method = pvalue_adj_method
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
            snp_column = "SNP",
            effect_allele_column = "A1",
            non_effect_allele_column = "A2",
            beta_column = "BETA",
            pvalue_column = "P",
            se_column = "StdErr",
            cutoff_threshold=smultixcan_cutoff_threshold
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