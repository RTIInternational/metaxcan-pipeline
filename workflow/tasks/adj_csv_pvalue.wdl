task adj_csv_pvalue{
    # Take used to take a CSV file with a columns of pvalues as input
    # Outputs the same CSV with p-values adjusted for multiple comparisons
    # Optionally can include a filter threshold to omit row entries with p-values above threshold from output
    File input_file
    String pvalue_colname
    String method
    String output_file_base
    Float? filter_threshold
    Int? num_comparisons

    # Boolean for whether input file is tab delimited (default is false to assume comma-separated)
    Boolean tab_delimited = false
    File output_file = "${output_file_base}.p_adjusted.csv"
    command {
        Rscript /opt/code_docker_lib/adjust_csv_pvalue.R --input_file ${input_file} \
            --output_file ./${output_file} \
            --pvalue_colname ${pvalue_colname} \
            --method ${method} ${"--n " + num_comparisons} ${"--filter_threshold " + filter_threshold} ${true="--tab_delimited" false="" tab_delimited}
    }
    output{
        # Count number of records by subtracting out header line for each file
        File adj_output_file = "${output_file}"
    }
    runtime {
        docker: "alexwaldrop/adjust_csv_pvalue:a40b48623a4877766f8a388046a2dd2cebe9d8f6"
        cpu: "1"
        memory: "1 GB"
    }
}
