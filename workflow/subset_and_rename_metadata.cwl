class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: subset_and_rename_metadata
baseCommand:
  - bash bin/subset_and_rename_metadata_cols.sh
inputs:
  - id: metadata_input_file
    type: File
    inputBinding:
      position: 0
  - id: subset_cols
    type: 'int[]?'
    inputBinding:
      position: 1
      itemSeparator: ' '
outputs:
  - id: subset_metadata_file
    type: File?
    outputBinding:
      glob: subset_metadata.txt
label: subset_and_rename_metadata
requirements:
  - class: ResourceRequirement
    ramMin: 100
    coresMin: 1
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/metaxcan:latest'
stdout: subset_metadata.txt
