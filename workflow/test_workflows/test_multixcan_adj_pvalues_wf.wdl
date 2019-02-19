import "metaxcan-pipeline/workflow/tasks/adj_csv_pvalue.wdl" as ADJPVALUES


workflow smultixcan_pvalue_adj_wf {

    # P-value correciton inputs
    File smultixcan_output
    String pvalue_adj_method
    Float adj_pvalue_filter_threshold
    String pvalue_colname = "pvalue"


    # Basename for final output file
    String pvalue_output_basename = "s-MulTiXcan_results_${pvalue_adj_method}_${adj_pvalue_filter_threshold}"


    # Correct for multiple tests across tissues (more conservative)
    call ADJPVALUES.adj_csv_pvalue as adj_pvalue{
        input:
            input_file = smultixcan_output,
            pvalue_colname = pvalue_colname,
            filter_threshold = adj_pvalue_filter_threshold,
            method = pvalue_adj_method,
            output_file_base = pvalue_output_basename,
            tab_delimited=true
    }

    output{
        File smultixcan_corrected_output = adj_pvalue.adj_output_file
    }

}