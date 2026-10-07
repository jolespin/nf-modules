# v2026.10.6
# =================================
FROM mambaorg/micromamba:latest

ARG ENV_NAME

SHELL ["/usr/local/bin/_dockerfile_shell.sh"]

WORKDIR /tmp/

# Data
USER root
RUN mkdir -p /volumes/
RUN mkdir -p /volumes/input
RUN mkdir -p /volumes/output
RUN mkdir -p /volumes/database
RUN mkdir -p /volumes/working

# Retrieve VEBA repository
USER $MAMBA_USER

# Install dependencies
# autocycler + assemblers + supporting tools
RUN micromamba install -y -n base -c bioconda -c conda-forge \
    autocycler==0.8.0 \
    flye==2.9.6 \
    raven-assembler==1.8.3 \
    miniasm==0.3 \
    minipolish==0.2.1 \
    racon==1.5.0 \
    myloasm==0.7.0 \
    metamdbg==1.4 \
    plassembler==1.8.5 \
    minimap2==2.31 \
    samtools==1.24 \
    parallel==20170422 \
    procps-ng==4.0.4 && \
    micromamba clean -a -y -f
# RUN micromamba install -y -n base -c bioconda -c conda-forge \
#     autocycler==0.8.0 \
#     flye \
#     raven-assembler \
#     miniasm \
#     minipolish \
#     racon \
#     myloasm \
#     metamdbg \
#     plassembler \
#     minimap2 \
#     samtools \
#     parallel \
#     procps-ng==4.0.4 && \
#     micromamba clean -a -y -f

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]