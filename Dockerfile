############################################################
# Dockerfile to build docker image: dyndna/glass_mutect
############################################################

# Set the base image to flowr on centos:6.6
# Source: https://github.com/flow-r/docker_centos_flowr

FROM centos:6.6

## For questions, visit https:
MAINTAINER "Samir B. Amin" <tweet:sbamin; sbamin.com/contact>

LABEL version="0.9.7" \
	  mode="in-house beta version" \	
      description="docker image to run GLASS consortium variant calling pipeline" \
      contributor1="flowr and ultraseq pipeline by Sahil Seth, tweet: sethsa" \
      contributor2="variant calling pipeline code by Hoon Kim, tweet: wisekh6" \
      website="http://glass-consortium.org" \
      code="http://odin.mdacc.tmc.edu/~rverhaak/resources" \
      contact="Dr. Roel GW Verhaak http://odin.mdacc.tmc.edu/~rverhaak/contact/ tweet:roelverhaak" \
      NOTICE="Third party license: Use of GATK and Mutect tools are subject to approval by GATK team at the Broad Institute, Cambridge, MA, USA. This docker image can not be deployed in public prior to getting appropriate licenses from the Broad Institute to use GATK and mutect for use with GLASS consortium related analysis pipelines."

## Install and update EPEL repository ##
### Use HTTP rather than HTTPS: To avoid error like, Cannot retrieve metalink for repository epel.

RUN yum install -y epel-release && sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
RUN yum update -y && yum install -y \
	sshfs rsync nano screen socat dos2unix bc \
	wget curl \
	zip unzip \
	openssl098e openssl-devel libcurl-devel libssh2-devel \
	java-1.8.0-openjdk-devel \
	R

# Install devp tools
RUN yum groupinstall -y development && yum install -y \
	zlib-dev xz-libs bzip2-devel ncurses-devel ncurses \
	sqlite-devel ftp

# Install flowr
RUN mkdir -p /{opt,scratch} && cd /opt/ && mkdir -p /usr/share/doc/R-3.2.3/html

RUN Rscript -e 'install.packages(c("httr", "git2r", "stringr", "dplyr", "tidyr", "devtools", "flowr"), repos = c(CRAN="http://cran.rstudio.com", DRAT="http://sahilseth.github.io/drat"))' && mkdir -p /root/bin && Rscript -e 'library(flowr);setup()'

RUN ln -s /root/bin/flowr /usr/bin/flowr && \
	Rscript -e 'devtools::install_github("flow-r/ultraseq", subdir = "ultraseq")' && \
	flowr run x=sleep_pipe platform=local execute=TRUE

# Install miniconda python 2.7
RUN wget --no-check-certificate http://repo.continuum.io/miniconda/Miniconda3-3.7.0-Linux-x86_64.sh -O /opt/miniconda.sh && \
	bash /opt/miniconda.sh -b -p /opt/miniconda -f && \
	rm -f /opt/miniconda.sh && \
	echo 'export PATH=/opt/miniconda/bin:$PATH' >> /etc/profile.d/conda.sh

# Install samtools, bcftools, htslib
RUN mkdir -p /opt/samtools && cd /opt/samtools && \
	wget --no-check-certificate https://github.com/samtools/samtools/releases/download/1.3/samtools-1.3.tar.bz2 && \
	tar xvjf samtools-1.3.tar.bz2 && \
	cd samtools-1.3 && make && make prefix=/opt/samtools/samtools install && \
	echo 'pathmunge /opt/samtools/samtools/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/samtools/samtools-1.3 /opt/samtools/samtools-1.3.tar.bz2

RUN cd /opt/samtools && \
	wget --no-check-certificate https://github.com/samtools/bcftools/releases/download/1.3/bcftools-1.3.tar.bz2 && \
	tar xvjf bcftools-1.3.tar.bz2 && \
	cd bcftools-1.3 && make && make prefix=/opt/samtools/bcftools install && \
	echo 'pathmunge /opt/samtools/bcftools/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/samtools/bcftools-1.3 /opt/samtools/bcftools-1.3.tar.bz2

RUN cd /opt/samtools && \
	wget --no-check-certificate https://github.com/samtools/htslib/releases/download/1.3/htslib-1.3.tar.bz2 && \
	tar xvjf htslib-1.3.tar.bz2 && \
	cd htslib-1.3 && make && make prefix=/opt/samtools/htslib install && \
	echo 'pathmunge /opt/samtools/htslib/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/samtools/htslib-1.3 /opt/samtools/htslib-1.3.tar.bz2

