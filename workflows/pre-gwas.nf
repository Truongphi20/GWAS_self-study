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



workflow PRE_GWAS {
    missing_file = channel.fromPath("$projectDir/GWASTutorial/01_Dataset/*.missing.zip")


    UNZIP_PROCESS(missing_file)
    CALCULATE_MISSING_RATE(UNZIP_PROCESS.out)
    CALCULATE_ALLELE_FREQUENCY_PLINK(UNZIP_PROCESS.out)
    CALCULATE_ALLELE_FREQUENCY_PLINK2(UNZIP_PROCESS.out)
}