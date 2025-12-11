# v2025.12.11
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
RUN micromamba install -y -n base -c bioconda -c conda-forge antismash==8.0.4 biopython tqdm 'pandas>=2' procps-ng==4.0.4 && \ 
    micromamba clean -a -y -f

# Add additional scripts to environment bin
RUN cp -rf ./bin/biosynthetic_genbanks_to_table.py /opt/conda/bin/ 
RUN cp -rf ./bin/compile_protein_cluster_prevalence_table.py /opt/conda/bin/ 

# The following section is regarding caching and permission issues:
# https://github.com/nf-core/modules/blob/master/modules/nf-core/antismash/README.md
## Speeds up slightly builds: https://github.com/antismash/antismash/issues/837#issuecomment-2893858536
## From: https://github.com/antismash/containers/blob/main/standalone-lite/Dockerfile#L25
# ENV PYTHON="/opt/conda/bin/python3"
RUN mkdir -p /tmp/matplotlib && MPLCONFIGDIR=/tmp/matplotlib python -c "import matplotlib.pyplot as plt" && chmod -R a+rw /tmp/matplotlib

# Download the antiSMASH database, needed for the prepare-data process
# Prepare the antiSMASH cache and other bits it needs to run properly
# Remove the databases to reduce the container size
RUN download-antismash-databases && \
    antismash --prepare-data && \
    antismash --check-prereqs && \
    rm -rf /opt/conda/lib/python*/site-packages/antismash/databases

RUN PYTHON_VERSION=$(python -c "import sys; print(f'python{sys.version_info.major}.{sys.version_info.minor}')") && \
    python -c "from antismash.modules.nrps_pks import prepare_data; prepare_data()" && \
    cp /opt/conda/lib/${PYTHON_VERSION}/site-packages/antismash/modules/nrps_pks/data/terminals/*.brawn_cache \
       /opt/conda/lib/${PYTHON_VERSION}/site-packages/antismash/modules/nrps_pks/data/
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
