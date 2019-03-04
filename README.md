# Metaxcan Pipeline Worklfow 
 Documentation for running [MetaXcan](https://github.com/hakyimlab/MetaXcan/tree/master/software) and [MulTiXcan](https://github.com/hakyimlab/MetaXcan/tree/master/software) on AWS using [WDL+Cromwell](https://software.broadinstitute.org/wdl/)

### Intended audience
This documentation is designed to guide a researcher through the steps necessary to 
run either S-PrediXcan or S-MulTiXcan on their dataset using the AWS cloud computing platform. It is intended more as a users guide than a developers guide.

## Workflow overview
MetaXcan is a suite of tools designed to integrate results from traditional GWAS/Meta-analyses with 
imputed expression data to provide mechanistic evidence for a relationship between genomic variants, 
gene expression patterns, and a phenotype of interest. 
For more information see the [original MetaXcan publication](https://www.nature.com/articles/s41467-018-03621-1) 

This document describes an automated workflow implemented in WDL designed to perform three high-level steps:
    
   1) Transform summary-statistics from GWAS/Meta-analysis into MetaXcan-formatted input
   2) Run MetaXcan's S-PrediXcan to identify relationships between genomic variants, gene expression patterns in specific tissues, and a phenotype
   3) Correct MetaXcan gene p-values for multiple comparisons and filter out significant hits 

Additionally, the S-MulTiXcan workflow goes a step further to identify multi-tissue
associations between gene expression and genomic variants. 

