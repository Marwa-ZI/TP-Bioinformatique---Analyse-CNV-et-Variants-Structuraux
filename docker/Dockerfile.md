# ============================================================================
# Dockerfile COMPLET - Environnement Bioinformatique Production
# R 4.4 + Structure TP + Tous les outils
# Auteur: Marwa ZIDI
# ============================================================================

FROM ubuntu:22.04

# Variables d'environnement
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=fr_FR.UTF-8
ENV LC_ALL=fr_FR.UTF-8
ENV TZ=Europe/Paris

# ============================================================================
# 1. INSTALLATION DES OUTILS DE BASE
# ============================================================================
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    curl \
    wget \
    git \
    rsync \
    build-essential \
    gcc-11 \
    g++-11 \
    cmake \
    locales \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libncurses5-dev \
    vim \
    nano \
    tree \
    htop \
    tmux \
    less \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen fr_FR.UTF-8

# Fix timezone
RUN mkdir -p /var/db/timezone && ln -sf /etc/localtime /var/db/timezone/localtime

# ============================================================================
# 2. NODE.JS + PYTHON + JUPYTER
# ============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs

RUN pip3 install --upgrade pip setuptools wheel
RUN npm install -g configurable-http-proxy
RUN pip3 install jupyterlab notebook

# Packages Python scientifiques
RUN pip3 install \
    biopython \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    scipy \
    pysam \
    scikit-learn \
    plotly \
    logomaker

# Extensions JupyterLab
RUN pip3 install \
    nbgitpuller \
    jupyter-archive \
    jupyterlab-git \
    jupyterlab-language-pack-fr-FR \
    jupyterlab-search-replace \
    jupyter-resource-usage \
    jupytext \
    jupyterlab-myst \
    jupyterlab-slideshow \
    nglview \
    nbgrader \
    ruff \
    jupyterlab-lsp \
    'python-lsp-server[all]' \
    jupyterlab_code_formatter \
    black \
    isort

# ============================================================================
# 3. MINIFORGE
# ============================================================================
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm /tmp/miniforge.sh

ENV PATH="/opt/conda/bin:${PATH}"

RUN conda config --remove channels defaults || true && \
    conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda config --set channel_priority flexible

# ============================================================================
# 4. R 4.4 + PACKAGES VIA CONDA
# ============================================================================
RUN conda install -y \
    r-base=4.4 \
    r-irkernel \
    r-devtools \
    r-ggplot2 \
    r-dplyr \
    r-tidyr \
    r-readr \
    r-data.table \
    && conda clean -afy

# Configurer IRkernel
RUN R -e "IRkernel::installspec(user = FALSE)"

# Vérifier devtools
RUN R -e "if (!requireNamespace('devtools', quietly=TRUE)) stop('devtools not installed'); cat('✅ devtools version', as.character(packageVersion('devtools')), '\n')"

# ============================================================================
# 5. PACKAGES R SUPPLÉMENTAIRES
# ============================================================================

# NETTOYER l'environnement conda (évite les corruptions)
RUN conda clean -afy || true && \
    rm -rf /opt/conda/conda-meta/.wh.* || true && \
    conda info

# Installer Rsamtools via CONDA (plus fiable que BiocManager pour R 4.4)
# CRITIQUE : Rsamtools est ESSENTIEL pour FACETS
RUN conda install -y -c bioconda bioconductor-rsamtools && conda clean -afy

# VÉRIFICATION CRITIQUE : Rsamtools DOIT être installé
RUN R -e "if (!requireNamespace('Rsamtools', quietly=FALSE)) { cat('\n❌ ERREUR CRITIQUE: Rsamtools non installé!\n'); quit(status=1) } else { cat('✅ Rsamtools version', as.character(packageVersion('Rsamtools')), 'installé avec succès\n') }"

# BiocManager pour les autres packages
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org/')"

