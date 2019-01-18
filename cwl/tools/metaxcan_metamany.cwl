class: CommandLineTool
cwlVersion: v1.0
$namespaces:
  sbg: 'https://www.sevenbridges.com/'
id: metaxcan_metamany
baseCommand:
  - MetaMany.py
inputs:
  - id: transcriptome_model
    type: Directory
    inputBinding:
      position: 1
      prefix: '--model_db_path'
    doc: Path to tissue transcriptome model
  - id: covariance_data
    type: File
    inputBinding:
      position: 2
      prefix: '--covariance'
    doc: >-
      Path to file containing covariance information. This covariance should
      have information related to the tissue transcriptome model.
  - id: gwas_folder
    type: Directory
    inputBinding:
      position: 3
      prefix: '--gwas_folder'
    doc: Folder containing GWAS summary statistics data.
  - id: gwas_file_pattern
    type: string
    inputBinding:
      position: 4
      prefix: '--gwas_file_pattern'
    doc: >-
      This option allows the program to select which files from the input to use
      based on their name. This allows to ignore several support files that
      might be generated at your GWAS analysis, such as plink logs.
  - id: snp_column
    type: string
    inputBinding:
      position: 5
      prefix: '--snp_column'
    doc: >-
      Argument with the name of the column containing the RSIDs for files in the
      gwas folder.
  - id: effect_allele_column
    type: string
    inputBinding:
      position: 6
      prefix: '--effect_allele_column'
    doc: >-
      Argument with the name of the column containing the effect allele (i.e.
      the one being regressed on) for input files in gwas folder.
  - id: non_effect_allele_column
    type: string
    inputBinding:
      position: 7
      prefix: '--non_effect_allele_column'
    doc: >-
      Argument with the name of the column containing the non effect allele in
      the gwas file in gwas_folder.
  - id: beta_column
    type: string
    inputBinding:
      position: 8
      prefix: '--beta_column'
    doc: >-
      Tells the program the name of a column containing -phenotype beta data for
      each SNP- in the input GWAS files.
  - id: pvalue_column
    type: string
    inputBinding:
      position: 9
      prefix: '--pvalue_column'
    doc: >-
      Tells the program the name of a column containing -PValue for each SNP- in
      the input GWAS files.
  - id: covariance_glob
    type: string
    inputBinding:
      position: 11
outputs:
  - id: metamany_results
    doc: Path where metamany results will be saved
    type: 'File[]'
    outputBinding:
      glob: $(runtime.outdir)/metamany_results/*
    'sbg:fileTypes': csv
doc: Wrapper for running MetaXcan MetaMany.py for integrative gene mapping studies.
label: metaxcan_metamany
arguments:
  - position: 10
    prefix: '--output_directory'
    valueFrom: $(runtime.outdir)/metamany_results
requirements:
  - class: DockerRequirement
    dockerPull: 'alexwaldrop/metaxcan:7b233d7c784026dd3f4fae5189c95c0427ccd1d6'
  - class: InlineJavascriptRequirement
'sbg:links':
  - id: 'https://github.com/hakyimlab/MetaXcan'
    label: MetaXcan git repo
'sbg:wrapperAuthor': Alex Waldrop
