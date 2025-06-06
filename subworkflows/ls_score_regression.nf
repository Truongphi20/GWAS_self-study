process DOWNLOAD_SUMMARY_STATISTICS{
    tag "$filename"
    container "phinguyen2000/wget:1.21.4"

    input:
    tuple val(filename), val(link)

    output:
    path(filename)

    """
    wget -O $filename $link
    """
}

process DOWNLOAD_REFERENCE_FILES{
    tag "${prefix}${meta.suffix}"
    container "google/cloud-sdk:latest"

    input:
    tuple val(prefix), val(meta)

    output:
    tuple val(prefix), path("ref")

    script:
    if (meta.suffix == '.bz2'){
        unzip_command = "bunzip2 -dk ${prefix}${meta.suffix} && mkdir ref && mv $prefix ref/$prefix"
    } else {
        unzip_command = "mkdir ref && $meta.unzip_command ${prefix}${meta.suffix} -C ref"
    }

    """
    gsutil -u $params.googleProject cp $meta.link .
    $unzip_command
    """
}

def ref_file_map = [
        "w_hm3.snplist": [
            "link": "gs://broad-alkesgroup-public-requester-pays/LDSCORE/w_hm3.snplist.bz2",
            "suffix": ".bz2",
            "unzip_command": "bzip2 -d"],
        "eas_ldscores": [
            "link": "gs://broad-alkesgroup-public-requester-pays/LDSCORE/eas_ldscores.tar.bz2",
            "suffix": ".tar.bz2",
            "unzip_command": "tar -xjvf"],
        "1000G_Phase3_EAS_weights_hm3_no_MHC": [
            "link": "gs://broad-alkesgroup-public-requester-pays/LDSCORE/1000G_Phase3_EAS_weights_hm3_no_MHC.tgz",
            "suffix": ".tgz",
            "unzip_command": "tar -xzvf"],
        "1000G_Phase3_EAS_plinkfiles": [
            "link": "gs://broad-alkesgroup-public-requester-pays/LDSCORE/1000G_Phase3_EAS_plinkfiles.tgz",
            "suffix": ".tgz",
            "unzip_command": "tar -xzvf"],
        "1000G_Phase3_EAS_baseline_v1.2_ldscores": [
            "link": "gs://broad-alkesgroup-public-requester-pays/LDSCORE/1000G_Phase3_EAS_baseline_v1.2_ldscores.tgz",
            "suffix": ".tgz",
            "unzip_command": "tar -xzvf"],
        "Cahoy_EAS_1000Gv3_ldscores": [
            "link": "gs://broad-alkesgroup-public-requester-pays/LDSCORE/LDSC_SEG_ldscores/Cahoy_EAS_1000Gv3_ldscores.tar.gz",
            "suffix": ".tar.gz",
            "unzip_command": "tar -xzvf"]
    ]

process MUNGE_SUMSTATS{
    tag "$prefix"
    container "phinguyen2000/ldsc:85c9dbb"

    input:
    tuple path(sumstats), path(snplist)

    output:
    tuple val(prefix), path("${prefix}.sumstats.gz")

    script:
    prefix = sumstats.toString() - '.txt.gz' 

    """
    munge_sumstats.py \
    --sumstats $sumstats \
    --merge-alleles $snplist/w_hm3.snplist\
    --a1 ALT \
    --a2 REF \
    --chunksize 500000 \
    --out $prefix
    """
}

process LD_SCORE {
    tag "$prefix"
    container "phinguyen2000/ldsc:85c9dbb"

    input:
    tuple val(prefix), path(filtered_sumstats), path(eas_ldscores)

    output:
    tuple val(prefix), path("${prefix}.log")

    """
    ldsc.py \
    --h2 $filtered_sumstats \
    --ref-ld-chr $eas_ldscores/eas_ldscores/ \
    --w-ld-chr $eas_ldscores/eas_ldscores/ \
    --out $prefix
    """
}

process CROSS_LD_SCORE {
    container "phinguyen2000/ldsc:85c9dbb"

    input:
    tuple path(filtered_sumstats), path(eas_ldscores)

    output:
    path("BBJ_HDLC_LDLC.log")

    """
    ldsc.py \
    --rg ${filtered_sumstats.join(",")} \
    --ref-ld-chr $eas_ldscores/eas_ldscores/ \
    --w-ld-chr $eas_ldscores/eas_ldscores/ \
    --out BBJ_HDLC_LDLC
    """
}

