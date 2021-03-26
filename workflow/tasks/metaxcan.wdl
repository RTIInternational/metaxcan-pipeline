task metaxcan {
    # Task for running S-PrediXcan on a single tissue expression database
    File model_db_file
    File covariance_file
    Array[File] gwas_files
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String pvalue_column
    String se_column

    # One of these needs to set
    String? zscore_column
    String? beta_column

    # Optionally specify snp id column in model file
    String? model_db_snp_key

    # Boolean for whether to keep non_rsid snps (should be true for gtex_v8, unnecessary for gtex_v7)
    Boolean keep_non_rsid = true

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
            --pvalue_column ${pvalue_column} \
            --effect_allele_column ${effect_allele_column} \
            --non_effect_allele_column ${non_effect_allele_column} \
            --snp_column ${snp_column} \
            --se_column ${se_column} \
            ${'--zscore_column ' + zscore_column} \
            ${'--beta_column ' + beta_column} \
            ${'--model_db_snp_key ' + model_db_snp_key} \
            ${true='--keep_non_rsid' false='' keep_non_rsid} \
            --additional_output \
            --throw \
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

task metamany {
    # Task for running MetaMany, which runs S-PrediXcan in serial on multiple tissue databases
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

task smultixcan {
    # Task for running S-MultiXcan across multiple tissue expression databases
    Array[File] model_db_files
    Array[File] metaxcan_output_files
    Array[File] gwas_files
    File covariance_file
    String model_name_pattern
    String metaxcan_file_name_parse_pattern
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String pvalue_column
    String se_column
    String output_base
    Float cutoff_threshold

    String? beta_column
    String? zscore_column

    String? model_db_snp_key
    Boolean keep_non_rsid = true

    String output_file = output_base + ".smultixcan_results.csv"

    command {

        mkdir ./metaxcan_dir
        cp -r ${sep=' ./metaxcan_dir ; cp -r ' metaxcan_output_files} ./metaxcan_dir
        ls -l ./metaxcan_dir

        mkdir ./model_dir
        cp -r ${sep=' ./model_dir ; cp -r ' model_db_files} ./model_dir
        ls -l ./model_dir

        mkdir ./gwas_dir
        cp -r ${sep=' ./gwas_dir ; cp -r ' gwas_files} ./gwas_dir
        ls -l ./gwas_dir

        source activate metaxcan

        /opt/code_docker_lib/MetaXcan/software/SMulTiXcan.py \
            --models_folder ./model_dir \
            --snp_covariance ${covariance_file} \
            --metaxcan_folder ./metaxcan_dir \
            --gwas_folder ./gwas_dir \
            --pvalue_column ${pvalue_column} \
            --effect_allele_column ${effect_allele_column} \
            --non_effect_allele_column ${non_effect_allele_column} \
            --snp_column ${snp_column} \
            --se_column ${se_column} \
            ${'--zscore_column ' + zscore_column} \
            ${'--beta_column ' + beta_column} \
            ${'--model_db_snp_key ' + model_db_snp_key} \
            ${true='--keep_non_rsid' false='' keep_non_rsid} \
            --additional_output \
            --throw \
            --verbosity 1 \
            --output ${output_file} \
            --models_name_pattern "${model_name_pattern}" \
            --metaxcan_file_name_parse_pattern "${metaxcan_file_name_parse_pattern}" \
            --cutoff_threshold ${cutoff_threshold}

    }
    output {
        File smultixcan_output = output_file
    }
    runtime {
        docker: "alexwaldrop/metaxcan:75065864afcec43181f17ef00c8518a2d29fe8a7"
        cpu: "8"
        memory: "32 GB"
  }
}
