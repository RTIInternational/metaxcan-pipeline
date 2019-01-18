class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: preprocess_metaxcan_chr
baseCommand: []
inputs:
  - id: gxg_meta_analysis_file
    type: File
    inputBinding:
      position: 0
  - id: gtex_variant_file
    type: File
    inputBinding:
      position: 1
  - id: legend_file_1000g
    type: File
    inputBinding:
      position: 2
  - id: chr
    type: int
    inputBinding:
      position: 3
  - id: output_base
    type: string
    inputBinding:
      position: 4
outputs:
  - id: metaxcan_ready_output_file
    type: File
    outputBinding:
      glob: '*$(inputs.output_base).txt.gz'
label: preprocess_metaxcan_chr
arguments:
  - position: 5
    valueFrom: $(runtime.outdir)
requirements:
  - class: DockerRequirement
    dockerPull: >-
      alexwaldrop/prepare_metaxcan_input:f79df01672944c44581d356968f0f21fc6a445f6
  - class: InlineJavascriptRequirement
