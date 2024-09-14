process CREATE_HLA_REGION{
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple path(high_ld_file), val(prefix_clean_pre_gwas), path(clean_pre_gwas)

    output:
    path("hild.set")

    """
    plink \
    --bfile $prefix_clean_pre_gwas \
    --make-set $high_ld_file \
    --write-set \
    --out hild
    """
}


workflow PCA {
    take:
    apply_all_filters

    main:
    high_ld_file = channel.fromPath("https://raw.githubusercontent.com/Cloufield/GWASTutorial/main/05_PCA/high-ld-hg19.txt")
    
    CREATE_HLA_REGION(
        high_ld_file.combine(apply_all_filters)
    )


}