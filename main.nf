include { PRE_GWAS }            from            "./workflows/pre-gwas.nf"
include { PCA }                 from            "./workflows/pca.nf"


workflow {
    PRE_GWAS()
    PCA(PRE_GWAS.out.apply_all_filters)
}