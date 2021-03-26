task harmonize_sumstats{

    File sumstats_in
    File? liftover_key
    File? snp_ref_metadata

    # Output basename
    String? user_output_filename
    String default_output_filename = basename(basename(basename(sumstats_in, ".gz"), ".tsv"), ".txt") + ".harmonized.txt.gz"
    String output_filename = select_first([user_output_filename, default_output_filename])

    # Optional blacklist file of snps to exclude
    File? snp_info_blacklist

    # Optinal snp info file for getting additional information
    File? snp_info_file

    # Names of columns to standardize from input
    String id_colname_in
    String pos_colname_in
    String chr_colname_in
    String effect_allele_colname_in
    String non_effect_allele_colname_in
    String effect_size_colname_in
    String pvalue_colname_in
    String? samplesize_colname_in

    # Mapped output column names
    String id_colname_out = "variant_id"
    String pos_colname_out = "position"
    String chr_colname_out = "chromosome"
    String effect_allele_colname_out = "effect_allele"
    String non_effect_allele_colname_out = "non_effect_allele"
    String effect_size_colname_out = "effect_size"
    String pvalue_colname_out = "pvalue"
    String samplesize_colname_out = "sample_size"

    # Create dummy samplesize column when not present
    # For some reason the program requires this column to be present so we've got to take it if it's not there
    String samplesize_arg = if (!defined(samplesize_colname_in)) then "--insert_value sample_size 1" else "-output_colname_map ${samplesize_colname_in} ${samplesize_colname_out}"

    # Output column orders
    Array[String] col_order = ["variant_id", "panel_variant_id", "chromosome", "position", "effect_allele", "non_effect_allele", "pvalue", "zscore", "effect_size", "standard_error", "sample_size", "frequency"]

    # Whether to prepend 'chr' to chromosome names
    Boolean chr_format_out = true

    # Handle any whitespace character (tabs or spaces)
    String separator = "ANY_WHITESPACE"

    # Provide optional list of args to insert values with a specific colname
    # e.g. --insert_value sample_size 184305 --insert_value n_cases 60801 would be passed as
    # ["sample_size 184305", "n_cases 60801"]
    Array[String]? insert_values
    Boolean has_insert_values = defined(insert_values)

    # Provide optional list of additional colname mappings
    # e.g. -output_colname_map CHISQUARE chisq -output_colname_map Z-score z would be passed as
    # ["CHISQUARE chisq", "Z-score z"]
    Array[String]? extra_col_maps
    Boolean has_extra_col_maps = defined(extra_col_maps)

    # Optional args (these args default to gwas_parsing.py default args if not set)
    Boolean keep_all_original_entries = false
    String? skip_until_header
    Boolean handle_empty_columns = false
    Boolean force_special_handling = false
    Boolean input_pvalue_fix = false
    Boolean enforce_numeric_columns = false

    String docker = "rtibiocloud/summary_gwas_imputation:commit_206dac5_e47b986"
    Int cpu = 1
    Int mem_gb = 6
    Int max_retries = 3

    command<<<
        # Activate conda env
        source activate imlabtools

        python /opt/summary-gwas-imputation/src/gwas_parsing.py \
            -gwas_file ${sumstats_in} \
            ${'-liftover ' + liftover_key} \
            ${'-snp_reference_metadata ' + snp_ref_metadata} \
            -output ${output_filename} \
            -output_column_map ${id_colname_in} ${id_colname_out} \
            -output_column_map ${pos_colname_in} ${pos_colname_out} \
            -output_column_map ${chr_colname_in} ${chr_colname_out} \
            -output_column_map ${effect_allele_colname_in} ${effect_allele_colname_out} \
            -output_column_map ${non_effect_allele_colname_in} ${non_effect_allele_colname_out} \
            -output_column_map ${pvalue_colname_in} ${pvalue_colname_out} \
            -output_column_map ${effect_size_colname_in} ${effect_size_colname_out} \
            ${samplesize_arg} \
            -output_order ${sep=" " col_order} \
            ${true='--chromosome_format' false='' chr_format_out} \
            ${true='--enforce_numeric_columns' false='' enforce_numeric_columns} \
            ${true='--keep_all_original_entries' false='' keep_all_original_entries} \
            ${'-separator ' + separator} \
            ${'-skip_until_header ' + skip_until_header} \
            ${true='--handle_empty_columns' false='' handle_empty_columns} \
            ${true='--force_special_handling' false='' force_special_handling} \
            ${true='-input_pvalue_fix' false='' input_pvalue_fix} \
            ${'-fill_from_snp_info ' + snp_info_file} \
            ${'-snp_info_blacklist ' + snp_info_blacklist} \
            ${true='--enforce_numeric_columns' false='' enforce_numeric_columns} \
            ${true='--insert_value' false='' has_insert_values} ${sep=' --insert_value ' insert_values} \
            ${true='-output_colname_map' false='' has_extra_col_maps} ${sep=' -output_colname_map ' extra_col_maps}
    >>>

    output{
        File output_file = "${output_filename}"
    }

    runtime {
        docker: docker
        cpu: cpu
        memory: "${mem_gb} GB"
        maxRetries: max_retries
    }
}