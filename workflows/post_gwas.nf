include {  ANNOTATION  }                         from            "./subworkflows/annotation.nf"
include {  SNP_HERITABILITY_ESTIMATION }         from            "./subworkflows/snp_heritability_estimation.nf"

workflow POST_GWAS {
   take:
   genotypeFile
   firth_file

   main:
   ANNOTATION(firth_file)
   SNP_HERITABILITY_ESTIMATION(genotypeFile)
}