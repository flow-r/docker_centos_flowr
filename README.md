## Ultraseq Docker Image

Docker container for running Ultraseq - a variant calling pipeline based on GATK best practices to preprocess bams followed by variant calling using MuTect. Docker image does not contain GATK and MuTect softwares as both requires individual license copies. A separate code repository will soon be made available which will use docker ultraseq image to run variant calling using following shell wrapper script:

Docker image is at https://hub.docker.com/r/flowrbio/ultraseq/ with current version:`0.9.9`

### Dry run:

~~~bash
ultraseq.sh \
          -p /scratch/foo/docktest \
          -t tumor.bam \
          -n normal.bam \
          -s samplename \
          -r DRY
~~~

### Actual run:

~~~bash
ultraseq.sh \
          -p /scratch/foo/docktest \
          -t tumor.bam \
          -n normal.bam \
          -s samplename \
          -r GO
~~~

`/scratch/foo/docktest` is a base ultraseq directory which contains code to run pipeline as well as saves output files, including logs.
