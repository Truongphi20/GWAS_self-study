process MAKE_GRM {
    container "phinguyen2000/gcta:dab9a33"

    input:
    tuple val(prefix), path(genotypeFile)

    output:
    tuple val("1kg_eas"), path("1kg_eas.grm.{bin,id,N.bin}")

    """
    gcta \
        --bfile ${prefix} \
        --autosome \
        --maf 0.01 \
        --make-grm \
        --out 1kg_eas
    """
}

process ESTIMATION{
    container "phinguyen2000/gcta:dab9a33"

    input:
    tuple val(prefix_grm), path(grm), val(prefix_pheno), path(pheno_simulate)

    """
    gcta \
        --grm ${prefix_grm} \
        --pheno ${prefix_pheno}_gcta.txt \
        --prevalence 0.5 \
        --qcovar  5PCs.txt \
        --reml \
        --out 1kg_eas
    """
}



workflow SNP_HERITABILITY_ESTIMATION {
    take:
    genotypeFile
    pheno_simulate

    main:
    MAKE_GRM(genotypeFile)
    ESTIMATION(MAKE_GRM.out.combine(pheno_simulate))
}