process FORMAT_INPUT_ANNOVAR{
    container "ubuntu:22.04"

    input:
    path(firth_file)

    output:
    path("annovar_input.txt")

    """
    awk 'NR>1 && NR<100000 {print \$1,\$2,\$2,\$4,\$5}' $firth_file > annovar_input.txt
    """
}

process ANNOVAR_ANNOTATION{
    container "phinguyen2000/annovar:39a4446"

    input:
    path(annovar_input)

    output:
    path("myannotation.hg19_multianno.txt")

    """
    table_annovar.pl \
                ${annovar_input} \
                /src/annovar/humandb \
                -buildver hg19 \
                -out myannotation \
                -remove \
                -protocol refGene \
                -operation g \
                -nastring . \
                -polish
    """
}


workflow POST_GWAS {
   take:
   firth_file

   main:
   FORMAT_INPUT_ANNOVAR(firth_file)
   ANNOVAR_ANNOTATION(FORMAT_INPUT_ANNOVAR.out)


}