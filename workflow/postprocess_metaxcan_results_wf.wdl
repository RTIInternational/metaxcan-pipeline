import "metaxcan-pipeline/workflow/tasks/adj_csv_pvalue.wdl" as ADJPVALUES
import "metaxcan-pipeline/workflow/tasks/utilities.wdl" as UTIL

# Workflow for correcting S-MultiXcan p-values within and across tissues and filtering significant results
workflow postprocess_metaxcan_results_wf{

    # Metaxcan output files from one or more tissues
    Array[File] metaxcan_output_files

    # Method of pvalue correction
    String pvalue_adj_method

    # Colname where pvalues are found
    String pvalue_colname = "pvalue"

    # Adjusted pvalue filter threshold
    Float adj_pvalue_filter_threshold_across_tissue
    Float adj_pvalue_filter_threshold_within_tissue

    # Output file basenames
    String combined_raw_output_basename = "metaxcan_results_combined"
    String across_tissue_output_basename
    String within_tissue_output_basename

    # Add tissue ID column to end of each s-prediXcan output csv
    # Associates each gene result with the source tissue so we can combine into single file and not lose this info
    scatter (metaxcan_output_file in metaxcan_output_files){
        call UTIL.add_col_to_csv as add_id_col{
            input:
                input_file = metaxcan_output_file,
                colname = "Source",
                value = basename(metaxcan_output_file, ".csv")
        }
    }

    # Concatenate all s-PrediXcan output csvs into one large csv
    call UTIL.cat_csv{
        input:
            input_files = add_id_col.col_output,
            output_base = combined_raw_output_basename
    }

    # Correct gene p-values for all tests ACROSS ALL tissues (more conservative. Num tests = num genes X num tissues)
    call ADJPVALUES.adj_csv_pvalue as across_tissue_adj_pvalue{
        input:
            input_file = cat_csv.cat_csv_output,
            pvalue_colname = pvalue_colname,
            filter_threshold = adj_pvalue_filter_threshold_across_tissue,
            method = pvalue_adj_method,
            output_file_base = across_tissue_output_basename
    }

    # Correct gene p-values for all tests separately WITHIN EACH tissue (less conservative. Num tests = num genes)
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

    # Concatenate all WITHIN-TISSUE CSV results into one file
    call UTIL.cat_csv as gather_within_tissue_csvs {
        input:
            input_files = within_tissue_adj_pvalue.adj_output_file,
            output_base = within_tissue_output_basename
    }

    # Final output files
    output{

        # Raw s-prediXcan output consolidated into single CSV
        File combined_metaxcan_output = cat_csv.cat_csv_output

        # Significant gene hits after correcting for multiple tests ACROSS ALL tissues and filtering based on p-value
        File across_tissue_adj_metaxcan_output = across_tissue_adj_pvalue.adj_output_file

        # Significant gene hits after correcting for multilpe tests WITHIN EACH tissue and filtering based on p-value
        File within_tissue_adj_metaxcan_output = gather_within_tissue_csvs.cat_csv_output
    }
}