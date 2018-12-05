class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: get_unique_gtex_variants
baseCommand:
  - bash bin/get_unique_gtex_variants.sh
inputs:
  - id: gtex_input_file
    type: File
    inputBinding:
      position: 0
outputs:
  - id: unique_gtex_variants
    type: File?
    outputBinding:
      glob: unique_gtex_variants.txt
label: get_unique_gtex_variants
requirements:
  - class: ResourceRequirement
    ramMin: 100
    coresMin: 1
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/metaxcan:latest'
stdout: unique_gtex_variants.txt