Full documentation of the MetaXcan suite including S-PrediXcan and S-MulTiXcan can be found [here](https://github.com/hakyimlab/MetaXcan/tree/master/software)

### Metaxcan S-PrediXcan workflow overview
<div align=center><img src="doc/metaxcan_pipeline.png" alt="S-PrediXcan Workflow" width=781 height=900 align="middle"/></div>

### S-MulTiXcan workflow overview
Runs S-PrediXcan workflow but also run S-MultiXcan as a final step to look for genes significant across all tissues. 
<div align=center><img src="doc/multixcan_pipeline.png" alt="S-MulTiXcan Workflow" width=533 height=615 align="middle"/></div>

### Workflow implementation
The workflows contained in this repo are implemented in the [Workflow Development Language (WDL)](https://software.broadinstitute.org/wdl/). 
As such, all workflows are platform and file-system independent meaning they can be run locally on your own computer,
on major cloud platforms such AWS and GCP, or on an on-prem High-Performance Computing Cluster (HPCC). 
Tools contained in the workflows are fully containerized, meaning a user doesn't need to install any dependencies (e.g. MetaXcan) other than [docker](https://www.docker.com/). 
Additionally, it is intended to be executed using the WDL-specific workflow engine called [Cromwell](https://github.com/broadinstitute/cromwell)

For the purpose of this document, we will focus on how to run the pipeline in the [AWS](https://aws.amazon.com/) environment using Cromwell.  

## Setting up your system

### Pre-requisites 
   * Unix-based operating system (Linux or OSx. Sorry Windows folks.)
   * Java v1.8 and higher [(download here)](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
   * [Docker](https://docs.docker.com/install/)
   * [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
   
   1. Install [Cromwell](https://cromwell.readthedocs.io/en/stable/tutorials/FiveMinuteIntro/) if you haven't already
   
   2. [Configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) for use with CODE AWS group. 
        * Configure with the secret key associated with the CODE AWS account 
   
   3. Clone local copy of metaxcan-pipeline to download this repository to your local maching
        
        ```
        git clone https://github.com/RTIInternational/metaxcan-pipeline.git    
        ```
   4. Download the [Cromwell AWS config file](https://s3.amazonaws.com/rti-cromwell-output/cromwell-config/cromwell_default_genomics_queue.conf) needed to run the workflow on CODE's AWS DefaultGenomicsQueue. 
        * Keep this handy. It might be best to put the queue file in the repo you download. 
        * File location: *s3://rti-cromwell-output/cromwell-config/cromwell_default_genomics_queue.conf*
    
        ```bash
        # Change into workflow repo dir
        cd metaxcan-pipeline
  
        # Make var directory (gitignore specifically ignores var folders) 
        mkdir var
  
        # Copy config to var directory 
        cp ~/Downloads/cromwell_default_genomics_queue.conf ./var

        ``` 
   Voila! You're ready to get started running the pipeline.
    
## Running a workflow

For a detailed tutorial of running WDL/Cromwell on AWS batch, [check this link](https://cromwell.readthedocs.io/en/develop/tutorials/AwsBatch101/). 

**Workflow WDL files** - Defines required input types and the workflow steps to execute. These don't change.:
   * Metaxcan workflow: **workflow/s-prediXcan_wf.wdl**
   * Multixcan workflow: **workflow/s-mulTiXcan_wf.wdl**
    
**WDL input file templates** -Defines analysis-specific input files/value for running the worflow on your data. Modify these to suite your specific analysis (discucsed below):
   * MetaXcan example input template: **json_input/s-prediXcan_wf_example_input.json**
   * MultiXcan example input template: **json_input/s-mulTiXcan_wf_example_input.json**

### Run a workflow on AWS via your local machine

1. Make a zipped-up copy of the metaxcan-pipeline repo. This is how WDL handles imports. 
    ```
    # Change to directory immediately above metaxcan-pipeline repo
    cd metaxcan-pipeline
    cd ..
    # Make zipped copy of repo somewhere
    zip --exclude=*var/* --exclude=*.git/* -r ~/Desktop/metaxcan-pipeline.zip metaxcan-pipeline
    
    ```
2. Run using cromwell

```
# Navigate to cromwell directory
cd ~/cromwell
java -Dconfig.file=/full/path/to/metaxcan-pipeline/var/cromwell_default_genomics_queue.conf -jar cromwell-36.jar \
    run /path/to/metaxcan-pipeline/workflow/s-mulTiXcan_test_wf.wdl \
    -i ~/PycharmProjects/metaxcan-pipeline/json_input/s-mulTiXcan_test_wf_example_input.json \
    -p ~/Desktop/metaxcan-pipeline.zip
```
    Notes:
        * Make sure the Dconfig.file points to the config you downloaded from S3 above. This tells Cromwell to run the pipeine on AWS instead of your maching.
        * -i should point to your input json file
        * -p should point to the zipped metaxcan-pipeline repo you created

And you're running! Make sure to monitor the status of the job as it runs. 

### Run a workflow on AWS via CODE's AWS Cromwell-Server

If you have a long-running job or intermittent internet connection, you may want to submit the job to CODE's cromwell server. 
This will run the job through a persistent EC2 instance that runs cromwell in server mode.

1. Check the list of EC2 instances for an EC2 instance called 'cromwell-server'. If one doesn't exists, this option won't work. 
2. Get the public IP address of the 'cromwell-server' EC2 instance from the EC2 dashboard
    
        It should look like this: 54.175.125.189 (note: this isn't the actual IP)
        
3. Open an SSH connection with cromwell server in one terminal on your local machine. Keep it open until you submit.
    
        ssh -L localhost:8000:localhost:8000 ec2-user@54.175.125.189
        
4. In another terminal on your local machine, submit the job to the server.

        curl -X POST "http://localhost:8000/api/workflows/v1" -H "accept: application/json" \
            -F "workflowSource=@/Users/awaldrop/PycharmProjects/metaxcan-pipeline/workflow/s-mulTiXcan_wf.wdl" \
            -F "workflowInputs=@/Users/awaldrop/PycharmProjects/metaxcan-pipeline/json_input/s-mulTiXcan_wf_example_input.json" \
            -F "workflowDependencies"=@/Users/awaldrop/Desktop/metaxcan-pipeline.zip
        
        
5. Make sure to record the id of the job you submitted. This will be used to track the status of your job. 

        {"id":"7067f7c3-ba65-401c-8bd0-5e0438535309","status":"Submitted"}
        
That's it. You can now exit the ssh terminal and the job will continue to run until error or completion. 

    
### Workflow outputs
Currently, all cromwell output gets written to **s3://rti-cromwell-output/cromwell-execution**
* s-prediXcan_wf.wdl output will be written to **s3://rti-cromwell-output/cromwell-execution/spredixcan_wf/<job_id>/**
* s-multiXcan_wf.wdl output will be written to **s3://rti-cromwell-output/cromwell-execution/smultixcan_wf/<job_id>/**

* Subfolders within your output directory will be created for each step in the workflow and hold that tasks output and log files

### Checking workflow status
This really only applies to running through the Cromwell server. Local cromwell runs will produce plenty of output. 

**NOTE: As a general rule, if you're not sure if your pipeline will run successfully run Cromwell on your computer so you can see error logs in real time.
It can be tricky sometimes to diagnose errors run through the server.**

When you run through server mode, you can check the status of an ongoing pipeline by opening up a terminal and connecting to the instance as with before:
    
    ssh -L localhost:8000:localhost:8000 ec2-user@54.175.125.189
    
Then use your browser to use the SWAGGER API by navigating to **http://localhost:8000/**

From there, you can choose the get_status() API request and enter the ID of the pipeline your tracking. 

If something failed, you can either go to the output directory to see what jobs ran and check the error messages. 

If you want to see real-time status of what jobs are getting run, navigate to the batch console on AWS and click on the **DefaultGenomicsQueue** to get a real-time readout 
of running jobs. 

#### What happens if my server job seems 'stuck?'
The cromwell server is currently a small instance. Lots of jobs running simultaenously can cause the server to run
out of heap space. You'll know your job is stuck because AWS batch will have no jobs queue/submitted/running but your analysis is halfway done or hasn't started.

The quick fix is to reboot the cromwell instance.

1. Reboot the 'cromwell-server' instance from the EC2 dashboard

2. ssh into to cromwell-server once EC2 is rebooted
        
        ssh -L localhost:8000:localhost:8000 ec2-user@54.175.125.189
3. Open a new screen session called Cromwell

        screen -S Cromwell
        
4. Re-start the cromwell server

        bash ./run_cromwell_server.sh
        
5. Close out of terminal. Cromwell server will be running in the background now and is live for new submissions.

If you want to check the output of Cromwell Server as it runs (say to check for a heap overflow error), ssh and run:

        screen -r Cromwell
        
This is another way to check if the server has run out of heap space. 
        

### Modifying JSON input files for your specific analysis 
These steps discuss how to modify the JSON input templates when you want to run your own analysis.

#### A note on example workflow input templates
The workflow input templates mentioned above are designed to give you an idea of the input files/values you'll need to set to run on your own data.
They're well commented and broken down by section to help orient you to which inputs are used by each task. 

All comments are entered as dummy input values starting with "##":

        "## Analysis name to be appended to output files for easily keeping track of outputs": "",
        
Actual parameters will look like "<workflow_name>.<input_parameter>":

        "spredixcan_wf.analysis_name" : "ftnd",


#### S-PrediXcan workflow inputs
1. Make a copy of the **json_input/s-prediXcan_wf_example_input.json**

2. Set the 'analysis_name' input. This name will be appended to output files to help keep track for downstream analysis. 

          "## Analysis name to be appended to output files for easily keeping track of outputs": "",
            "spredixcan_wf.analysis_name" : "ftnd",
          
3. Set your meta-analysis/GWAS input files in numerical chr order (1-22). Also make sure these files actually exists on CODE S3 or are public. 
 
        "spredixcan_wf.gwas_input_files": 
            [
            "s3://rti-nd/META/1df/20181108/results/ea/20181108_ftnd_meta_analysis_wave3.eur.chr1.exclude_singletons.1df.gz",
            "s3://rti-nd/META/1df/20181108/results/ea/20181108_ftnd_meta_analysis_wave3.eur.chr2.exclude_singletons.1df.gz",
            "s3://rti-nd/META/1df/20181108/results/ea/20181108_ftnd_meta_analysis_wave3.eur.chr3.exclude_singletons.1df.gz",
            ...
            "s3://rti-nd/META/1df/20181108/results/ea/20181108_ftnd_meta_analysis_wave3.eur.chr22.exclude_singletons.1df.gz"
            ],

4. Set the 1-based column indices for required columns as they appear in your GWAS inputs. 
         
            "spredixcan_wf.input_id_col":     1,
            "spredixcan_wf.input_chr_col":    2,
            "spredixcan_wf.input_pos_col":    3,
            "spredixcan_wf.input_a1_col":     4,
            "spredixcan_wf.input_a2_col":     5,
            "spredixcan_wf.input_beta_col":   6,
            "spredixcan_wf.input_se_col":     7,
            "spredixcan_wf.input_pvalue_col": 8,
            
5. Set the input paths to PredictDB tissue model files of interest. Example template already contains valid paths to all brain region models so no need to change if these are your target tissues.

        "####################### STEP_3 INPUTS: S-PrediXcan":"",
        "## Make sure PredictDB model_db/covariance files are in same tissue order": "",
        "spredixcan_wf.model_db_files": 
        [
            "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Amygdala_imputed_europeans_tw_0.5_signif.db",
            "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Anterior_cingulate_cortex_BA24_imputed_europeans_tw_0.5_signif.db",
            "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Caudate_basal_ganglia_imputed_europeans_tw_0.5_signif.db",
            ...
            "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Substantia_nigra_imputed_europeans_tw_0.5_signif.db"
        ],

6. Set the input paths to PredictDB covariance files for tissue of interest. 
    * Each model file must have corresponding covariance file. They should be in same order in array as well. 
    * Covariance filenames **must** have same filename as model file but replace .db with .txt.gz (MetaXcan will fail otherwise)
        
            "spredixcan_wf.covariance_files": 
            [
                "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Amygdala_imputed_europeans_tw_0.5_signif.db.txt.gz",
                "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Anterior_cingulate_cortex_BA24_imputed_europeans_tw_0.5_signif.db.txt.gz",
                "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Caudate_basal_ganglia_imputed_europeans_tw_0.5_signif.db.txt.gz",
                ...
                "s3://rti-common/metaxcan_predictDB/release_11-29-2017/GTEx-V7_HapMap-2017-11-29/gtex_v7_Brain_Substantia_nigra_imputed_europeans_tw_0.5_signif.db.txt.gz"
            ],
            
7. Set p-value correction method and corrected pvalue filtering cutoffs. Only genes below these thresholds will appear in filtered output files.

        "####################### STEP_4 INPUTS: P-VALUE CORRECTION:":"",
        "## Final filtered S-PrediXcan results will only contain genes with p-values <= these thresholds": "",
            "spredixcan_wf.adj_pvalue_filter_threshold_within_tissue" : 0.15,
            "spredixcan_wf.adj_pvalue_filter_threshold_across_tissue" : 0.15,

        "## Accepted methods for pvalue adjustment: fdr, bonferroni, holm, hochberg, hommel, BY": "",
        "## For more information on pvalue adjustments see R p.adjust() method": "",
            "spredixcan_wf.pvalue_adj_method" : "fdr"
            
8. You're done! All other input parameters are intended to be static across workflows. Modify with caution and only if you want to update a 
static reference file and know what you're doing.

#### S-MulTiXcan workflow inputs
Steps 1-8 are unchanged for modifying input template to run S-MulTiXcan workflow. Do those first. 

1. Modify MulTiXcan tissue regex pattern to parse out tissue names from PredictDB model files.

        "####################### STEP_4 INPUTS: MulTiXcan":"",
        "## Make sure model_name_pattern is a regex that matches all model filenames. The (.*) capture will extract the tissue name so make sure that's in the right place.": "",
            "smultixcan_wf.model_name_pattern": "gtex_v7_(.*)_imputed_europeans_tw_0.5_signif.db",
2. Modify regex to parse out tissue name from S-PrediXcan output files

    * S-PrediXcan output filenames will always be model filenames but ".db" is replaced with ".metaxcan_results.csv"

            "## Make sure metaxcan_file_name_parse_pattern is a regex that matches all sPrediXcan output filenames.": "",
            "## S-PrediXcan output filenames will be the model filename with '.db' replaced by 'metaxcan_results.csv'": "",
                "smultixcan_wf.metaxcan_file_name_parse_pattern": "gtex_v7_(.*)_imputed_europeans_tw_0.5_signif.metaxcan_results.csv",
                
3. Set the corrected p-value threshold for filtering S-MulTiXcan significant hits
        
        "####################### STEP_5 INPUTS: P-VALUE CORRECTION":"",
        "## Final filtered S-MulTiXcan results will only contain genes with p-values <= this thresholds": "",
            "smultixcan_wf.adj_pvalue_filter_threshold" : 0.75,

## A brief summary of how to run the workflow on your data
1. Create a new JSON input file specific to your analysis. Usually just means modifying the following:
        
        1. GWAS Input files
        2. PredictDB tissue model files
        3. pvalue filter thresholds
        
2. Run the workflow using WDL either on your local machine or through Cromwell Server
3. Monitor the job until it completes

## Authors
For any questions, comments, concerns, or bugs,
send me an email or slack and I'll be happy to help. 
* [Alex Waldrop](https://github.com/alexwaldrop) (awaldrop@rti.org)
