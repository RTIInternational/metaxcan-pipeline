task preprocess_metaxcan_chr {
    File gxg_meta_analysis_file
    File gtex_variant_file
    File legend_file_1000g
    Int chr
    String output_base

    command {
        /opt/code_docker_lib/prepare_metaxcan_input.sh ${gxg_meta_analysis_file} ${gtex_variant_file} ${legend_file_1000g} ${chr} ${output_base} ./
    }
    output {
        File metaxcan_ready_output_file = "${output_base}.txt.gz"
    }
    runtime {
        docker: "alexwaldrop/prepare_metaxcan_input:f79df01672944c44581d356968f0f21fc6a445f6"
        cpu: "2"
        memory: "8 GB"
  }
}

workflow test_pmc{
    call preprocess_metaxcan_chr
}