import "metaxcan-pipeline/workflow/tasks/metaxcan_preprocessing.wdl" as PREPROCESSING
import "metaxcan-pipeline/workflow/tasks/metaxcan.wdl" as METAXCAN
import "metaxcan-pipeline/workflow/tasks/utilities.wdl" as UTIL

workflow smultixcan_wf {

    # Inputs for metamany
    Array[File] gwas_files
    Array[File] model_db_files
    Array[String] metaxcan_output_files
    File covariance_file
    String model_name_pattern
    String metaxcan_file_name_parse_pattern
    String snp_column
    String effect_allele_column
    String non_effect_allele_column
    String beta_column
    String pvalue_column
    String se_column
    Float smultixcan_cutoff_threshold = 0.4

    # Run s-prediXcan in parallel across input tissue types
    call METAXCAN.smultixcan as smultixcan{
        input:
            model_db_files = model_db_files,
            metaxcan_output_files = metaxcan_output_files,
            gwas_files = gwas_files,
            covariance_file = covariance_file,
            model_name_pattern = model_name_pattern,
            metaxcan_file_name_parse_pattern = metaxcan_file_name_parse_pattern,
            output_base = "multixcan_test",
            snp_column = snp_column,
            effect_allele_column = effect_allele_column,
            non_effect_allele_column = non_effect_allele_column,
            beta_column = beta_column,
            pvalue_column = pvalue_column,
            se_column = se_column,
            cutoff_threshold=smultixcan_cutoff_threshold
     }

    output{
        File metaxcan_output = smultixcan.smultixcan_output
    }

}