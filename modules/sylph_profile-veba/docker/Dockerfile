# v2026.1.19
# =================================
FROM mambaorg/micromamba:latest

ARG MAMBA_DOCKERFILE_ACTIVATE=1

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

# Copy directory
COPY --chown=$MAMBA_USER:$MAMBA_USER ./bin/ ./bin/

# Install dependencies
RUN micromamba install -y -n base -c bioconda -c conda-forge sylph==0.9.0 'pandas>=2' procps-ng==4.0.4 && \ 
    micromamba clean -a -y -f

# Add additional scripts to environment bin
RUN install -m 775 ./bin/*.py \
                   /opt/conda/bin/

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
