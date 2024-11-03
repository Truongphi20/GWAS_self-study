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
    path("HDLC_chr3.genes.annot")

    """
    magma --annotate \
      --snp-loc ${snploc} \
      --gene-loc ${ncbi37} \
      --out HDLC_chr3
    """
}

process DOWNLOAD_REFERENCE{
    container "phinguyen2000/unzip:318d185"

    output:
    tuple val("g1000_sas"), path("g1000_sas.{bed,bim,fam}")

    script:
    down_link = "https://vu.data.surfsara.nl/index.php/s/C6UkTV5nuFo8cJC/download"

    """
    wget $down_link
    unzip download
    """
}

process GENE_BASED_ANALYSIS{
    container "phinguyen2000/magma:167b2d2"

    input:
    tuple path(magma_p), val(g1000_eas_prefix), path(g1000_eas), path(genes_annot)

    output:
    path("HDLC_chr3.genes.raw")
    """
    magma \
        --bfile $g1000_eas_prefix\
        --pval $magma_p N=70657 \
        --gene-annot $genes_annot \
        --out HDLC_chr3
    """
}

process GENE_SET_LEVEL {
    container "phinguyen2000/magma:167b2d2"

    input:
    tuple path(genes_raw), path(geneset)

    output:
    path("HDLC_chr3*")

    """
    magma \
    --gene-results $genes_raw\
    --set-annot ${geneset} \
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
    DOWNLOAD_REFERENCE()
    GENE_BASED_ANALYSIS(
        FORMAT_INPUT.out.magma_p
                    .combine(DOWNLOAD_REFERENCE.out)
                    .combine(ANNOTATE_SNPS.out)
    )

    geneset = channel.fromPath("https://data.broadinstitute.org/gsea-msigdb/msigdb/release/2022.1.Hs/msigdb.v2022.1.Hs.entrez.gmt")
    GENE_SET_LEVEL(
        GENE_BASED_ANALYSIS.out.combine(geneset)
    )

}