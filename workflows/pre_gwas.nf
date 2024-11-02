include { DATA_FORMATING }            from            "../subworkflows/data_formating.nf"
include { PCA }                       from            "../subworkflows/pca.nf"


workflow PRE_GWAS {
    DATA_FORMATING()
    PCA(DATA_FORMATING.out.apply_all_filters)

    emit:
    pheno_simulate = DATA_FORMATING.out.pheno_simulate
    genotypeFile = DATA_FORMATING.out.genotypeFile
    apply_all_filters = DATA_FORMATING.out.apply_all_filters
    sscore_file = PCA.out.sscore_file
    prunedSNP = DATA_FORMATING.out.prunedSNP
}