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

Workflow WDL files:
   * Metaxcan workflow: **workflow/s-prediXcan_wf.wdl**
   * Multixcan workflow: **workflow/s-mulTiXcan_wf.wdl**
    
WDL input file templates:
   * MetaXcan input template: **json_input/s-prediXcan_wf_example_input.json**
   * MultiXcan input template: **json_input/s-mulTiXcan_wf_example_input.json**

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
2. Get the public IP address of the 'cromwell-server' EC2 instance
    
        It should look like this: 54.175.125.189 (note: this isn't the actual IP)
        
3. Open an SSH connection with cromwell server in one terminal. Keep it open until you submit.
    
        ssh -L localhost:8000:localhost:8000 ec2-user@54.175.125.189
        
4. In another terminal, use curl to submit the job to the server.

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

### Setting your input parameters





## A brief summary of how to run the workflow on your data
1. Create a new JSON input file for the pipeline by making a copy of the example template.
2. Update the values specific to your analysis. These are ones you may have to change depending on your analysis. 
        1. GWAS Input files
        2. PredictDB tissue model files
        3. pvalue filter thresholds
3. Run the workflow using WDL
4. Monitor the job until it completes

## Authors
For any questions, comments, concerns, or bugs,
send me an email or slack and I'll be happy to help. 
* [Alex Waldrop](https://github.com/alexwaldrop) (awaldrop@rti.org)
