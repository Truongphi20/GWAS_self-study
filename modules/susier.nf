process SUSIER  {
    container "phinguyen2000/susier:f40a095"

    memory '10.GB'
    cpus 5
    
    input:
    tuple path(sumstats), path(susie_notebook), path(human_ref), path(human_ref_fai), val(prefix), path(bfile) 

    output:
    path("rendered_susier.ipynb")
    path("sig_locus.tsv")
    path("sig_locus.snplist")
    path("sig_locus_mt.ld")
    path("sig_locus_mt_r2.ld")
    path("credible_r.ld")
    path("credible_r2.ld")

    """
    export SUMSTAT=$sumstats
    export HUMAN_REF_CHR37=$human_ref
    export PREFIX_BFILE=$prefix

    jupyter nbconvert --to notebook --execute $susie_notebook --output "rendered_susier.ipynb"
    """
}