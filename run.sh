export NXF_LOG_FILE="logs/.nextflow.log"
export NXF_IGNORE_RESUME_HISTORY=true

nextflow run main.nf -resume "0121dd20-0552-4170-a2e0-a993862d07c3" -name "GWAS_TUTORIAL_${BASHPID}"