library(dplyr)

process_raw_combined_results = function(input_file, filename_prefix, filename_suffix, ...){
  # Input file is assumed to be the combined output from metaxcan across multiple tissues
  # Should have a column 'X' that contains the source filename
  # Prefix and suffix are strings that need to be stripped from filenames to parse tissue names
  # Ouptut is file with adjusted pvalues and tissue source column
  
  # Read csv input file
  data = read.csv(input_file, header=T)

  # Adjust pvalues for multiple tests
  data$pvalue_adjusted = p.adjust(data$pvalue, ...)

  # Extract tissue name from source filename column for each result
  data$tissue = gsub(filename_suffix, "",gsub(filename_prefix, "", data$X)) 

  # Get only desired columns
  data = select(data, gene, gene_name, zscore, effect_size, pvalue, var_g, pred_perf_r2, pred_perf_pval, n_snps_used, n_snps_in_cov, n_snps_in_model, pvalue_adjusted, tissue)

  # Return data
  return(data)
}

###### Full Nicotine gwas results
input_file = "/Users/awaldrop/Desktop/projects/dana/metaxcan/analysis/results/nic_meta_analysis/full_metaxcan_results_combined.csv"
output_file = "/Users/awaldrop/Desktop/projects/dana/metaxcan/analysis/results/nic_meta_analysis/final_full_metaxcan_results_combined.csv"
filename_prefix = "gtex_v7_"
filename_suffix = "_imputed_europeans_tw_0.5_signif.metaxcan_results"
method = "fdr"

# Process data and write to CSV
data = process_raw_combined_results(input_file, filename_prefix, filename_suffix, method=method)
write.csv(data, output_file)
