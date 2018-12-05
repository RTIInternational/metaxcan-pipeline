class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: subset_gtex_by_chrom
baseCommand:
  - bash bin/split_gtex_by_chr.sh
inputs:
  - id: gtex_input_file
    type: File
    inputBinding:
      position: 0
  - id: chr
    type: int?
    inputBinding:
      position: 1
outputs:
  - id: gtex_output_file
    type: File
    outputBinding:
      glob: gtex_chr_subset_output.txt
label: subset_gtex_by_chrom
requirements:
  - class: ResourceRequirement
    ramMin: 100
    coresMin: 1
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/metaxcan:latest'
stdout: ' gtex_chr_subset_output.txt'
