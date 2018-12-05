class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: extract_rows
baseCommand:
  - perl src/extract_rows.pl
inputs:
  - id: source_input_file
    type: File
    inputBinding:
      position: 0
      prefix: '--source'
  - id: id_list_file
    type: File
    inputBinding:
      position: 1
      prefix: '--id_list'
  - id: header_row
    type: int
    inputBinding:
      position: 3
      prefix: '--header'
  - id: id_col
    type: int
    inputBinding:
      position: 4
      prefix: '--id_column'
outputs:
  - id: extract_rows_output_file
    type: File
    outputBinding:
      glob: extract_rows_output.txt
label: extract_rows
arguments:
  - position: 2
    prefix: '--out'
    valueFrom: extract_rows_output.txt
requirements:
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 0
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/metaxcan:latest'
