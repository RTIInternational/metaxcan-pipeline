# import "wdl/preprocess_metaxcan_chr.wdl" as preprocess_meta

task preprocess_metaxcan_chr {
    File gxg_meta_analysis_file
    File gtex_variant_file
    File legend_file_1000g
    Int chr
    String output_base
    String final_output_base = "${output_base}.${chr}"

    command {
        /opt/code_docker_lib/prepare_metaxcan_input.sh ${gxg_meta_analysis_file} ${gtex_variant_file} ${legend_file_1000g} ${chr} ${final_output_base} ./
    }
    output {
        File metaxcan_ready_output_file = "${final_output_base}.txt.gz"
    }
    runtime {
        docker: "alexwaldrop/prepare_metaxcan_input:39673a1fde1b6485392202b243b66ecb1a0e9828"
        cpu: "2"
        memory: "8 GB"
  }
}

task metaxcan {
    File model_db_file
    File covariance_file
    Array[File] gwas_files
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String beta_column
    String pvalue_column
    String se_column
    String output_base = basename(model_db_file, ".db")
    String output_file = output_base + ".metaxcan_results.csv"

    command {

        mkdir ./gwas_dir
        cp -r ${sep=' ./gwas_dir ; cp -r ' gwas_files} ./gwas_dir
        ls -l ./gwas_dir

        source activate metaxcan

        /opt/code_docker_lib/MetaXcan/software/MetaXcan.py \
            --model_db_path ${model_db_file} \
            --covariance ${covariance_file} \
            --gwas_folder ./gwas_dir \
            --beta_column ${beta_column} \
            --pvalue_column ${pvalue_column} \
            --effect_allele_column ${effect_allele_column} \
            --non_effect_allele_column ${non_effect_allele_column} \
            --snp_column ${snp_column} \
            --se_column ${se_column} \
            --output_file ${output_file}

    }
    output {
        File metaxcan_output = output_file
    }
    runtime {
        docker: "alexwaldrop/metaxcan:75065864afcec43181f17ef00c8518a2d29fe8a7"
        cpu: "6"
        memory: "16 GB"
  }
}

task count_results {
    Array[File] input_files
    command {
        cat ${sep=' ' input_files} | wc -l
    }
    output{
        # Count number of records by subtracting out header line for each file
        Int num_results = read_int(stdout())
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

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

workflow metaxcan_wf {

    # Inputs for preprocessing
    Array[File] gxg_meta_analysis_files
    Array[File] legend_files_1000g
    Array[Int] chrs
    File gtex_variant_file
    String output_base = "processed_metaxcan_input"

    # Inputs for metamany
    Array[File] model_db_files
    Array[String] model_db_glob_patterns
    Array[File] covariance_files
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String beta_column
    String pvalue_column
    String se_column

    # Inputs for p-value adjusting
    String pvalue_adj_method
    String pvalue_colname = "pvalue"
    Float adj_pvalue_filter_threshold

    # Basename for final output file
    String final_output_basename = "metaxcan_results_${pvalue_adj_method}_${adj_pvalue_filter_threshold}"

    # Scatter parallel processing by chromosome
    scatter (chr_index in range(length(chrs))){

        File gxg_meta_analysis_file = gxg_meta_analysis_files[chr_index]
        Int chr = chrs[chr_index]
        File legend_file_1000g = legend_files_1000g[chr_index]

        call preprocess_metaxcan_chr as preprocessing {
            input:
                gxg_meta_analysis_file = gxg_meta_analysis_files[chr_index],
                chr = chrs[chr_index],
                legend_file_1000g = legend_files_1000g[chr_index],
                gtex_variant_file = gtex_variant_file,
                output_base = output_base
        }

    }

    # Scatter parallel processing by tissue type
    scatter (model_index in range(length(model_db_files))){

        File model_db_file = model_db_files[model_index]
        File covariance_file = covariance_files[model_index]

        call metaxcan{
            input:
                model_db_file = model_db_file,
                covariance_file = covariance_file,
                gwas_files = preprocessing.metaxcan_ready_output_file,
                snp_column = snp_column,
                effect_allele_column = effect_allele_column,
                non_effect_allele_column = non_effect_allele_column,
                beta_column = beta_column,
                pvalue_column = pvalue_column,
                se_column = se_column
        }
    }

    # Count number Gene/Tissue pvalues across metaxcan results for adjusting pvalues
    call count_results{
        input:
            input_files = metaxcan.metaxcan_output
    }

    # Adjust metaxcan results pvalues for multiple comparisons and filter out results above threshold
    scatter (metaxcan_output in metaxcan.metaxcan_output){
        # Total number of comparisons across all metaxcan output files
        Int num_comparisons = count_results.num_results - length(model_db_files)
        call adj_csv_pvalue{
            input:
                input_file = metaxcan_output,
                pvalue_colname = pvalue_colname,
                num_comparisons = num_comparisons,
                filter_threshold = adj_pvalue_filter_threshold,
                method = pvalue_adj_method
        }

    }

    # Add column to end of each CSV file to show original source file after concatentation
    scatter (adj_csv_file in adj_csv_pvalue.adj_output_file){
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
        Array[File] metaxcan_output = metaxcan.metaxcan_output
        Int num_results = count_results.num_results
        Array[File] adj_metaxcan_output = adj_csv_pvalue.adj_output_file
        File concat_output = cat_csv.cat_csv_output
    }

}