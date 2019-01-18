class: Workflow
cwlVersion: v1.0
id: metaxcan_metamany_workflow
label: metaxcan_metamany_workflow
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
inputs: []
outputs: []
steps:
  - id: metaxcan_metamany
    in:
      - id: gwas_folder
        source: preprocess_metaxcan/metaxcan_ready_output_file
    out:
      - id: metamany_results
    run: ../tools/metaxcan_metamany.cwl
    label: metaxcan_metamany
    'sbg:x': -193
    'sbg:y': -185
  - id: preprocess_metaxcan
    in: []
    out:
      - id: metaxcan_ready_output_file
    run: ../tools/preprocess_metaxcan.cwl
    label: preprocess_metaxcan
    scatter:
      - output_prefix
    scatterMethod: dotproduct
    'sbg:x': -559.3988647460938
    'sbg:y': -182.5
requirements:
  - class: ScatterFeatureRequirement
