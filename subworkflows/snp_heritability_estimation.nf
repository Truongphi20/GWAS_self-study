process MAKE_GRM {
    container "phinguyen2000/gcta:dab9a33"

    input:
    tuple val(prefix), path(apply_all_filters), path(prunedSNP)

    output:
    tuple val("1kg_eas"), path("1kg_eas.grm.{bin,id,N.bin}")

    """
    gcta \
        --bfile ${prefix} \
        --extract ${prunedSNP} \
        --autosome \
        --maf 0.01 \
        --make-grm \
        --out 1kg_eas
    """
}

process ESTIMATION{
    container "phinguyen2000/gcta:dab9a33"

    input:
    tuple val(prefix_grm), path(grm), val(prefix_pheno), path(pheno_simulate), path(sscore_file)

    output:
    path("5PCs.txt"), emit: pcs
    path("1kg_eas*"), emit: main

    """
    awk '{print \$1,\$2,\$5,\$6,\$7,\$8,\$9}' $sscore_file > 5PCs.txt
    gcta \
        --grm ${prefix_grm} \
        --pheno ${prefix_pheno}.phen \
        --prevalence 0.5 \
        --qcovar  5PCs.txt \
        --reml \
        --out 1kg_eas \
        --thread-num $task.cpus
    """
}



workflow SNP_HERITABILITY_ESTIMATION {
    take:
    genotypeFile
    pheno_simulate
    sscore_file
    prunedSNP
    apply_all_filters

    main:
    MAKE_GRM(
        apply_all_filters.combine(prunedSNP)
    )

    ESTIMATION(
        MAKE_GRM.out.combine(pheno_simulate)
                    .combine(sscore_file)
    )
}