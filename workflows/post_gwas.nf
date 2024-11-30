include {  ANNOTATION  }                         from            "../subworkflows/annotation.nf"
include {  SNP_HERITABILITY_ESTIMATION }         from            "../subworkflows/snp_heritability_estimation.nf"
include {  LD_SCORE_REGRESSION         }         from            "../subworkflows/ls_score_regression.nf"
include {  GENE_SET_ANALYSIS           }         from            "../subworkflows/gene_set_analysis.nf"
include {  FINE_MAPPING                }         from            "../subworkflows/fine_mapping.nf"
include {  META_ANALYSIS              }         from            "../subworkflows/meta_analysis.nf"

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
    GENE_SET_ANALYSIS(
        LD_SCORE_REGRESSION.out.bbj_hdlc_sumstats
    )

    FINE_MAPPING(
        firth_file,
        genotypeFile
    )

    META_ANALYSIS()
}