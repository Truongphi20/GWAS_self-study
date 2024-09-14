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

process LD_PRUNING{
    container "phinguyen2000/plink2:v2.00a5.10LM"

    input:
    tuple path(high_ld_file), path(hildset)

    output:
    path("ld_pruning.prune.in")

    """
    plink2 \
        --bfile ${high_ld_file} \
        --maf 0.01 \
        --threads ${task.cpus} \
        --exclude ${hildset} \
        --indep-pairwise 500 50 0.2 \
        --out ld_pruning

    """
}

process REMOVE_RELATED_SAMPLES{
    container "phinguyen2000/plink2:v2.00a5.10LM"

    input:
    tuple path(high_ld_file), path(prune_in)

    output:
    path("king_cutoff.king.cutoff.in.id")

    """
    plink2 \
        --bfile ${plinkFile} \
        --extract $prune_in \
        --king-cutoff 0.0884 \
        --threads ${task.cpus} \
        --out king_cutoff
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

    LD_PRUNING(
        high_ld_file.combine(CREATE_HLA_REGION.out)
    )

    REMOVE_RELATED_SAMPLES(
        high_ld_file.combine(LD_PRUNING.out)
    )


}