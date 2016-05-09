#!/usr/bin/env cwl-runner

class: CommandLineTool
description: "A Docker container for variant calling pipeline based on GATK best practices and MuTect. See [flowR-ultraseq](https://github.com/flow-r/docker_ultraseq) website for more information."
id: "ultraseq"
label: "UltraSeq by flowR"

dct:creator:
- class: foaf:Organization
  foaf:name: "Genomic Medicine at the UT MD Anderson Cancer Center"
  foaf:member:
  - class: foaf:Person
    id: "https://orcid.org/0000-0002-3207-9505"
    foaf:name: Samir B. Amin
    foaf:mbox: "mailto:sbamin@outlook.com"
  foaf:member:
  - class: foaf:Person
    id: "http://orcid.org/0000-0003-4579-3959"
    foaf:name: Sahil Seth
    foaf:mbox: "mailto:sethsahil1@gmail.com"
  foaf:member:
  - class: foaf:Person
    id: "http://odin.mdacc.tmc.edu/~rverhaak/people/h_kim/"
    foaf:name: Hoon Kim
    foaf:mbox: "mailto:hkim6@mdanderson.org"

requirements:
  - class: DockerRequirement
    dockerPull: "docker pull flowrbio/ultraseq:0.9.7"

hints:
  - class: ResourceRequirement
    coresMin: 8
    ramMin: 16000
    outdirMin: 512000
    description: "pipeline requires a docker enabled compute node with at least 8 cores, 16G of RAM and 500 GB of disk space."
