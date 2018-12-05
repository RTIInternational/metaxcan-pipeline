class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com'
id: gzip
baseCommand:
  - gzip -c
inputs:
  - id: gzip_input_file
    type: File
    inputBinding:
      position: 0
outputs:
  - id: gzip_output_file
    type: File
    outputBinding:
      glob: $(runtime.outdir)/$(inputs.gzip_input_file.path).gz
label: gzip
requirements:
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 0
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/gzip:latest'
  - class: InlineJavascriptRequirement
stdout: $(runtime.outdir)/$(inputs.gzip_input_file.path).gz