process PARTITIONED_LD{
    container "phinguyen2000/ldsc:85c9dbb"

    input:
    tuple path(bbj_hdlc_sumstats), 
            path(baseline, name: 'basename/'), 
            path(eas_plinkfiles, name: 'eas_plinkfiles/'), 
            path(eas_weights, name: 'weight/')

    output:
    path("BBJ_HDLC_baseline.log")

    """
    ldsc.py \
    --h2 $bbj_hdlc_sumstats \
    --overlap-annot \
    --ref-ld-chr $baseline/baseline. \
    --frqfile-chr $eas_plinkfiles/1000G_Phase3_EAS_plinkfiles/1000G.EAS.QC. \
    --w-ld-chr $eas_weights/1000G_Phase3_EAS_weights_hm3_no_MHC/weights.EAS.hm3_noMHC. \
    --out BBJ_HDLC_baseline
    """
}

process CELLTYPE_SPECIFICITY_LD{
    container "phinguyen2000/ldsc:85c9dbb"

    input:
    tuple path(bbj_hdlc_sumstats), 
            path(baseline, name: 'basename/'), 
            path(cahoy_eas, name: 'cahoy_eas/'), 
            path(eas_weights, name: 'weight/')

    output:
    path("BBJ_HDLC_baseline_cts.cell_type_results.txt")

    """
    cp $cahoy_eas/Cahoy_EAS_1000Gv3_ldscores/Cahoy.EAS.ldcts .
    sed -i 's|Cahoy_EAS_1000Gv3_ldscores|$cahoy_eas/Cahoy_EAS_1000Gv3_ldscores|g' Cahoy.EAS.ldcts
    ldsc.py \
        --h2-cts $bbj_hdlc_sumstats \
        --ref-ld-chr-cts Cahoy.EAS.ldcts \
        --ref-ld-chr $baseline/baseline. \
        --w-ld-chr  $eas_weights/1000G_Phase3_EAS_weights_hm3_no_MHC/weights.EAS.hm3_noMHC. \
        --out BBJ_HDLC_baseline_cts
    """
}

workflow LD_SCORE_REGRESSION {

    sumstats_map = [
        "BBJ_LDLC.txt.gz": "http://jenger.riken.jp/61analysisresult_qtl_download/",
        "BBJ_HDLC.txt.gz": "http://jenger.riken.jp/47analysisresult_qtl_download/"
    ]

    DOWNLOAD_SUMMARY_STATISTICS(
        channel.of(*sumstats_map.collect{ [it.key, it.value] })
    )

    DOWNLOAD_REFERENCE_FILES(
        channel.of(*ref_file_map.collect { [it.key, it.value] } )
    )

    MUNGE_SUMSTATS(
        DOWNLOAD_SUMMARY_STATISTICS.out.combine(
            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == 'w_hm3.snplist' }
                                    .map{ it[1] }
        )
    )

    LD_SCORE(
        MUNGE_SUMSTATS.out.combine(
            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == 'eas_ldscores' }
                                    .map{ it[1] }
        )
    )

    CROSS_LD_SCORE(
        MUNGE_SUMSTATS.out.map{it[1]}
                      .flatten().collect().map{[it]}
                      .combine(
                        DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == 'eas_ldscores' }
                                                .map{ it[1] }
                        )
    )

    PARTITIONED_LD(
        MUNGE_SUMSTATS.out.filter{ it[0] == 'BBJ_HDLC' }.map{ it[1] }
                        .combine(
                            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == '1000G_Phase3_EAS_baseline_v1.2_ldscores' }
                                                .map{ it[1] }
                        ).combine(
                            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == '1000G_Phase3_EAS_plinkfiles' }
                                                .map{ it[1] }
                        ).combine(
                            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == '1000G_Phase3_EAS_weights_hm3_no_MHC' }
                                                .map{ it[1] }
                        )
    )

    CELLTYPE_SPECIFICITY_LD(
        MUNGE_SUMSTATS.out.filter{ it[0] == 'BBJ_HDLC' }.map{ it[1] }
                        .combine(
                            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == '1000G_Phase3_EAS_baseline_v1.2_ldscores' }
                                                .map{ it[1] }
                        ).combine(
                            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == 'Cahoy_EAS_1000Gv3_ldscores' }
                                                .map{ it[1] }
                        ).combine(
                            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == '1000G_Phase3_EAS_weights_hm3_no_MHC' }
                                                .map{ it[1] }
                        )
    )

    emit:
    bbj_hdlc_sumstats = DOWNLOAD_SUMMARY_STATISTICS.out.filter{ it.getName() == 'BBJ_HDLC.txt.gz' }
}


