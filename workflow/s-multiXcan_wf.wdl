import "metaxcan-pipeline/workflow/tasks/metaxcan_preprocessing.wdl" as PREPROCESSING
import "metaxcan-pipeline/workflow/tasks/metaxcan.wdl" as METAXCAN
import "metaxcan-pipeline/workflow/tasks/adj_csv_pvalue.wdl" as ADJPVALUES
import "metaxcan-pipeline/workflow/tasks/utilities.wdl" as UTIL

workflow smultixcan_wf {

    # Inputs for standardizing input file before metaxcan preprocessing
    Array[File] gxg_meta_analysis_files
    Int input_id_col
    Int input_chr_col
    Int input_pos_col
    Int input_a1_col
    Int input_a2_col
    Int input_beta_col
    Int input_se_col
    Int input_pvalue_col

    # Inputs for metaxcan preprocessing
    Array[File] legend_files_1000g
    Array[Int] chrs
    File gtex_variant_file
    String preprocessing_output_base = "processed_metaxcan_input"

   # Inputs for metaxcan/smultixcan
    Array[File] model_db_files
    Array[File] metaxcan_covariance_files
    File smultixcan_covariance_file
    String model_name_pattern
    String metaxcan_file_name_parse_pattern
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String beta_column
    String pvalue_column
    String se_column
    Float smultixcan_cutoff_threshold = 0.4

    # P-value correciton inputs
    String pvalue_adj_method
    Float adj_pvalue_filter_threshold
    String pvalue_colname = "pvalue"


    # Basename for final output file
    String smultixcan_output_basename = "s-MulTiXcan_results"
    String pvalue_output_basename = "s-MulTiXcan_results_${pvalue_adj_method}_${adj_pvalue_filter_threshold}"

    # Standardize input files in parallel
    scatter (chr_index in range(length(chrs))){
        call PREPROCESSING.standardize_input_cols{
            input:
                gxg_meta_analysis_file = gxg_meta_analysis_files[chr_index],
                id_col = input_id_col,
                chr_col = input_chr_col,
                pos_col = input_pos_col,
                a1_col = input_a1_col,
                a2_col = input_a2_col,
                beta_col = input_beta_col,
                se_col = input_se_col,
                pvalue_col = input_pvalue_col
        }
    }

    # Preprocess metaxcan input in parallel
    scatter (chr_index in range(length(chrs))){
        call PREPROCESSING.preprocess_metaxcan_chr as preprocessing {
            input:
                gxg_meta_analysis_file = standardize_input_cols.output_file[chr_index],
                chr = chrs[chr_index],
                legend_file_1000g = legend_files_1000g[chr_index],
                gtex_variant_file = gtex_variant_file,
                output_base = preprocessing_output_base
        }
    }

    # Run s-prediXcan in parallel across input tissue types
    scatter (model_index in range(length(model_db_files))){
        call METAXCAN.metaxcan as metaxcan{
            input:
                model_db_file = model_db_files[model_index],
                covariance_file = metaxcan_covariance_files[model_index],
                gwas_files = preprocessing.metaxcan_ready_output_file,
                snp_column = snp_column,
                effect_allele_column = effect_allele_column,
                non_effect_allele_column = non_effect_allele_column,
                beta_column = beta_column,
                pvalue_column = pvalue_column,
                se_column = se_column
        }
    }


    # Run s-MulTiXcan on s-PrediXcan results to test for associations across multiple tissue types
    call METAXCAN.smultixcan as smultixcan{
        input:
            model_db_files = model_db_files,
            metaxcan_output_files = metaxcan.metaxcan_output,
            gwas_files = preprocessing.metaxcan_ready_output_file,
            covariance_file = smultixcan_covariance_file,
            model_name_pattern = model_name_pattern,
            metaxcan_file_name_parse_pattern = metaxcan_file_name_parse_pattern,
            output_base = smultixcan_output_basename,
            snp_column = snp_column,
            effect_allele_column = effect_allele_column,
            non_effect_allele_column = non_effect_allele_column,
            beta_column = beta_column,
            pvalue_column = pvalue_column,
            se_column = se_column,
            cutoff_threshold=smultixcan_cutoff_threshold
     }

         # Correct for multiple tests across tissues (more conservative)
    call ADJPVALUES.adj_csv_pvalue as adj_pvalue{
        input:
            input_file = smultixcan.smultixcan_output,
            pvalue_colname = pvalue_colname,
            filter_threshold = adj_pvalue_filter_threshold,
            method = pvalue_adj_method,
            output_file_base = pvalue_output_basename,
            tab_delimited=true
    }

    output{
        Array[File] metaxcan_output = metaxcan.metaxcan_output
        File smultixcan_output = smultixcan.smultixcan_output
        File smultixcan_corrected_output = adj_pvalue.adj_output_file
    }

}