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

process PCA_PLOT{
    container "phinguyen2000/seaborn:624a037"

    input:
    tuple path(sscore_file), path(meta_panel)

    output:
    path("pca_plot.png")

    """
    #!/usr/bin/env python

    import pandas as pd
    import matplotlib.pyplot as plt
    import seaborn as sns


    pca = pd.read_table("$sscore_file",sep="\t")
    ped = pd.read_table("$meta_panel",sep="\t")

    pcaped=pd.merge(pca,ped,right_on="sample",left_on="IID",how="inner")
    plt.figure(figsize=(10,10))
    sns.scatterplot(data=pcaped,x="PC1_AVG",y="PC2_AVG",hue="pop",s=50)
    plt.savefig("pca_plot.png", dpi=300)
    """
}


workflow PCA {
    take:
    apply_all_filters

    main:
    high_ld_file = channel.fromPath("https://raw.githubusercontent.com/Cloufield/GWASTutorial/main/05_PCA/high-ld-hg19.txt")
    meta_panel_file = channel.fromPath("https://raw.githubusercontent.com/Cloufield/GWASTutorial/main/01_Dataset/integrated_call_samples_v3.20130502.ALL.panel")
    
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

    PCA_PLOT(
        PROJECT_SAMPLE.out.combine(meta_panel_file)
    )


}