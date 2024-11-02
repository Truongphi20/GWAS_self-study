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
    tuple val(prefix), val(meta), path("${prefix}${meta.suffix}")

    """
    gsutil -u $params.googleProject cp $meta.link .
    """
}

def ref_file_map = [
        "eas_ldscores": [
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

process UNZIP_REFERENCE_FILES{
    tag "${prefix}${meta.suffix}"
    container "phinguyen2000/unzip:318d185"

    input:
    tuple val(prefix), val(meta), path(ref_file)

    output:
    tuple val(prefix), path(prefix)

    """
    if [[ $meta.suffix == '.bz2' ]]; then
        bunzip2 $ref_file
    else
        mkdir $prefix && $meta.unzip_command $ref_file -C $prefix
    fi
    """
}

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
    --merge-alleles $snplist \
    --a1 ALT \
    --a2 REF \
    --chunksize 500000 \
    --out $prefix
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

    UNZIP_REFERENCE_FILES(
        DOWNLOAD_REFERENCE_FILES.out
    )

    MUNGE_SUMSTATS(
        DOWNLOAD_SUMMARY_STATISTICS.out.combine(
            DOWNLOAD_REFERENCE_FILES.out.filter{ it[0] == 'w_hm3.snplist' }
                                    .map{ it[2] }
        )
    )


}


