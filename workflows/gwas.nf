process ASSOCIATION_TEST {
    container "phinguyen2000/plink2:v2.00a5.10LM"

    input:
    tuple val(prefix_clean_pre_gwas), path(clean_pre_gwas), path(phenotypeFile), path(sscore_file)

    output:
    path("1kgeas.B1.glm.firth")

    """
    plink2 \
        --bfile ${prefix_clean_pre_gwas} \
        --pheno ${phenotypeFile} \
        --pheno-name B1\
        --maf 0.01 \
        --covar ${sscore_file} \
        --covar-col-nums 6-10 \
        --glm hide-covar firth  firth-residualize single-prec-cc \
        --threads ${task.cpus} \
        --out 1kgeas
    """
}

workflow GWAS {
    take:
    clean_pre_gwas
    sscore_file

    main:
    phenotypeFile = channel.fromPath("https://raw.githubusercontent.com/Truongphikt/GWASTutorial/main/01_Dataset/1kgeas_binary.txt")

    ASSOCIATION_TEST(
        clean_pre_gwas.combine(phenotypeFile)
                      .combine(sscore_file)
    )

}