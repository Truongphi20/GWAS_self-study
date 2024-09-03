process UNZIP_PROCESS{
    container "phinguyen2000/unzip:318d185"

    input:
    path missing_file

    output:
    tuple val(prefix), path("$prefix/${prefix}.{bed,bim,fam}")

    script:
    prefix = missing_file.name.replace('.zip', '')
    """
    unzip $missing_file
    """
}

process CALCULATE_MISSING_RATE{
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple val(prefix), path(genotypeFile)

    output:
    tuple val("plink_results"), path("plink_results.{imiss,lmiss}")

    """
    plink \
    --bfile ${prefix} \
    --missing \
    --out plink_results
    """
}

process CALCULATE_ALLELE_FREQUENCY_PLINK{
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple val(prefix), path(genotypeFile)

    output:
    path("plink_results.frq")


    """
    plink \
    --bfile ${prefix} \
    --freq \
    --out plink_results
    """
}

process CALCULATE_ALLELE_FREQUENCY_PLINK2{
    container "phinguyen2000/plink2:v2.00a5.10LM"

    input:
    tuple val(prefix), path(genotypeFile)

    output:
    path("plink_results.afreq")


    """
    plink2 \
    --bfile ${prefix} \
    --freq \
    --out plink_results
    """
}

process CALCULATE_HARDY_WEINBERG_EQUILIBRIUM{
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple val(prefix), path(genotypeFile)

    output:
    path("plink_results.hwe")

    """
    plink \
    --bfile ${prefix} \
    --hardy \
    --out plink_results
    """
}

process LD_PRUNING{
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple val(prefix), path(genotypeFile)

    output:
    path("plink_results.prune.{in,out}")

    """
    plink \
    --bfile ${prefix} \
    --maf 0.01 \
    --geno 0.02 \
    --mind 0.02 \
    --hwe 1e-6 \
    --indep-pairwise 50 5 0.2 \
    --out plink_results
    """

}

process INBREEDING_F_COEFFICIENT{
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple val(prefix), path(genotypeFile), path(prune)

    output:
    path("plink_results.het")

    """
    plink \
    --bfile ${prefix} \
    --extract ${prune[0]} \
    --het \
    --out plink_results
    """
}

process ESTIMATE_IBD{
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple val(prefix), path(genotypeFile), path(prune)

    output:
    path("plink_results.genome")

    """
    plink \
    --bfile ${prefix} \
    --extract ${prune[0]} \
    --genome \
    --out plink_results
    """
}

process LD_CALCULATION {
    container "phinguyen2000/plink:v1.90b7.2"

    input:
    tuple val(prefix), path(genotypeFile)

    output:
    path("plink_results.ld")

    """
    plink \
        --bfile ${prefix} \
        --chr 22 \
        --r2 \
        --out plink_results
    """
}

workflow PRE_GWAS {
    input_file = "https://github.com/Cloufield/GWASTutorial/raw/main/01_Dataset/1KG.EAS.auto.snp.norm.nodup.split.rare002.common015.missing.zip"
    missing_file = channel.fromPath("$input_file")


    UNZIP_PROCESS(missing_file)
    CALCULATE_MISSING_RATE(UNZIP_PROCESS.out)
    CALCULATE_ALLELE_FREQUENCY_PLINK(UNZIP_PROCESS.out)
    CALCULATE_ALLELE_FREQUENCY_PLINK2(UNZIP_PROCESS.out)
    CALCULATE_HARDY_WEINBERG_EQUILIBRIUM(UNZIP_PROCESS.out)
    LD_PRUNING(UNZIP_PROCESS.out)
    INBREEDING_F_COEFFICIENT(UNZIP_PROCESS.out.combine(LD_PRUNING.out.map{[it]}))
    ESTIMATE_IBD(UNZIP_PROCESS.out.combine(LD_PRUNING.out.map{[it]}))
    LD_CALCULATION(UNZIP_PROCESS.out)
}