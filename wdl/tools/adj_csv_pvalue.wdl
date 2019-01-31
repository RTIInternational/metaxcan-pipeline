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
        docker: "alexwaldrop/adjust_csv_pvalue:122f10e0b18706d61ab76ba7d5f44eca2581c92a"
        cpu: "1"
        memory: "1 GB"
    }
}
