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
RUN micromamba install -y -n base -c bioconda -c conda-forge \
    dnaapler==1.4.0 \
    seqkit==2.14.0 \
    procps-ng==4.0.4 && \
    micromamba clean -a -y -f

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]