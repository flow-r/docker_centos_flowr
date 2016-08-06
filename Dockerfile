############################################################
# Dockerfile to build docker image: flowrbio/ultraseq
############################################################

# Set the base image to flowr on Ubuntu 16.04
# Source: https://raw.githubusercontent.com/flow-r/docker_ultraseq/ultraseq/Dockerfile
# Image at https://hub.docker.com/r/flowrbio/ultraseq/

FROM ubuntu:16.04

## For questions, visit https:
MAINTAINER "Samir B. Amin" <tweet:sbamin; sbamin.com/contact>

LABEL version="1.0-b1" \
	  mode="devp version for GLASS" \	
      description="docker image to run GLASS consortium WGS SNV and SV pipeline" \
      contributor1="flowr and ultraseq variant caller pipeline by Sahil Seth, tweet: sethsa" \
      contributor2="variant calling pipeline code by Hoon Kim, tweet: wisekh6" \
      website="http://glass-consortium.org" \
      code="http://odin.mdacc.tmc.edu/~rverhaak/resources" \
      contact="Dr. Roel GW Verhaak http://odin.mdacc.tmc.edu/~rverhaak/contact/ tweet:roelverhaak" \
      NOTICE="Third party license: Use of GATK and Mutect tools are subject to approval by GATK team at the Broad Institute, Cambridge, MA, USA. This docker image can not be deployed in public prior to getting appropriate licenses from the Broad Institute to use GATK and mutect for use with GLASS consortium related analysis pipelines."

#### Install dependencies, some utilities ####
RUN apt-get update && \
	apt-get install --yes build-essential python-software-properties \
	python-setuptools sudo locales ca-certificates \
	software-properties-common cmake libcurl4-openssl-dev wget curl \
	gdebi tar zip unzip rsync screen nano vim dos2unix bc \ 
 	libxml2-dev libssl-dev && \
	add-apt-repository --yes ppa:git-core/ppa && \
	apt-get update && \
	apt-get install --yes git && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

## overwrite /etc/profile with one having pathmunge function
ADD ./config/profile /etc/

## Configure default locale, Ref.: https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen en_US.utf8 && \
	/usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Create non-root user, glass with passwordless sudo privileges
# http://askubuntu.com/a/574454/52398
RUN useradd -m -d /home/glass -s /bin/bash -c "GLASS User" -U glass && \
	usermod -a -G staff,sudo glass && \
	echo "%sudo  ALL=(ALL) NOPASSWD:ALL" | (EDITOR="tee -a" visudo) && \
	id -a glass

# Install miniconda2 python
RUN mkdir -p /opt && \
	wget --no-check-certificate https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh -O /opt/miniconda.sh && \
	bash /opt/miniconda.sh -b -p /opt/miniconda -f && \
	rm -f /opt/miniconda.sh && \
	echo 'export PATH=/opt/miniconda/bin:$PATH' >> /etc/profile.d/conda.sh

#### Install Java JDK 7 and 8 ####
## https://launchpad.net/~webupd8team/+archive/ubuntu/java

RUN add-apt-repository --yes ppa:webupd8team/java && \
	apt-get update && \
	echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
	apt-get install --yes oracle-java7-installer && \
	echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
	apt-get install --yes oracle-java8-installer && \
	mkdir -p /opt/java && cd /opt/java && \
	ln -s /usr/lib/jvm/java-8-oracle/jre jre8 && \
	ln -s /usr/lib/jvm/java-7-oracle/jre jre7 && \
	apt-get install --yes oracle-java8-set-default && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

#### Set env ####
ENV PATH /opt/miniconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV J2SDKDIR /usr/lib/jvm/java-8-oracle
ENV J2REDIR /usr/lib/jvm/java-8-oracle/jre

## By default, updated java jdk 8 will be set at /usr/java/ and /usr/bin/java. 
## Java 1.7 is required for mutect.

#### Install R ####
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" >> /etc/apt/sources.list && \
	gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
	gpg -a --export E084DAB9 | apt-key add - && \
	apt-get update && \
	apt-get install --yes r-base r-base-dev && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

########## Install flowr ##########
## Install R packages and setup flowr for user: root
RUN mkdir -p /{opt,scratch} && \
	cd /opt && \
	mkdir -p /usr/share/doc/R-3.3.0/html && \
	Rscript -e 'install.packages(c("httr", "git2r", "stringr", "dplyr", "tidyr", "devtools", "params", "flowr", "funr"), repos = c(CRAN="http://cran.rstudio.com"))' && \
	Rscript -e 'devtools::install_github("glass-consortium/ultraseq", subdir = "ultraseq", ref="master")' && \
	mkdir -p /root/bin && \
	Rscript -e 'library(flowr);setup()' && \
	/root/bin/flowr run x=sleep_pipe platform=local execute=TRUE && \
	rm -f /root/Rplots.pdf && \
	ln -s /usr/local/lib/R/site-library/flowr/scripts/flowr /usr/local/bin/flowr

