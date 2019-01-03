class: Workflow
cwlVersion: v1.0
id: test_preprocess_metaxcan_chr_wf
label: test_preprocess_metaxcan_chr_wf
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
inputs:
  - id: gxg_meta_analysis_file
    type: File
    #'sbg:exposed': true
  - id: legend_file_1000g
    type: File
    #'sbg:exposed': true
  - id: gtex_variant_file
    type: File
    #'sbg:exposed': true
  - id: chr
    type: int
    #'sbg:exposed': true
  - id: output_base
    type: string
    #'sbg:exposed': true
outputs:
  - id: metaxcan_ready_output_file
    outputSource:
      - preprocess_metaxcan/metaxcan_ready_output_file
    type: File
steps:
  - id: preprocess_metaxcan
    in:
      - id: gxg_meta_analysis_file
        source: gxg_meta_analysis_file
      - id: legend_file_1000g
        source: legend_file_1000g
      - id: gtex_variant_file
        source: gtex_variant_file
      - id: chr
        source: chr
      - id: output_base
        source: output_base
    out:
      - id: metaxcan_ready_output_file
    run: ../tools/preprocess_metaxcan_chr.cwl
    label: preprocess_metaxcan
    'sbg:x': -286
    'sbg:y': -186
requirements: []
