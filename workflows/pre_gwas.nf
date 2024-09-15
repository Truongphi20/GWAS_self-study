include { DATA_FORMATING }            from            "../subworkflows/data_formating.nf"
include { PCA }                       from            "../subworkflows/pca.nf"


workflow PRE_GWAS {
    DATA_FORMATING()
    PCA(DATA_FORMATING.out.apply_all_filters)

    emit:
    apply_all_filters = DATA_FORMATING.out.apply_all_filters
    sscore_file = PCA.out.sscore_file
}