## setup flowr for user: glass
USER glass

RUN mkdir -p /home/glass/bin && \
	Rscript -e 'library(flowr);setup()' && \
	/usr/local/bin/flowr run x=sleep_pipe platform=local execute=TRUE && \
	rm -f /home/glass/Rplots.pdf

USER root
####### flowr setup complete #########

#### Install samtools, bcftools, htslib ####
RUN mkdir -p /opt/samtools && cd /opt/samtools && \
	wget --no-check-certificate https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
	tar xvjf samtools-1.3.1.tar.bz2 && \
	cd samtools-1.3.1 && make && make prefix=/opt/samtools/samtools install && \
	echo 'pathmunge /opt/samtools/samtools/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/samtools/samtools-1.3.1 /opt/samtools/samtools-1.3.1.tar.bz2

RUN cd /opt/samtools && \
	wget --no-check-certificate https://github.com/samtools/bcftools/releases/download/1.3.1/bcftools-1.3.1.tar.bz2 && \
	tar xvjf bcftools-1.3.1.tar.bz2 && \
	cd bcftools-1.3.1 && make && make prefix=/opt/samtools/bcftools install && \
	echo 'pathmunge /opt/samtools/bcftools/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/samtools/bcftools-1.3.1 /opt/samtools/bcftools-1.3.1.tar.bz2

RUN cd /opt/samtools && \
	wget --no-check-certificate https://github.com/samtools/htslib/releases/download/1.3.1/htslib-1.3.1.tar.bz2 && \
	tar xvjf htslib-1.3.1.tar.bz2 && \
	cd htslib-1.3.1 && make && make prefix=/opt/samtools/htslib install && \
	echo 'pathmunge /opt/samtools/htslib/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/samtools/htslib-1.3.1 /opt/samtools/htslib-1.3.1.tar.bz2

#### Install bwa ####
RUN cd /opt && \
	wget --no-check-certificate https://github.com/lh3/bwa/releases/download/v0.7.15/bwakit-0.7.15_x64-linux.tar.bz2 -O bwakit.tar.bz2 && \
	tar xvjf bwakit.tar.bz2 && \
	mv bwa.kit bwa && \
	echo 'pathmunge /opt/bwa after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/bwakit.tar.bz2

#### Install bedtools ####
RUN cd /opt && \
	wget --no-check-certificate https://github.com/arq5x/bedtools2/releases/download/v2.26.0/bedtools-2.26.0.tar.gz -O /opt/bedtools.tar.gz && \
	tar xvzf bedtools.tar.gz && cd /opt/bedtools2 && \
	make && \
	echo 'pathmunge /opt/bedtools2/bin after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/bedtools.tar.gz

#### Install picard ####
RUN mkdir -p /opt/picard && \
	wget --no-check-certificate https://github.com/broadinstitute/picard/releases/download/2.5.0/picard-tools-2.5.0.zip -O /opt/picard2.zip && \
	unzip /opt/picard2.zip -d /opt/picard && cd /opt/picard && \
	ln -s picard-tools-2.5.0 default && \
	echo 'pathmunge /opt/picard/default after' >> /etc/profile.d/ngspaths.sh && \
	rm -rf /opt/picard2.zip

#### rJava R package under Oracle JDK 1.8 ####
RUN R CMD javareconf && \
	Rscript -e 'install.packages("rJava", repos = c(CRAN="http://cran.rstudio.com"))'

## Install bamtools
## Copyright under  MIT License by Derek Barnett, Erik Garrison, Gabor Marth, Michael Stromberg
## https://github.com/pezmaster31/bamtools/wiki/Building-and-installing
RUN cd /opt && \
	git clone git://github.com/pezmaster31/bamtools.git && \
	cd bamtools && \
	git checkout tags/v2.4.0 -b v2.4.0 && \
	mkdir -p build && cd build && \
	cmake .. && make && cd .. && \
	echo 'pathmunge /opt/bamtools/bin after' >> /etc/profile.d/ngspaths.sh

##### IMPORTANT: LICENSE RESTRICTION #####
## Following can not be containerized as they require individual licenses. Use volume mount during docker run.
RUN mkdir -p /opt/{gatk,mutect} && \
	mkdir -p /scratch/bundle && \
	chgrp -R glass /scratch && \
	chmod -R 775 /scratch

# Cleanup
RUN apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# set workdir to /scratch where pipeline code will be cloned
# This requires proper volume mount while running docker run -v flag to allow docker container to see code directory.
WORKDIR /scratch

ENV PATH /opt/miniconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-8-oracle/bin:/usr/lib/jvm/java-8-oracle/db/bin:/usr/lib/jvm/java-8-oracle/jre/bin:/opt/samtools/samtools/bin:/opt/samtools/bcftools/bin:/opt/samtools/htslib/bin:/opt/bwa:/opt/bedtools2/bin:/opt/picard/default:/opt/bamtools/bin

ENTRYPOINT []
CMD []

## END ##
