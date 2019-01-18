class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
baseCommand:
  - wc
  - '-l'
inputs:
  - id: file1
    type: File
    inputBinding:
      position: 0
outputs:
  - id: output_file
    type: File
    outputBinding:
      glob: output.txt
stdout: output.txt
