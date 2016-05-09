## Stable UltraSeq build from scratch

>https://github.com/flow-r/docker_ultraseq/releases/tag/v0.9.8

Based on Dockerfile: https://github.com/flow-r/docker_ultraseq/blob/c86c252cbfa1b9f06329a067b3fd4cedf9b910c3/Dockerfile

Automated docker image was built at https://hub.docker.com/r/flowrbio/ultraseq/tags/ with docker image id/tag: `flowrbio/ultraseq:0.9.8`.

>`flowrbio/ultraseq:0.9.8` image serves as a base image for `flowrbio/ultraseq:latest` and `flowrbio/ultraseq:devel`

To pull stable docker image, 

```
docker pull flowrbio/ultraseq:0.9.8
```

### latest docker image:
[![Build Status](https://travis-ci.org/flow-r/docker_ultraseq.svg?branch=master)](https://travis-ci.org/flow-r/docker_ultraseq)

```
docker pull flowrbio/ultraseq:latest
```

### devel docker image: 
[![Build Status](https://travis-ci.org/flow-r/docker_ultraseq.svg?branch=devel)](https://travis-ci.org/flow-r/docker_ultraseq) 

```
docker pull flowrbio/ultraseq:devel
```

***

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
