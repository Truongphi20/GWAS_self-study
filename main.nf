process TEST{
    container "phinguyen2000/multiqc:5da6a92"

    publishDir 'data/',  mode: 'copy', overwrite: true
    
    input:
    val string

    output:
    path "a.txt"

    """
    echo $string > a.txt
    multiqc --help >> a.txt
    """
}


workflow {
    TEST(channel.of("phine"))
}