

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

task metamany {
    Array[File] model_db_files
    Array[String] model_db_glob_patterns
    Array[File] covariance_files
    Array[File] gwas_files
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String beta_column
    String pvalue_column
    String se_column
    String output_directory = "metamany_output"

    command {

        mkdir ./cov_dir
        cp -r ${sep=' ./cov_dir ; cp -r ' covariance_files} ./cov_dir
        ls -l ./cov_dir

        mkdir ./model_dir
        cp -r ${sep=' ./model_dir ; cp -r ' model_db_files} ./model_dir
        ls -l ./model_dir

        mkdir ./gwas_dir
        cp -r ${sep=' ./gwas_dir ; cp -r ' gwas_files} ./gwas_dir
        ls -l ./gwas_dir

        mkdir ${output_directory}

        source activate metaxcan

        /opt/code_docker_lib/MetaXcan/software/MetaMany.py \
            --gwas_folder ./gwas_dir \
            --beta_column ${beta_column} \
            --pvalue_column ${pvalue_column} \
            --effect_allele_column ${effect_allele_column} \
            --non_effect_allele_column ${non_effect_allele_column} \
            --snp_column ${snp_column} \
            --se_column ${se_column} \
            --covariance_directory ./cov_dir \
            --output_directory ${output_directory} \
            ./model_dir/${sep=' ./model_dir/' model_db_glob_patterns}

    }
    output {
        Array[File] metamany_output = glob("${output_directory}/*")
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
        Int num_results = read_int(stdout()) - length(input_files)
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
    }
}

workflow metaxcan_metamany_wf {

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

    # Run metaxcan across all tisse types using metamany
    call metamany{
        input:
            model_db_files = model_db_files,
            model_db_glob_patterns = model_db_glob_patterns,
            covariance_files = covariance_files,
            gwas_files = preprocessing.metaxcan_ready_output_file,
            snp_column = snp_column,
            effect_allele_column = effect_allele_column,
            non_effect_allele_column = non_effect_allele_column,
            beta_column = beta_column,
            pvalue_column = pvalue_column,
            se_column = se_column
    }

    # Count number of results for p-value adjusting
    call count_results{
        input:
            input_files = metamany.metamany_output
    }

    output{
        Array[File] metamany_output = metamany.metamany_output
        Int num_results = count_results.num_results
    }

}