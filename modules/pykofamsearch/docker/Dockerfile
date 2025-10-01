# v2025.9.5
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

# Install dependencies
RUN micromamba install -y -n base -c bioconda -c conda-forge pip tqdm biopython pandas requests 'pyhmmer>=0.10.12,<0.11.0' procps-ng==4.0.4 && \
    micromamba run -n base pip install --no-deps --no-cache pykofamsearch==2025.9.5 && \
    micromamba clean -a -y -f

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
