# v2025.9.19
# =================================
FROM mambaorg/micromamba:latest

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
RUN micromamba install -y -n base -c bioconda -c conda-forge tiara==1.0.3 pandas scipy procps-ng==4.0.4 && \ 
    micromamba clean -a -y -f

# Add additional scripts to environment bin
RUN cp -rf ./bin/consensus_domain_classification.py /opt/conda/bin/ 


ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