# Vérifier la version de BiocManager
RUN R -e "cat('BiocManager version:', as.character(packageVersion('BiocManager')), '\n')"

# Autres packages Bioconductor (optionnels)
RUN R -e "BiocManager::install('pctGCdata', ask=FALSE, update=FALSE)" || true

# Packages GitHub
RUN R -e "devtools::install_github('trevorld/argparse', ref='v1.1.1')"
RUN R -e "devtools::install_github('mskcc/facets', ref='434b5ce')"

# Packages CRAN supplémentaires
RUN R -e "install.packages(c('testthat', 'covr', 'gridExtra', 'knitr', 'rmarkdown', 'roxygen2'), repos='https://cloud.r-project.org/')"

# ============================================================================
# 6. COMPILATION DE SAMTOOLS, BCFTOOLS, SNP-PILEUP
# ============================================================================

RUN mkdir -p /tmp/biotools && cd /tmp/biotools

# samtools
RUN cd /tmp/biotools && \
    wget -q https://github.com/samtools/samtools/releases/download/1.18/samtools-1.18.tar.bz2 && \
    tar xf samtools-1.18.tar.bz2 && \
    cd samtools-1.18 && \
    ./configure --prefix=/usr/local && \
    make -j 4 && \
    make install && \
    cd /tmp/biotools && \
    rm -rf samtools-1.18*

# bcftools
RUN cd /tmp/biotools && \
    wget -q https://github.com/samtools/bcftools/releases/download/1.18/bcftools-1.18.tar.bz2 && \
    tar xf bcftools-1.18.tar.bz2 && \
    cd bcftools-1.18 && \
    ./configure --prefix=/usr/local && \
    make -j 4 && \
    make install && \
    cd /tmp/biotools && \
    rm -rf bcftools-1.18*

# htslib
RUN cd /tmp/biotools && \
    wget -q https://github.com/samtools/htslib/releases/download/1.18/htslib-1.18.tar.bz2 && \
    tar xf htslib-1.18.tar.bz2 && \
    cd htslib-1.18 && \
    ./configure --prefix=/usr/local && \
    make -j 4 && \
    make install && \
    cd /tmp/biotools && \
    rm -rf htslib-1.18*

# snp-pileup
RUN cd /tmp/biotools && \
    git clone https://github.com/mskcc/facets.git && \
    cd facets/inst/extcode && \
    g++ -std=c++11 -I/usr/local/include snp-pileup.cpp -L/usr/local/lib -lhts -o snp-pileup -lcurl -lz -lpthread -lcrypto -llzma -lbz2 && \
    cp snp-pileup /usr/local/bin/ && \
    chmod +x /usr/local/bin/snp-pileup

# cnv_facets.R
RUN cd /tmp/biotools && \
    git clone https://github.com/dariober/cnv_facets.git && \
    cd cnv_facets && \
    chmod +x bin/cnv_facets.R && \
    cp bin/cnv_facets.R /usr/local/bin/ && \
    cd /tmp && \
    rm -rf /tmp/biotools

# ============================================================================
# 7. STAR-FUSION 
# ============================================================================

# Installer STAR-Fusion
RUN conda install -y star-fusion && conda clean -afy

# ============================================================================
# 8. FILT3R
# ============================================================================
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100

RUN cd /opt && \
    git clone https://gitlab.univ-lille.fr/filt3r/filt3r.git && \
    cd filt3r && \
    make gatb && \
    make && \
    cp filt3r /usr/local/bin/

# ============================================================================
# 9. OUTILS NGS SUPPLÉMENTAIRES
# ============================================================================
RUN apt-get update && apt-get install -y \
    bedtools \
    bowtie2 \
    bwa \
    fastqc \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# 10. CRÉATION DE LA STRUCTURE TP
# ============================================================================

