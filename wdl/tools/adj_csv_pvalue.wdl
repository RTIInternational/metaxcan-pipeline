task adj_csv_pvalue{
    File input_file
    String pvalue_colname
    String? method
    Float? filter_threshold
    Int? num_comparisons
    String output_file_base = basename(input_file, ".csv")
    File output_file = "${output_file_base}.p_adjusted.csv"
    command {
        Rscript /opt/code_docker_lib/adjust_csv_pvalue.R --input_file ${input_file} \
            --output_file ./${output_file} \
            --pvalue_colname ${pvalue_colname} ${"--method " +  method} ${"--n " + num_comparisons} ${"--filter_threshold " + filter_threshold}
    }
    output{
        # Count number of records by subtracting out header line for each file
        File adj_output_file = "${output_file}"
    }
    runtime {
        docker: "alexwaldrop/adjust_csv_pvalue:0a8448a04115f522bf112de088c6bc9ce363b442"
        cpu: "1"
        memory: "1 GB"
    }
}
