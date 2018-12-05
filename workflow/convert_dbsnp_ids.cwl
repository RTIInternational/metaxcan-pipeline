class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: convert_dbsnp_ids
baseCommand:
  - Rscript src/convert_dbsnp_ids.R
inputs:
  - id: metadata_input_file
    type: File
    inputBinding:
      position: 0
  - id: gtex_input_file
    type: File
    inputBinding:
      position: 1
      prefix: ''
outputs:
  - id: matched_metadata_output_file
    type: File
    outputBinding:
      glob: matched_metadata.txt
label: convert_dbsnp_ids
arguments:
  - position: 2
    prefix: ''
    valueFrom: matched_metadata.txt
requirements:
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 0
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/metaxcan:latest'
