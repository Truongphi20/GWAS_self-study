include {  BASICS  }                from            "../modules/basics.nf"

process DOWNLOAD_HUMAN_G1K_V37{
    container "phinguyen2000/wget:1.21.4"
    disk '10 GB'

    output:
    path("human_g1k_v37.{fasta,fasta.fai}", arity: '2')

    """
    wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.gz
    wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/human_g1k_v37.fasta.fai
    gunzip human_g1k_v37.fasta.gz || true
    """
}


workflow FINE_MAPPING{
    take:
    firth_file
    genotypeFile

    main:
    DOWNLOAD_HUMAN_G1K_V37()
    BASICS(
        firth_file,
        genotypeFile,
        DOWNLOAD_HUMAN_G1K_V37.out
    )
}