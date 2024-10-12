include {  ANNOTATION  }           from            "./subworkflows/annotation.nf"

workflow POST_GWAS {
   take:
   firth_file

   main:
   ANNOTATION(firth_file)
}