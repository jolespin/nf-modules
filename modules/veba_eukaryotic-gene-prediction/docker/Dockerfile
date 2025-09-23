# v2025.9.22
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
RUN micromamba install -y -n base -c bioconda -c conda-forge metaeuk==7.bba0d80 barrnap==0.9 trnascan-se==2.0.12 pyrodigal==3.6.3.post1 seqkit==2.10.1 procps-ng==4.0.4 python==3.10.14  biopython==1.85 && \
    micromamba run -n base pip install --no-cache genopype==2023.5.15 soothsayer_utils==2022.6.24 https://github.com/jolespin/tiara-nal/archive/refs/tags/1.0.4rc3.tar.gz && \
    micromamba clean -a -y -f

# Add additional scripts to environment bin
RUN cp -rf ./bin/LICENSE /opt/conda/bin/ && \
    cp -rf ./bin/*.py /opt/conda/bin/ && \
    chmod +x /opt/conda/bin/*.py


ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]