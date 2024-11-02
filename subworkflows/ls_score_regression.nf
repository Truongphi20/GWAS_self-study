process DOWNLOAD_SUMMARY_STATISTICS{
    container "phinguyen2000/wget:1.21.4"

    output:
    path("BBJ_LDLC.txt.gz"),        emit: BBJ_LDLC
    path("BBJ_HDLC.txt.gz"),        emit: BBJ_HDLC

    """
    wget -O BBJ_LDLC.txt.gz http://jenger.riken.jp/61analysisresult_qtl_download/
    wget -O BBJ_HDLC.txt.gz http://jenger.riken.jp/47analysisresult_qtl_download/
    """
}

process DOWNLOAD_REFERENCE_FILES{
    tag "${prefix}${meta.suffix}"
    container "google/cloud-sdk:latest"

    input:
    tuple val(prefix), val(meta)

    output:
    tuple val(prefix), val(meta), path("${prefix}${meta.suffix}")

    """
    gsutil -u $params.googleProject cp $meta.link .
    """
}

process UNZIP_REFERENCE_FILES{
    tag "${prefix}${meta.suffix}"
    container "phinguyen2000/unzip:318d185"

    input:
    tuple val(prefix), val(meta), path(ref_file)

    output:
    tuple val(prefix), path(prefix)

    """
    mkdir $prefix
    $meta.unzip_command $ref_file -C $prefix
    """
}


workflow LD_SCORE_REGRESSION {
    DOWNLOAD_SUMMARY_STATISTICS()

    ref_file_map = [
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

    DOWNLOAD_REFERENCE_FILES(
        channel.of(*ref_file_map.collect { [it.key, it.value] } )
    )

    UNZIP_REFERENCE_FILES(
        DOWNLOAD_REFERENCE_FILES.out
    )


}