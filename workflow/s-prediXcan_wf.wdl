import "metaxcan-pipeline/workflow/tasks/metaxcan_preprocessing.wdl" as PREPROCESSING
import "metaxcan-pipeline/workflow/tasks/metaxcan.wdl" as METAXCAN
import "metaxcan-pipeline/workflow/postprocess_metaxcan_results_wf.wdl" as POSTPROCESSING
import "metaxcan-pipeline/workflow/tasks/utilities.wdl" as UTIL

workflow spredixcan_wf {

    # Analysis name to be appended to filenames
    String analysis_name

    ########### Inputs for standardizing GWAS/Meta-analysis output files for input to metaxcan preprocessing
    # GWAS/Meta-analysis output files that will be used for S-PrediXcan
    Array[File] gwas_input_files
    # 1-based column indices of required information columns
    Int input_id_col
    Int input_chr_col
    Int input_pos_col
    Int input_a1_col
    Int input_a2_col
    Int input_beta_col
    Int input_se_col
    Int input_pvalue_col

    ########### Inputs for metaxcan preprocessing
    Array[Int] chrs
    # 1000g legend files used to convert GWAS/Meta-analysis snp ids to correct PredictDB ids
    Array[File] legend_files_1000g
    # PredictDB variant annotation file
    File gtex_variant_file

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
        call PREPROCESSING.standardize_input_cols{
            input:
                gxg_meta_analysis_file = gwas_input_files[chr_index],
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

    # Transforms standardized GWAS/Meta-analysis files into s-predixcan input files
    # Uses the PredictDB variant annotations (gtex_variant_file) and 1000g legend files to
    #   Convert PredictDB snp_ids and GWAS/Meta-analysis snp_ids to common snp_id (1000g ids)
    #   Subset GWAS/Meta-analysis snps to include only those present in predictDB models
    #   Convert GWAS/Meta-analysis snp ids to PredictDB ids so GWAS scores are compatiable with PredictDB models used by MetaXcan
    scatter (chr_index in range(length(chrs))){
        call PREPROCESSING.preprocess_metaxcan_chr as preprocessing {
            input:
                gxg_meta_analysis_file = standardize_input_cols.output_file[chr_index],
                chr = chrs[chr_index],
                legend_file_1000g = legend_files_1000g[chr_index],
                gtex_variant_file = gtex_variant_file,
                output_base = "processed_metaxcan_input"
        }
    }

    # Run s-prediXcan in parallel across input tissue types
    scatter (model_index in range(length(model_db_files))){
        call METAXCAN.metaxcan as spredixcan{
            input:
                model_db_file = model_db_files[model_index],
                covariance_file = covariance_files[model_index],
                gwas_files = preprocessing.metaxcan_ready_output_file,
                snp_column = "SNP",
                effect_allele_column = "A1",
                non_effect_allele_column = "A2",
                beta_column = "BETA",
                pvalue_column = "P",
                se_column = "StdErr"
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
        Array[File] metaxcan_input = preprocessing.metaxcan_ready_output_file

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