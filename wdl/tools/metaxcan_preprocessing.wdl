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
    # Takes standardized GWAS/Meta-analysis output (gxg_meta_analysis_file) and produces a metaxcan-ready input file
    # Converts to 1000g standard ids, subsets to include only SNPs in the gtex_variant_file, annotates input SNPs with additional information needed for metaXcan
    # Processing is meant to be for a single chromosome so that processing can be scattered and performed in parallel at workflow level
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
