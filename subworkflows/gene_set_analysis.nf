process FORMAT_INPUT{
    container "ubuntu:22.04"

    input:
    path(bbj_hdlc_sumstats)

    output:
    path("HDLC_chr3.magma.input.snp.chr.pos.txt"), emit: magma_pos
    path("HDLC_chr3.magma.input.p.txt")          , emit: magma_p

    """
    zcat $bbj_hdlc_sumstats | awk 'NR>1 && \$2==3 {print \$1,\$2,\$3}' > HDLC_chr3.magma.input.snp.chr.pos.txt
    zcat $bbj_hdlc_sumstats | awk 'NR>1 && \$2==3 {print \$1,10^(-\$11)}' >  HDLC_chr3.magma.input.p.txt
    """
}

process ANNOTATE_SNPS {
    container "phinguyen2000/magma:167b2d2"

    input:
    tuple path(snploc), path(ncbi37)

    output:
    path("HDLC_chr3*")

    """
    magma --annotate \
      --snp-loc ${snploc} \
      --gene-loc ${ncbi37} \
      --out HDLC_chr3
    """
}


workflow GENE_SET_ANALYSIS{
    take:
    bbj_hdlc_sumstats
    
    main:
    FORMAT_INPUT(bbj_hdlc_sumstats)

    ncbi37 = channel.fromPath("https://raw.githubusercontent.com/Truongphi20/GWASTutorial/refs/heads/main/19_ld/magma_genloc37/NCBI37.3.gene.loc")
    ANNOTATE_SNPS(
        FORMAT_INPUT.out.magma_pos
                    .combine(ncbi37)
    )
}