include { PRE_GWAS }        from            "./workflows/pre_gwas.nf"
include { GWAS }            from            "./workflows/gwas.nf"


workflow {
    PRE_GWAS()
    GWAS(
        PRE_GWAS.out.apply_all_filters,
        PRE_GWAS.out.sscore_file
    )
}