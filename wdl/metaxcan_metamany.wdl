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
        cp ${sep=' ./cov_dir cp ' covariance_files} ./cov_dir
        ls -l ./cov_dir

        mkdir ./model_dir
        cp ${sep=' ./model_dir cp ' model_db_files} ./model_dir
        ls -l ./model_dir

        mkdir ./gwas_dir
        cp ${sep=' ./gwas_dir cp ' gwas_files} ./gwas_dir
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

workflow test_mm{
    call metamany
}
