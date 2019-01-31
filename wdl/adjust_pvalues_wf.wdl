task adj_csv_pvalue{
    File input_file
    String pvalue_colname
    String method
    Float? filter_threshold
    Int? num_comparisons
    String output_file_base = basename(input_file, ".csv")
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

task add_col_to_csv {
    File input_file
    String colname
    String value
    File output_file_base = basename(input_file, ".csv")
    File output_file = "${output_file_base}.col_added.csv"
    command <<<
        awk -F"," 'BEGIN {OFS = ","} FNR==1{$(NF+1)=${colname}} FNR>1{$(NF+1)="${value}";} 1' ${input_file} > ${output_file}
    >>>
    output{
        File col_output = "${output_file}"
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

task cat_csv {
    Array[File] input_files
    File output_base
    File output_file = output_base + ".csv"
    command {

        mkdir ./csv_inputs
        cp -r ${sep=' ./csv_inputs ; cp -r ' input_files} ./csv_inputs
        awk '(NR == 1) || (FNR > 1)' ./csv_inputs/* > ${output_file}
    }
    output{
        File cat_csv_output = "${output_file}"
    }

    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

workflow adj_csv_pvalue_wf{

    Array[File] input_files
    String pvalue_colname
    Float adj_pvalue_filter_threshold
    String final_output_basename
    String pvalue_adj_method
    Int? num_comparisons

    # Adjust pvalues for multiple test corrections in each file
    scatter (input_file in input_files ){
        call adj_csv_pvalue{
            input:
                input_file = input_file,
                pvalue_colname = pvalue_colname,
                filter_threshold = adj_pvalue_filter_threshold,
                method = pvalue_adj_method,
                num_comparisons = num_comparisons
        }
    }

    # Add column to end of each CSV file to show original source file after concatentation
    scatter ( adj_csv_file in adj_csv_pvalue.adj_output_file){
        call add_col_to_csv as add_id_col{
            input:
                input_file = adj_csv_file,
                colname = "Source",
                value = basename(adj_csv_file, ".csv")
        }
    }

    # Concatenate all CSVs into one large csv
    call cat_csv{
        input:
            input_files = add_id_col.col_output,
            output_base = final_output_basename
    }

    output{
        Array[File] adj_metaxcan_output = adj_csv_pvalue.adj_output_file
        File concat_output = cat_csv.cat_csv_output
    }
}