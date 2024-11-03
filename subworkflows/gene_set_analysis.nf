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


workflow GENE_SET_ANALYSIS{
    take:
    bbj_hdlc_sumstats
    
    main:
    FORMAT_INPUT(bbj_hdlc_sumstats)

}