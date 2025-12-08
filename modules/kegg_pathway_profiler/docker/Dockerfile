# v2025.12.4
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
# tqdm==4.67.1 scipy==1.16.3 pandas==2.3.3 numpy==2.3.5 networkx==3.6
RUN micromamba install -y -n base -c bioconda -c conda-forge pip python==3.13.10 procps-ng==4.0.4 && \
    micromamba run -n base pip install --no-cache kegg_pathway_profiler==2025.12.4 pyexeggutor && \
    micromamba clean -a -y -f

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