# Créer l'arborescence complète pour les TPs
RUN mkdir -p /root/tp_seance4/facets/case1/bam_tumor && \
    mkdir -p /root/tp_seance4/facets/case1/bam_remission && \
    mkdir -p /root/tp_seance4/facets/case1/results && \
    mkdir -p /root/tp_seance4/facets/case2/bam_tumor && \
    mkdir -p /root/tp_seance4/facets/case2/bam_remission && \
    mkdir -p /root/tp_seance4/facets/case2/results && \
    mkdir -p /root/tp_seance4/facets/ref_snp && \
    mkdir -p /root/tp_seance4/facets/ref_bed && \
    mkdir -p /root/tp_seance4/filt3r && \
    mkdir -p /root/tp_seance4/star_fusion && \
    mkdir -p /root/notebooks && \
    mkdir -p /root/data && \
    mkdir -p /root/results


# 🎓 Environnement Bioinformatique - Analyse CNV et Variants

Bienvenue dans votre environnement d'analyse bioinformatique !


## 🔧 Outils disponibles

### Python
- **Biopython** : Analyse de séquences biologiques
- **numpy, pandas** : Manipulation de données
- **matplotlib, seaborn** : Visualisation
- **pysam** : Manipulation de fichiers NGS
- **scikit-learn** : Machine learning
- **plotly** : Graphiques interactifs

### R (version 4.4)
- **devtools** : Développement R
- **tidyverse** : ggplot2, dplyr, tidyr, readr
- **Rsamtools** : Manipulation BAM/SAM
- **facets** : Analyse CNV
- **argparse** : Arguments ligne de commande
- **data.table** : Manipulation efficace de données
- **knitr, rmarkdown** : Rapports

### Outils bioinformatiques
- **cnv_facets.R** : Analyse de variations du nombre de copies
- **snp-pileup** : Comptage d'allèles aux positions SNP
- **STAR-Fusion** : Détection de gènes de fusion
- **FiLT3r** : Filtrage de variants
- **samtools** : Manipulation BAM/SAM (v1.18)
- **bcftools** : Manipulation VCF/BCF (v1.18)
- **bedtools** : Opérations sur régions génomiques
- **bwa** : Alignement de séquences
- **fastqc** : Contrôle qualité NGS

## 🚀 Commandes utiles

### Afficher les informations sur l'environnement
```bash
info_env
```

### Tester les outils bioinformatiques
```bash
# FACETS
cnv_facets.R
snp-pileup --help

# Alignement et manipulation
samtools --version
bcftools --version
bwa

# Autres
STAR-Fusion --version
filt3r --help 2>&1 | head -5
fastqc --version
bedtools --version
```

### Vérifier les packages R
```bash
R -e "library(Rsamtools); library(facets); library(devtools)"
```

### Afficher l'arborescence
```bash
tree /root/tp_seance4 -L 2
```

### Lister les kernels Jupyter
```bash
jupyter kernelspec list
```

## 📚 Ressources

### Documentation
- **FACETS** : https://github.com/mskcc/facets
- **cnv_facets** : https://github.com/dariober/cnv_facets
- **Samtools** : http://www.htslib.org/
- **STAR-Fusion** : https://github.com/STAR-Fusion/STAR-Fusion
- **Bioconductor** : https://bioconductor.org/

### Articles scientifiques
- FACETS : Shen & Seshan (2016) Nucleic Acids Research
- STAR-Fusion : Haas et al. (2019) Genome Biology

## 💡 Conseils

1. **Organisation** : Utilisez la structure de répertoires fournie
2. **Documentation** : Documentez vos analyses dans des notebooks
3. **Vérification** : Vérifiez toujours vos données d'entrée
4. **Sauvegarde** : Sauvegardez régulièrement vos résultats

## 🆘 En cas de problème

1. Vérifiez que tous les outils sont installés : `info_env`
2. Vérifiez les versions : `<outil> --version`
3. Consultez les logs de Jupyter Lab
4. Vérifiez la documentation en ligne

Bon travail ! 🧬
EOF

