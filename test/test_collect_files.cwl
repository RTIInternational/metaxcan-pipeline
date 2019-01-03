class: Workflow
cwlVersion: v1.0
id: test_collect_files
label: test_collect_files
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
inputs:
  - id: input_files
    type: 'File[]'
    'sbg:x': -435
    'sbg:y': -147
  - id: output_dir_name
    type: string
    'sbg:x': -74
    'sbg:y': -9
outputs:
  - id: output_dir
    outputSource:
      - pack_files/output_dir
    type: Directory
    'sbg:x': 256
    'sbg:y': -128
steps:
  - id: pack_files
    in:
      - id: input_files
        source:
          - input_files
      - id: dir_name
        source: output_dir_name
    out:
      - id: output_dir
    run: ../tools/pack_files.cwl
    label: pack_files
    'sbg:x': -196.796875
    'sbg:y': -148
requirements: []
