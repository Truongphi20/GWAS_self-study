# How to run the workflow?

- Step 1: Following the [Nextflow instruction][1] to set up credentials for GCloud Batch.
- Step 2: Set up GCloud configs for your GCloud in `nextflow.config` file.
- Step 3: Remove `-resume` parameter in [`run.sh` file][2]
- Step 4: Install Nextflow 24.04.4 by conda.
  ```
  conda create -n nextflow bioconda::nextflow=24.04.4
  conda activate nextflow
  ```
- Step 5: Run workflow `bash run.sh`.


[1]: https://www.nextflow.io/docs/latest/google.html#credentials
[2]: https://github.com/Truongphi20/GWAS_self-study/blob/84cd25276efb2e94776444b0312459c5cfbf205d/run.sh#L4
