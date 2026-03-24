#!/bin/bash
# ============================================================================
# Wrapper script - Environnement Bioinformatique
# Outils: cnv_facets, STAR-Fusion, FiLT3r, R via Jupyter
# Auteur: Marwa ZIDI
# ============================================================================

USER=$1
PASSWORD=$2

echo "=========================================="
echo "DEBUT DU SCRIPT - $(date)"
echo "=========================================="

set -e

# ============================================================================
# VÉRIFICATION DES OUTILS INSTALLÉS
# ============================================================================
echo ""
echo "🔍 Vérification des outils bioinformatiques..."
echo ""

echo "--- Python et Jupyter ---"
python3 --version
jupyter --version | head -n 1

echo ""
echo "--- Biopython ---"
python3 -c "import Bio; print('✓ Biopython version:', Bio.__version__)" || echo "⚠️  Biopython non disponible"

echo ""
echo "--- R ---"
if command -v R &> /dev/null; then
    echo "✓ R trouvé: $(which R)"
    R --version | head -n 1
    echo ""
    echo "Vérification des packages R critiques..."
    R --vanilla --quiet -e "
    packages <- c('devtools', 'Rsamtools', 'facets', 'argparse', 'ggplot2', 'dplyr')
    all_ok <- TRUE
    for (pkg in packages) {
        if (requireNamespace(pkg, quietly=TRUE)) {
            cat('  ✓', pkg, '\n')
        } else {
            cat('  ✗', pkg, 'MANQUANT\n')
            all_ok <- FALSE
        }
    }
    if (all_ok) {
        cat('\n✅ Tous les packages R sont installés\n')
    } else {
        cat('\n⚠️  Certains packages R sont manquants\n')
    }
    "
else
    echo "⚠️  R non trouvé"
fi

echo ""
echo "--- Kernels Jupyter ---"
jupyter kernelspec list | head -n 10

echo ""
echo "--- cnv_facets ---"
if command -v cnv_facets.R &> /dev/null; then
    echo "✓ cnv_facets.R trouvé: $(which cnv_facets.R)"
else
    echo "⚠️  cnv_facets.R non trouvé"
fi

echo ""
echo "--- snp-pileup ---"
if command -v snp-pileup &> /dev/null; then
    echo "✓ snp-pileup trouvé: $(which snp-pileup)"
else
    echo "⚠️  snp-pileup non trouvé"
fi

echo ""
echo "--- STAR-Fusion ---"
if command -v STAR-Fusion &> /dev/null; then
    echo "✓ STAR-Fusion trouvé: $(which STAR-Fusion)"
    STAR-Fusion --version 2>&1 | head -n 1 || true
else
    echo "⚠️  STAR-Fusion non trouvé"
fi

echo ""
echo "--- FiLT3r ---"
if command -v filt3r &> /dev/null; then
    echo "✓ filt3r trouvé: $(which filt3r)"
else
    echo "⚠️  filt3r non trouvé"
fi

echo ""
echo "--- Autres outils NGS ---"
echo -n "samtools: " && which samtools && echo -n "  Version: " && samtools --version | head -n 1
echo -n "bcftools: " && which bcftools && echo -n "  Version: " && bcftools --version | head -n 1
echo -n "bedtools: " && which bedtools && echo -n "  Version: " && bedtools --version
echo -n "bwa: " && which bwa && echo -n "  Version: " && bwa 2>&1 | grep Version || true
echo -n "fastqc: " && which fastqc && echo -n "  Version: " && fastqc --version

echo ""
echo "=========================================="
echo "Tous les outils ont été vérifiés"
echo "=========================================="

# ============================================================================
# AFFICHAGE DE LA STRUCTURE TP
# ============================================================================
echo ""
echo "📁 Structure des TPs:"
echo ""
tree /root/tp_seance4 -L 2 2>/dev/null || ls -la /root/tp_seance4/
echo ""

# ============================================================================
# MESSAGE D'ACCUEIL
# ============================================================================
echo ""
cat << 'EOF'
============================================================
🧬 PLATEFORME JUPYTER BIOINFORMATIQUE 🧬
============================================================

📦 Environnement prêt pour l'analyse CNV et variants

🔬 Commandes utiles :
   • info_env          : Afficher les infos
   • cat /root/README.md : Documentation complète

📁 Vos données :
   • /root/tp_seance4/facets/  : Analyse CNV
   • /root/tp_seance4/filt3r/  : Filtrage variants
   • /root/notebooks/          : Vos notebooks

🧪 Tests rapides :
   • cnv_facets.R
   • snp-pileup --help
   • R -e "library(Rsamtools); library(facets)"

============================================================
EOF

# ============================================================================
# DÉMARRAGE JUPYTER LAB
# ============================================================================
echo ""
echo "📓 Lancement de Jupyter Lab..."
echo "=========================================="

cd /root
pwd
whoami

# Lancer Jupyter Lab SANS mot de passe (accès par token)
exec jupyter lab \
    --allow-root \
    --no-browser \
    --ip="0.0.0.0" \
    --port=8888 \
    --IdentityProvider.token='' \
    --ServerApp.password='' \
    --ServerApp.shutdown_no_activity_timeout=1200 \
    --MappingKernelManager.cull_idle_timeout=1200 \
    --TerminalManager.cull_inactive_timeout=1200
