# Utility method to append a column to a CSV file with a single colname and value
# Makes most sense in conjunction with cat_csv so that you can add a file-specific annotation to each CSV before cat
# To track the source of records in the concatenated CSV
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

# Cats a set of CSV files (or text files) which have headers
# Includes one copy of header at top of concatentated file and removes header from all other files
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