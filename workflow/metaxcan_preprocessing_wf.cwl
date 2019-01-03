class: Workflow
cwlVersion: v1.0
id: metaxcan_preprocessing_wf
label: metaxcan_preprocessing_wf
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
inputs:
  - id: gxg_meta_analysis_file
    type: 'File[]'
    'sbg:x': 148.40625
    'sbg:y': 107
  - id: legend_file_1000g
    type: 'File[]'
    'sbg:x': 148.40625
    'sbg:y': 0
  - id: gtex_variant_file
    type: File
    'sbg:x': 148.40625
    'sbg:y': 214
  - id: chr
    type: 'int[]'
    'sbg:x': -96.25540924072266
    'sbg:y': 412.36492919921875
  - id: output_base
    type: string
    'sbg:x': -107.71438598632812
    'sbg:y': 309.9485168457031
outputs:
  - id: metaxcan_ready_output_dir
    outputSource:
      - collect_files/output_dir
    type: Directory
    'sbg:x': 944.2196655273438
    'sbg:y': 113.44385528564453
steps:
  - id: generate_output_basenames
    in:
      - id: output_base
        source: output_base
      - id: chr
        source:
          - chr
    out:
      - id: output_basenames
    run:
      class: ExpressionTool
      cwlVersion: v1.0
      expression: |
        ${
            var ret = [];
            for (var i = 0; i < inputs.chr.length; ++i) {
                ret.push(inputs.output_base+".chr"+inputs.chr[i]);
            }
            return { 'output_basenames' : ret }
        }
      inputs:
        - id: output_base
          type: string
        - id: chr
          type: 'int[]'
      outputs:
        - id: output_basenames
          type: 'string[]'
    'sbg:x': 162.89666748046875
    'sbg:y': 391.0243835449219
  - id: preprocess_metaxcan
    in:
      - id: gxg_meta_analysis_file
        source: gxg_meta_analysis_file
      - id: gtex_variant_file
        source: gtex_variant_file
      - id: legend_file_1000g
        source: legend_file_1000g
      - id: chr
        source: chr
      - id: output_base
        source: generate_output_basenames/output_basenames
    out:
      - id: metaxcan_ready_output_file
    run: ../tools/preprocess_metaxcan_chr.cwl
    label: preprocess_metaxcan
    scatter:
      - gxg_meta_analysis_file
      - legend_file_1000g
      - chr
      - output_base
    scatterMethod: dotproduct
    'sbg:x': 416.7296447753906
    'sbg:y': 139.5
  - id: collect_files
    in:
      - id: dir_name
        valueFrom: processed_metaxcan_input
      - id: input_files
        source:
          - preprocess_metaxcan/metaxcan_ready_output_file
    out:
      - id: output_dir
    run: ../tools/collect_files.cwl
    label: collect_files
    'sbg:x': 662.3556518554688
    'sbg:y': 139.22177124023438
requirements:
  - class: ScatterFeatureRequirement
  - class: InlineJavascriptRequirement
