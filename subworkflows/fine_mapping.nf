process FILE_PREPARATION{
    container "phinguyen2000/gwaslab:853cd62"


    input:
    tuple path(firth_file), path(human_g1k_v37)


    output:
    path("sig_locus.snplist")


    """
    #!/usr/bin/env python

    import gwaslab as gl
    import pandas as pd
    import numpy as np

    sumstats = gl.Sumstats("$firth_file",fmt="plink2")
    sumstats.basic_check()
    sumstats.get_lead()


    # filter in the variants in the this locus.

    locus = sumstats.filter_value('CHR==2 & POS>55074452 & POS<56074452')
    locus.fill_data(to_fill=["BETA"])
    locus.harmonize(basic_check=False, ref_seq="${human_g1k_v37[0]}")
    locus.data.to_csv("sig_locus.tsv",sep="\t",index=None)
    locus.data["SNPID"].to_csv("sig_locus.snplist",sep="\t",index=None,header=None)
    """
}

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

    main:
    DOWNLOAD_HUMAN_G1K_V37()
    FILE_PREPARATION(
        firth_file.combine(DOWNLOAD_HUMAN_G1K_V37.out.map{[it]})
    )
}