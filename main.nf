include { PRE_GWAS }             from            "./workflows/pre_gwas.nf"
include { GWAS }                 from            "./workflows/gwas.nf"
include { POST_GWAS }            from            "./workflows/post_gwas.nf"


workflow {
    PRE_GWAS()
    GWAS(
        PRE_GWAS.out.apply_all_filters,
        PRE_GWAS.out.sscore_file
    )
    POST_GWAS(
        PRE_GWAS.out.genotypeFile,
        GWAS.out.firth_file,
        PRE_GWAS.out.pheno_simulate,
        PRE_GWAS.out.sscore_file,
        PRE_GWAS.out.prunedSNP,
        PRE_GWAS.out.apply_all_filters
    )
}