# Install genetorrent

RUN cd /opt && \
	wget --no-check-certificate https://cghub.ucsc.edu/software/downloads/GeneTorrent/3.8.7/GeneTorrent-common-3.8.7-11.207.el6.x86_64.rpm -O /opt/gt-common.rpm && \
	wget --no-check-certificate https://cghub.ucsc.edu/software/downloads/GeneTorrent/3.8.7/GeneTorrent-download-3.8.7-11.207.el6.x86_64.rpm -O /opt/gt-download.rpm && \
	yum --nogpgcheck localinstall -y gt-common.rpm gt-download.rpm && \
	rm -f gt-common.rpm gt-download.rpm

# Install bwa

RUN cd /opt && \
	wget --no-check-certificate https://github.com/lh3/bwa/releases/download/v0.7.13/bwakit-0.7.13_x64-linux.tar.bz2 -O bwakit.tar.bz2 && \
	tar xvjf bwakit.tar.bz2 && \
	echo 'pathmunge /opt/bwa.kit after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/bwakit.tar.bz2

# Install bedtools

RUN cd /opt && \
	wget --no-check-certificate https://github.com/arq5x/bedtools2/releases/download/v2.25.0/bedtools-2.25.0.tar.gz -O /opt/bedtools.tar.gz && \
	tar xvzf bedtools.tar.gz && cd /opt/bedtools2 && \
	make && \
	echo 'pathmunge /opt/bedtools2/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/bedtools.tar.gz

# Install Oracle Java followed by GATK, Picard tools, and rJava package.

RUN cd /opt && \
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u77-b03/jdk-8u77-linux-x64.rpm" && \
	yum --nogpgcheck localinstall -y jdk-8u77-linux-x64.rpm && \
	rm -f jdk-8u77-linux-x64.rpm

RUN cd /opt && \
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm" && \
	yum --nogpgcheck localinstall -y jdk-7u79-linux-x64.rpm && \
	rm -f jdk-7u79-linux-x64.rpm && \
	cd /usr/java && \
	ln -s jdk1.7.0_79 old

## PS: By default, updated java jdk 8 will be set at /usr/java/ and /usr/bin/java. Java 1.7 is required for mutect.

RUN mkdir -p /opt/picard && \
	wget --no-check-certificate https://github.com/broadinstitute/picard/releases/download/2.1.1/picard-tools-2.1.1.zip -O /opt/picard2.zip && \
	unzip /opt/picard2.zip -d /opt/picard && cd /opt/picard && \
	ln -s picard-tools-2.1.1 default && \
	echo 'pathmunge /opt/picard/default after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/picard2.zip

# Install/Update rJava R package to link to Oracle JDK 1.8 over open-jdk 1.6
RUN R CMD javareconf && \
	Rscript -e 'install.packages("rJava", repos = c(CRAN="http://cran.rstudio.com", DRAT="http://sahilseth.github.io/drat"))'

## Install bamtools
## Copyright under  MIT License by Derek Barnett, Erik Garrison, Gabor Marth, Michael Stromberg
## https://github.com/pezmaster31/bamtools/wiki/Building-and-installing
RUN yum install -y cmake && \
		cd /opt && \
		git clone git://github.com/pezmaster31/bamtools.git && \
		cd bamtools && \
		mkdir p build && cd build && \
		cmake .. && make && cd .. && \
		echo 'pathmunge /opt/bamtools/bin after' >> /etc/profile.d/ngspaths.sh

#### Pending ####

# Add /licenses.txt to include respective licenses from above software developers.

##### IMPORTANT: LICENSE RESTRICTION #####
## Following can not be containerized as they require individual licenses. Use volume mount during docker run.
RUN mkdir -p /opt/{gatk,mutect,bundle}

# Cleanup
RUN yum clean all

# set workdir to flowr volumne mounted directory
# This requires proper volume mount while running docker run -v flag to allow docker container to see flowr directory.
WORKDIR /scratch/docker_mutect/flowr

ENV PATH /opt/miniconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/samtools/samtools/bin:/opt/samtools/bcftools/bin:/opt/samtools/htslib/bin:/opt/bwa.kit:/opt/bedtools2/bin:/opt/picard/default:/opt/gatk:/opt/mutect

ENTRYPOINT []
CMD []

## END ##

