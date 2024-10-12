process MAKE_GRM {
    container "phinguyen2000/gcta:dab9a33"

    input:
    tuple val(prefix), path(genotypeFile)

    """
    gcta \
        --bfile ${prefix} \
        --autosome \
        --maf 0.01 \
        --make-grm \
        --out 1kg_eas
    """
}



workflow SNP_HERITABILITY_ESTIMATION {
    take:
    genotypeFile

    main:
    MAKE_GRM(genotypeFile)
}