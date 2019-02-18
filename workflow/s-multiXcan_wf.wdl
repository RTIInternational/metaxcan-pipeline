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

    # Inputs for metamany
    Array[File] model_db_files
    Array[String] model_db_glob_patterns
    Array[File] covariance_files
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String beta_column
    String pvalue_column
    String se_column

    # Inputs for p-value adjusting
    String pvalue_adj_method
    String pvalue_colname = "pvalue"

    Float adj_pvalue_filter_threshold_within_tissue
    Float adj_pvalue_filter_threshold_across_tissue

    # Basename for final output files
    String combined_output_basename = "metaxcan_results_combined"
    String across_tissue_output_basename = "metaxcan_results_across_tissue_${pvalue_adj_method}_${adj_pvalue_filter_threshold_across_tissue}"
    String within_tissue_output_basename = "metaxcan_results_within_tissue_${pvalue_adj_method}_${adj_pvalue_filter_threshold_within_tissue}"

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
        call METAXCAN.metaxcan{
            input:
                model_db_file = model_db_files[model_index],
                covariance_file = covariance_files[model_index],
                gwas_files = preprocessing.metaxcan_ready_output_file,
                snp_column = snp_column,
                effect_allele_column = effect_allele_column,
                non_effect_allele_column = non_effect_allele_column,
                beta_column = beta_column,
                pvalue_column = pvalue_column,
                se_column = se_column
        }
    }

    # Add ID column to end of each s-prediXcan output so we can combine and still have source file info
    scatter (metaxcan_output in metaxcan.metaxcan_output){
        call UTIL.add_col_to_csv as add_id_col{
            input:
                input_file = metaxcan_output,
                colname = "Source",
                value = basename(metaxcan_output, ".csv")
        }
    }

    # Concatenate all CSVs into one large csv
    call UTIL.cat_csv{
        input:
            input_files = add_id_col.col_output,
            output_base = combined_output_basename
    }

    # Correct for multiple tests across tissues (more conservative)
    call ADJPVALUES.adj_csv_pvalue as across_tissue_adj_pvalue{
        input:
            input_file = cat_csv.cat_csv_output,
            pvalue_colname = pvalue_colname,
            filter_threshold = adj_pvalue_filter_threshold_across_tissue,
            method = pvalue_adj_method,
            output_file_base = across_tissue_output_basename
    }

    # Correct for multiple tests within tissues (less conservative)
    scatter (metaxcan_output_with_id in add_id_col.col_output){
        call ADJPVALUES.adj_csv_pvalue as within_tissue_adj_pvalue{
            input:
                input_file = metaxcan_output_with_id,
                pvalue_colname = pvalue_colname,
                filter_threshold = adj_pvalue_filter_threshold_within_tissue,
                method = pvalue_adj_method,
                output_file_base = basename(metaxcan_output_with_id, ".csv")
        }
    }

    # Concatenate all within-tissue CSVs into one file
    call UTIL.cat_csv as gather_within_tissue_csvs {
        input:
            input_files = within_tissue_adj_pvalue.adj_output_file,
            output_base = within_tissue_output_basename
    }

    output{
        Array[File] metaxcan_output = metaxcan.metaxcan_output
        File combined_metaxcan_output = cat_csv.cat_csv_output
        File across_tissue_adj_metaxcan_output = across_tissue_adj_pvalue.adj_output_file
        File within_tissue_adj_metaxcan_output = gather_within_tissue_csvs.cat_csv_output
    }

}