# ============================================================================
# 11. VÉRIFICATIONS COMPLÈTES
# ============================================================================
RUN echo "============================================================" && \
    echo "VÉRIFICATIONS FINALES" && \
    echo "============================================================" && \
    python3 --version && \
    echo "" && \
    R --version | head -n 1 && \
    echo "" && \
    echo "Kernels Jupyter:" && \
    jupyter kernelspec list && \
    echo "" && \
    echo "Outils bioinformatiques:" && \
    which cnv_facets.R && echo "  ✅ cnv_facets.R" && \
    which snp-pileup && echo "  ✅ snp-pileup" && \
    which STAR-Fusion && echo "  ✅ STAR-Fusion" && \
    which prep_genome_lib.pl && echo "  ✅ prep_genome_lib.pl" && \
    which filt3r && echo "  ✅ filt3r" && \
    which samtools && echo "  ✅ samtools" && \
    which bcftools && echo "  ✅ bcftools" && \
    which bedtools && echo "  ✅ bedtools" && \
    which bwa && echo "  ✅ bwa" && \
    which fastqc && echo "  ✅ fastqc" && \
    echo "" && \
    echo "Packages R:" && \
    R --vanilla --quiet -e "packages <- c('devtools', 'Rsamtools', 'data.table', 'ggplot2', 'dplyr', 'tidyr', 'readr', 'facets', 'argparse', 'IRkernel', 'knitr', 'rmarkdown'); for (pkg in packages) { if (pkg %in% installed.packages()[,1]) { cat('  ✅', pkg, '\n') } else { cat('  ❌', pkg, '\n') } }" && \
    echo "" && \
    echo "Structure TP:" && \
    tree /root/tp_seance4 -L 2 2>/dev/null || ls -la /root/tp_seance4/ && \
    echo "" && \
    echo "============================================================" && \
    echo "✅ ENVIRONNEMENT PRÊT POUR LES ÉTUDIANTS ✅" && \
    echo "============================================================"

# ============================================================================
# 12. COMMANDE INFO_ENV
# ============================================================================
RUN cat > /usr/local/bin/info_env << 'EOF'
#!/bin/bash
cat << 'BANNER'
============================================================
        🧬 PLATEFORME JUPYTER BIOINFORMATIQUE 🧬
============================================================

📦 Environnement complet pour l'analyse NGS

🔬 Outils installés :
   • Python 3.12 + JupyterLab
   • R 4.4 + devtools + tidyverse + Rsamtools
   • cnv_facets.R + snp-pileup (FACETS)
   • STAR-Fusion + prep_genome_lib.pl (fusions de gènes)
   • FiLT3r (filtrage variants)
   • samtools, bcftools (v1.18)
   • bedtools, bwa, fastqc

📁 Structure des TPs :
   /root/tp_seance4/
   ├── facets/    (Analyse CNV)
   │   ├── case1/ (Échantillon 1)
   │   ├── case2/ (Échantillon 2)
   │   ├── ref_snp/ (Références SNP)
   │   └── ref_bed/ (Régions cibles)
   └── filt3r/    (Filtrage variants)

Vos notebooks :
   /root/notebooks/

Tests rapides :
   cnv_facets.R
   snp-pileup --help
   R -e "library(Rsamtools); library(facets)"
   samtools --version

Documentation :
   cat /root/README.md

============================================================
Environnement prêt ! Bon travail ! 🚀
============================================================
BANNER
EOF
RUN chmod +x /usr/local/bin/info_env

# ============================================================================
# 13. WRAPPER + ENTRYPOINT
# ============================================================================
COPY wrapper_script.sh /usr/local/lib/wrapper_script.sh
RUN chmod +x /usr/local/lib/wrapper_script.sh

WORKDIR /root
EXPOSE 8888
ENTRYPOINT ["/bin/bash", "/usr/local/lib/wrapper_script.sh"]
