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
    tuple val(prefix_clean_pre_gwas), path(clean_pre_gwas), path(hildset)

    output:
    path("ld_pruning.prune.in")

    """
    plink2 \
        --bfile ${prefix_clean_pre_gwas} \
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
    tuple val(prefix_clean_pre_gwas), path(clean_pre_gwas), path(prune_in)

    output:
    path("king_cutoff.king.cutoff.in.id")

    """
    plink2 \
        --bfile ${prefix_clean_pre_gwas} \
        --extract $prune_in \
        --king-cutoff 0.0884 \
        --threads ${task.cpus} \
        --out king_cutoff
    """
}

process PCA_PROCESSING{
    container "phinguyen2000/plink2:v2.00a5.10LM"

    input:
    tuple val(prefix_clean_pre_gwas), path(clean_pre_gwas), path(prune_in), path(king_cutoff)

    output:
    path("pca.acount"), emit: acount_file
    path("pca.eigenvec.allele"), emit: allele_file

    """
    plink2 \
        --bfile ${prefix_clean_pre_gwas} \
        --keep $king_cutoff \
        --extract $prune_in \
        --freq counts \
        --threads ${task.cpus} \
        --pca approx allele-wts 10 \
        --out pca
    """
}

process PROJECT_SAMPLE{
    container "phinguyen2000/plink2:v2.00a5.10LM"

    input:
    tuple val(prefix_clean_pre_gwas), path(clean_pre_gwas), path(acount_file), path(allele_file)

    output:
    path("projected.sscore")

    """
    plink2 \
        --bfile ${prefix_clean_pre_gwas} \
        --threads ${task.cpus} \
        --read-freq $acount_file \
        --score $allele_file 2 6 header-read no-mean-imputation variance-standardize \
        --score-col-nums 7-16 \
        --out projected
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
        apply_all_filters.combine(CREATE_HLA_REGION.out)
    )

    REMOVE_RELATED_SAMPLES(
        apply_all_filters.combine(LD_PRUNING.out)
    )

    PCA_PROCESSING(
        apply_all_filters.combine(LD_PRUNING.out)
                         .combine(REMOVE_RELATED_SAMPLES.out)
    )

    PROJECT_SAMPLE(
        apply_all_filters.combine(PCA_PROCESSING.out.acount_file)
                         .combine(PCA_PROCESSING.out.allele_file)
    )


}