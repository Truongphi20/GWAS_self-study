process DOWNLOAD_DATABASE{
    container "phinguyen2000/annovar:39a4446"
    disk '50 GB'
    tag "$protocol"

    input:
    val(protocol)

    output:
    path("hg19_*")

    """
    annotate_variation.pl -buildver hg19 -downdb -webfrom annovar $protocol .
    """
}

process ANNOVAR_ANNOTATION{
    container "phinguyen2000/annovar:39a4446"

    input:
    tuple path(annovar_input), path(databases)

    output:
    path("add_db*")

    """
    table_annovar.pl \
            ${annovar_input} \
            . \
            -buildver hg19 \
            -protocol refGene,avsnp150,clinvar_20200316,gnomad211_exome \
            -operation g,f,f,f \
            -polish\
            -remove \
            -out add_db \
            -vcfinput
    """
}



workflow ADDITIONAL_DATABASE{

    take:
    annovar_input

    main:
    protocols_ch = channel.of("refGene", "avsnp150", "clinvar_20200316", "gnomad211_exome")

    DOWNLOAD_DATABASE(protocols_ch)

    databases = DOWNLOAD_DATABASE.out.flatten().collect(sort: true).map{[it]}

    // ANNOVAR_ANNOTATION(
    //     annovar_input.combine(databases)
    // )
}