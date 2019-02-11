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
    File output_file = "${output_file_base}.p_adjusted.csv"
    command {
        Rscript /opt/code_docker_lib/adjust_csv_pvalue.R --input_file ${input_file} \
            --output_file ./${output_file} \
            --pvalue_colname ${pvalue_colname} \
            --method ${method} ${"--n " + num_comparisons} ${"--filter_threshold " + filter_threshold}
    }
    output{
        # Count number of records by subtracting out header line for each file
        File adj_output_file = "${output_file}"
    }
    runtime {
        docker: "alexwaldrop/adjust_csv_pvalue:122f10e0b18706d61ab76ba7d5f44eca2581c92a"
        cpu: "1"
        memory: "1 GB"
    }
}
