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
RUN micromamba install -y -n base -c bioconda -c conda-forge metaeuk==6.a5d39d9 barrnap==0.9 trnascan-se==2.0.12 pyrodigal==3.6.3.post1 tiara==1.0.3 seqkit==2.10.1 pandas procps-ng==4.0.4 && \ 
    micromamba run -n base pip install --no-cache genopype==2023.5.15 soothsayer_utils==2022.6.24 && \
    micromamba clean -a -y -f

# Add additional scripts to environment bin
RUN cp -rf ./bin/LICENSE /opt/conda/bin/ 
RUN cp -rf ./bin/append_geneid_to_barrnap_gff.py
RUN cp -rf ./bin/append_geneid_to_prodigal_gff.py
RUN cp -rf ./bin/compile_metaeuk_identifiers.py
RUN cp -rf ./bin/eukaryotic_gene_modeling_wrapper.py
RUN cp -rf ./bin/partition_gene_models.py
RUN cp -rf ./bin/partition_organelle_sequences.py


ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
