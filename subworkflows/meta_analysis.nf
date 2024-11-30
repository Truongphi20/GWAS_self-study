process MENTAL_ANALYZE {
    container "phinguyen2000/metal:4cb3f16"

    input:
    tuple path(regions_file), path(fusion_result), path(magic_sardinia), path(metal_strucs)

    output:
    path("*.TBL")

    """
    metal $metal_strucs
    """

}


workflow META_ANALYSIS{

    metal_ch = channel.fromPath("$projectDir/GWASTutorial/11_meta_analysis/GlucoseExample/DGI_three_regions.txt")
                      .combine(channel.fromPath("$projectDir/GWASTutorial/11_meta_analysis/GlucoseExample/MAGIC_FUSION_Results.txt.gz"))
                      .combine(channel.fromPath("$projectDir/GWASTutorial/11_meta_analysis/GlucoseExample/magic_SARDINIA.tbl"))
                      .combine(channel.fromPath("$projectDir/GWASTutorial/11_meta_analysis/GlucoseExample/metal.txt"))

    MENTAL_ANALYZE(metal_ch)
}