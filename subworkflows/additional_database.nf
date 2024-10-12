process DOWNLOAD_DATABASE{
    container "phinguyen2000/annovar:39a4446"
    machineType 'z3-highmem-88'

    storeDir "gs://phi-nextflow-bucket/store_files"

    output:
    path("humandb/")

    """
    annotate_variation.pl -buildver hg19 -downdb -webfrom annovar avsnp150 ./humandb/
    """
}

process ANNOVAR_ANNOTATION{
    container "phinguyen2000/annovar:39a4446"

    input:
    tuple path(annovar_input), path(humandb)

    output:
    path("add_db*")

    """
    table_annovar.pl \
            ${annovar_input} \
            ${humandb} \
            -buildver hg19 \
            -protocol refGene,avsnp150,clinvar_20200316,gnomad211_exome \
            -operation g,f,f,f \
            -remove \
            -out add_db \ 
            -vcfinput
    """
}



workflow ADDITIONAL_DATABASE{

    take:
    annovar_input

    main:
    DOWNLOAD_DATABASE()
    ANNOVAR_ANNOTATION(
        annovar_input.combine(DOWNLOAD_DATABASE.out)
    )
}