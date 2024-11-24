process SUSIER  {
    container "phinguyen2000/susier:ba90ff1"
    
    input:
    path(sumstats), path(susie_notebook), path(human_ref), val(prefix), path(bfile) 

    output:
    path("rendered_susier.ipynb")
    path("sig_locus.tsv")
    path("sig_locus.snplist")

    """
    export SUMSTAT=$sumstats
    export HUMAN_REF_CHR37=$human_ref
    export PREFIX_BFILE=$prefix

    jupyter nbconvert --to notebook --execute $susie_notebook --output "rendered_susier.ipynb"
    """
}