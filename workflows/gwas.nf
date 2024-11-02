process ASSOCIATION_TEST {
    container "phinguyen2000/plink2:v2.00a5.10LM"

    input:
    tuple val(prefix_clean_pre_gwas), path(clean_pre_gwas), path(phenotypeFile), path(sscore_file)

    output:
    path("1kgeas.B1.glm.firth"), emit: firth_file

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

process VISUALIZE {
    container "phinguyen2000/gwaslab:853cd62"

    memory "4.GB"
    cpus "2"

    input:
    path(firth_file)

    output:
    path("*.png")

    """
    #!/usr/bin/env python

    import gwaslab as gl
    import matplotlib.pyplot as plt

    # Load sumstats
    sumstats = gl.Sumstats("$firth_file",fmt="plink2")

    # Create mahattan plot
    plt.figure(figsize=(10,10))
    sumstats.plot_mqq(skip=2,anno=True)
    plt.savefig("mahattan.png", dpi=300)

    # Create regional plot
    plt.figure(figsize=(10,10))
    sumstats.plot_mqq(mode="r",anno=True,region=(2,54513738,56513738),region_grid=True,build="19")
    plt.savefig("regional.png", dpi=300)

    # Create regional plot with LD information
    gl.download_ref("1kg_eas_hg19")
    plt.figure(figsize=(10,10))
    sumstats.plot_mqq(mode="r",anno=True,region=(2,54531536,56731536),region_grid=True,vcf_path=gl.get_path("1kg_eas_hg19"),build="19")
    plt.savefig("regional_ld.png", dpi=300)
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

    // VISUALIZE(ASSOCIATION_TEST.out.firth_file)

    emit:
    firth_file = ASSOCIATION_TEST.out.firth_file

}