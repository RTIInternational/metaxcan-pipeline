task count_lines {
    # Take for running wc -l on a file and getting number of lines
    File input_file
    command {
        cat ${input_file} | wc -l
    }
    output{
        # Count number of records by subtracting out header line for each file
        Int num_lines = read_int(stdout())
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

task add_col_to_csv {
    # Utility method to append a column to a CSV file with a single colname and value
    # Makes most sense in conjunction with cat_csv so that you can add a file-specific annotation to each CSV before cat
    # To track the source of records in the concatenated CSV
    File input_file
    String colname
    String value
    String output_file_base = basename(input_file, ".csv")
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
    # Cats a set of CSV files (or text files) which have headers
    # Includes one copy of header at top of concatentated file and removes header from all other files
    Array[File] input_files
    File output_base
    File output_file = output_base + ".csv"
    command {
        rm -rf ./csv_inputs
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
