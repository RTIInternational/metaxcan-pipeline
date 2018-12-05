class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: convert_to_1000g_ids
baseCommand:
  - perl src/convert_to_1000g_p3_ids.pl
inputs:
  - id: input_file_to_convert
    type: File
    inputBinding:
      position: 0
      prefix: '--file_in'
  - id: legend_file
    type: File
    inputBinding:
      position: 2
      prefix: '--legend'
  - id: file_in_header
    type: int
    inputBinding:
      position: 3
      prefix: '--file_in_header'
  - id: file_in_id_col
    type: int
    inputBinding:
      position: 4
      prefix: '--file_in_id_col'
  - id: file_in_chr_col
    type: int
    inputBinding:
      position: 5
      prefix: '--file_in_chr_col'
  - id: file_in_pos_col
    type: int
    inputBinding:
      position: 6
      prefix: '--file_in_pos_col'
  - id: file_in_a1_col
    type: int
    inputBinding:
      position: 7
      prefix: '--file_in_a1_col'
  - id: file_in_a2_col
    type: int
    inputBinding:
      position: 8
      prefix: '--file_in_a2_col'
  - id: chr
    type: int
    inputBinding:
      position: 9
      prefix: '--chr'
outputs:
  - id: converted_id_out_file
    type: File
    outputBinding:
      glob: converted_id_out_file.txt
label: convert_to_1000g_ids
arguments:
  - position: 1
    prefix: '--file_out'
    valueFrom: converted_id_out_file.txt
requirements:
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 0
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/metaxcan:latest'
