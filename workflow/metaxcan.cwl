class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: metaxcan
baseCommand:
  - MetaMany.py
inputs:
  - id: gwas_folder
    type: Directory
    inputBinding:
      position: 0
      prefix: '--gwas_folder'
  - id: gwas_file_pattern
    type: string
    inputBinding:
      position: 1
      prefix: '--gwas_file_pattern'
  - id: beta_column
    type: string
    inputBinding:
      position: 2
      prefix: '--beta_column'
  - id: pvalue_column
    type: string
    inputBinding:
      position: 3
      prefix: '--pvalue_column'
  - id: covariance_directory
    type: Directory
    inputBinding:
      position: 4
      prefix: '--covariance_directory'
  - id: predict_db_files
    type:
      - File
      - type: array
        items: File
    inputBinding:
      position: 6
      prefix: ''
outputs:
  - id: metaxcan_output_directory
    type: Directory
    outputBinding:
      glob: metaxcan_results
label: metaxcan
arguments:
  - position: 5
    prefix: '--output_directory'
    valueFrom: metaxcan_results
requirements:
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 0
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/gzip:latest'
