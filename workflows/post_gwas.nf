include {  ANNOTATION  }                         from            "../subworkflows/annotation.nf"
include {  SNP_HERITABILITY_ESTIMATION }         from            "../subworkflows/snp_heritability_estimation.nf"
include {  LD_SCORE_REGRESSION         }         from            "../subworkflows/ls_score_regression.nf"

workflow POST_GWAS {
   take:
   genotypeFile
   firth_file
   pheno_simulate
   sscore_file
   prunedSNP
   apply_all_filters

   main:
   ANNOTATION(firth_file)
   SNP_HERITABILITY_ESTIMATION(
        genotypeFile, 
        pheno_simulate,
        sscore_file,
        prunedSNP,
        apply_all_filters
    )
    LD_SCORE_REGRESSION()
}