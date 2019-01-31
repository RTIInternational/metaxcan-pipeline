task standardize_input_cols {
    # Standardizes GWAS/Meta-analysis input files to expected format for pipelines
    # Replaces spaces with tabs to ensure tab delimited
    # Re-arranges columns to be in standard order
    # Standardizes column names

    File gxg_meta_analysis_file
    Int id_col
    Int chr_col
    Int pos_col
    Int a1_col
    Int a2_col
    Int beta_col
    Int se_col
    Int pvalue_col
    String output_filename = basename(gxg_meta_analysis_file) + ".standardized.txt"
    String tmp_filename = "unzipped_gxg_file.txt"
    command<<<

        input_file=${gxg_meta_analysis_file}

        # Unzip file if necessary
        if [[ ${gxg_meta_analysis_file} =~ \.gz$ ]]; then
            log_info "${gxg_meta_analysis_file} is gzipped. Unzipping..."
            gunzip -c ${gxg_meta_analysis_file} > ${tmp_filename}
            input_file=${tmp_filename}
        fi

        # Replace spaces with tabs
        sed -i 's/ /\t/g' $input_file

        # Re-arrange colunns
        awk -v OFS="\t" -F"\t" '{print $${id_col},$${chr_col},$${pos_col},$${a1_col},$${a2_col},$${beta_col},$${se_col},$${pvalue_col}}' \
            $input_file \
            > ${output_filename}

        # Standardize column names
        sed -i "1s/.*/MarkerName\tchr\tposition\tA1\tA2\tBETA\tStdErr\tP/" ${output_filename}
    >>>
    output{
        File output_file = "${output_filename}"
    }
    runtime{
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

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

task count_lines {
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

task adj_csv_pvalue{
    File input_file
    String pvalue_colname
    String method
    String output_file_base
    Float? filter_threshold
    Int? num_comparisons
    #String output_file_base = basename(input_file, ".csv")
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

# Cats a set of CSV files (or text files) which have headers
# Includes one copy of header at top of concatentated file and removes header from all other files
task cat_csv {
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

workflow metaxcan_wf {

    # Inputs for preprocessing
    Array[File] gxg_meta_analysis_files
    Int input_id_col
    Int input_chr_col
    Int input_pos_col
    Int input_a1_col
    Int input_a2_col
    Int input_beta_col
    Int input_se_col
    Int input_pvalue_col

    # Inputs for preprocessing
    Array[File] legend_files_1000g
    Array[Int] chrs
    File gtex_variant_file
    String preprocessing_output_base = "processed_metaxcan_input"

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

    Float adj_pvalue_filter_threshold_within_tissue
    Float adj_pvalue_filter_threshold_across_tissue

    # Basename for final output files
    String combined_output_basename = "metaxcan_results_combined"
    String across_tissue_output_basename = "metaxcan_results_across_tissue_${pvalue_adj_method}_${adj_pvalue_filter_threshold_across_tissue}"
    String within_tissue_output_basename = "metaxcan_results_within_tissue_${pvalue_adj_method}_${adj_pvalue_filter_threshold_within_tissue}"

    # Standardize input files in parallel
    scatter (chr_index in range(length(chrs))){
        call standardize_input_cols{
            input:
                gxg_meta_analysis_file = gxg_meta_analysis_files[chr_index],
                id_col = input_id_col,
                chr_col = input_chr_col,
                pos_col = input_pos_col,
                a1_col = input_a1_col,
                a2_col = input_a2_col,
                beta_col = input_beta_col,
                se_col = input_se_col,
                pvalue_col = input_pvalue_col
        }
    }

    # Preprocess metaxcan input in parallel
    scatter (chr_index in range(length(chrs))){
        call preprocess_metaxcan_chr as preprocessing {
            input:
                gxg_meta_analysis_file = standardize_input_cols.output_file[chr_index],
                chr = chrs[chr_index],
                legend_file_1000g = legend_files_1000g[chr_index],
                gtex_variant_file = gtex_variant_file,
                output_base = preprocessing_output_base
        }
    }

    # Run metaxcan in parallel across tissue types
    scatter (model_index in range(length(model_db_files))){
        call metaxcan{
            input:
                model_db_file = model_db_files[model_index],
                covariance_file = covariance_files[model_index],
                gwas_files = preprocessing.metaxcan_ready_output_file,
                snp_column = snp_column,
                effect_allele_column = effect_allele_column,
                non_effect_allele_column = non_effect_allele_column,
                beta_column = beta_column,
                pvalue_column = pvalue_column,
                se_column = se_column
        }
    }

    # Add ID column to end of each metaxcan output so we can combine and still have source file info
    scatter (metaxcan_output in metaxcan.metaxcan_output){
        # Total number of comparisons across all metaxcan output files
        call add_col_to_csv as add_id_col{
            input:
                input_file = metaxcan_output,
                colname = "Source",
                value = basename(metaxcan_output, ".csv")
        }
    }

    # Concatenate all CSVs into one large csv
    call cat_csv{
        input:
            input_files = add_id_col.col_output,
            output_base = combined_output_basename
    }

    # Correct for multiple tests across tissues (more conservative)
    call adj_csv_pvalue as across_tissue_adj_pvalue{
        input:
            input_file = cat_csv.cat_csv_output,
            pvalue_colname = pvalue_colname,
            filter_threshold = adj_pvalue_filter_threshold_across_tissue,
            method = pvalue_adj_method,
            output_file_base = across_tissue_output_basename
    }

    # Correct for multiple tests within tissues (less conservative)
    scatter (metaxcan_output_with_id in add_id_col.col_output){
        call adj_csv_pvalue as within_tissue_adj_pvalue{
            input:
                input_file = metaxcan_output_with_id,
                pvalue_colname = pvalue_colname,
                filter_threshold = adj_pvalue_filter_threshold_within_tissue,
                method = pvalue_adj_method,
                output_file_base = basename(metaxcan_output_with_id, ".csv")
        }
    }

    # Concatenate all within-tissue CSVs into one file
    call cat_csv as gather_within_tissue_csvs {
        input:
            input_files = within_tissue_adj_pvalue.adj_output_file,
            output_base = within_tissue_output_basename
    }

    output{
        Array[File] metaxcan_output = metaxcan.metaxcan_output
        File combined_metaxcan_output = cat_csv.cat_csv_output
        File across_tissue_adj_metaxcan_output = across_tissue_adj_pvalue.adj_output_file
        File within_tissue_adj_metaxcan_output = gather_within_tissue_csvs.cat_csv_output
    }

}