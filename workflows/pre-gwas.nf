process UNZIP_PROCESS{
    container "phinguyen2000/unzip:318d185"

    input:
    path missing_file

    output:
    path "$prefix/${prefix}.{bed,bim,fam}"

    script:
    prefix = missing_file.name.replace('.zip', '')
    """
    unzip $missing_file
    """
}



workflow PRE_GWAS {
    missing_file = channel.fromPath("$projectDir/GWASTutorial/01_Dataset/*.missing.zip")


    UNZIP_PROCESS(missing_file)
}