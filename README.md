# TP Bioinformatique — Seance 4 : Analyse CNV et Variants Structuraux

> Travaux pratiques d'analyse de variations du nombre de copies (CNV) et de variants structuraux sur des echantillons tumoraux, dans un environnement Docker Jupyter pre-configure.

**Auteur : Marwa Zidi** — Universite Paris Cite

---

## Description

Ce TP couvre deux analyses bioinformatiques appliquees a des echantillons oncologiques :

- **Partie 1 — FACETS** : Detection de variations du nombre de copies (CNV) et estimation de la purete/ploidie tumorale a partir de fichiers BAM apparies (tumeur / remission).
- **Partie 2 — FiLT3r** : Detection d'un variant structural (duplication interne en tandem du gene FLT3) a partir de donnees de sequencage.

---

## Acces a l'environnement

L'environnement de TP est disponible en ligne via l'infrastructure Docker de l'Universite Paris Cite :

**[Lancer l'environnement Jupyter](https://mydocker.universite-paris-saclay.fr/course/6f0c1159-74fa-4b24-a54c-5fe6a4f82448/magic-link)**

> Aucune installation locale necessaire. L'environnement inclut R 4.4, Python 3, et tous les outils NGS pre-installes.

---

## Structure des notebooks

| # | Notebook | Description | Mode |
|---|----------|-------------|------|
| 1 | `facets_cnv.ipynb` | Analyse CNV avec cnv_facets.R — case1 et case2 | Correction |
| 2 | `facets_cnv_exercice.ipynb` | Memes analyses avec cellules a completer | Exercice |
| 3 | `filt3r.ipynb` | Detection de variant structural FLT3-ITD avec FiLT3r | Correction |
| 4 | `filt3r_exercice.ipynb` | Meme analyse avec commandes a completer | Exercice |

### Progression recommandee

```
facets_cnv_exercice  →  facets_cnv       (correction)
filt3r_exercice      →  filt3r           (correction)
```

---

## Arborescence des donnees

```
/root/tp_seance4/
├── facets/
│   ├── case1/
│   │   ├── bam_tumor/        ADN449-67_processed.bam
│   │   ├── bam_remission/    ADN452-75_processed.bam
│   │   └── results/          (resultats generes)
│   ├── case2/
│   │   ├── bam_tumor/        424-96_processed.bam
│   │   ├── bam_remission/    (utilise celui du case1)
│   │   └── results/          (resultats generes)
│   ├── ref_snp/              dbsnp_138.hg19.vcf.gz
│   └── ref_bed/              panel_hg19_ref.bed
└── filt3r/
    ├── flt3_dna.bam
    ├── flt3_dna.bai
    ├── flt3_dna_R1.fastq.gz
    ├── flt3_dna_R2.fastq.gz
    └── flt3_exon14_15_hg38.fa
```

---

## Outils et environnement

### Outils bioinformatiques
- **cnv_facets.R** (v0.16.0) — Detection de CNV somatiques, estimation de purete et ploidie
- **snp-pileup** — Comptage d'alleles aux positions SNP (etape interne a cnv_facets)
- **FiLT3r** — Detection de variants structuraux par approche k-mer
- **samtools** (v1.18) — Indexation et manipulation de fichiers BAM

### Packages R
- **facets** (v0.5.14) — Algorithme central d'analyse CNV
- **Rsamtools** — Lecture de fichiers BAM depuis R
- **ggplot2, dplyr, tidyr** — Manipulation et visualisation

### Librairies Python
- `pandas`, `numpy`, `matplotlib`, `seaborn`
- `pysam` — Interface Python pour SAMtools

---

## Partie 1 — Analyse CNV avec FACETS

### Principe

FACETS analyse les variations du nombre de copies en comparant le profil allelique d'une tumeur a son echantillon normal apparie. Il estime :
- les segments genomiques gains/pertes
- la purete tumorale (fraction de cellules tumorales)
- la ploidie globale

### Etapes du TP

1. Navigation dans l'arborescence et reperage des fichiers
2. Indexation des fichiers BAM avec `samtools index`
3. Decouverte des arguments de `cnv_facets.R`
4. Lancement de l'analyse sur le **case1** (echantillon apparie)
5. Lancement de l'analyse sur le **case2** (option `--unmatched`)
6. Interpretation des fichiers de sortie (`.png`, `.vcf`, `.csv.gz`)

### Commande principale

```bash
Rscript cnv_facets.R \
    -t tumor.bam \
    -n normal.bam \
    -vcf dbsnp.vcf.gz \
    -T targets.bed \
    -g hg19 \
    -mq 20 -bq 20 \
    -o output_prefix
```

---

## Partie 2 — Detection de variant structural avec FiLT3r

### Principe

FiLT3r detecte les variants structuraux (duplications en tandem, inversions) par une approche basee sur les k-mers. Il filtre les reads contenant des sequences aberrantes par rapport a une reference.

Le gene **FLT3** (Fms-Like Tyrosine kinase 3) presente frequemment des duplications internes en tandem (ITD) dans les leucemies aiguës myeloblastiques (LAM), constituant un marqueur pronostique important.

### Etapes du TP

1. Navigation vers le repertoire `filt3r/`
2. Identification des fichiers disponibles
3. Decouverte des parametres de `filt3r`
4. Lancement de l'analyse sur les reads paired-end
5. Interpretation du fichier VCF de sortie
6. Indexation du BAM et visualisation dans IGV

### Commande principale

```bash
filt3r \
    --ref flt3_exon14_15_hg38.fa \
    -k 12 \
    --sequences R1.fastq.gz,R2.fastq.gz \
    --out results \
    --vcf
```

---

## Objectifs pedagogiques

A l'issue de ce TP, l'etudiant sera capable de :

- Comprendre le principe de l'analyse CNV par sequencage apparie tumeur/normal
- Utiliser cnv_facets.R pour detecter des gains et pertes chromosomiques
- Interpreter les graphiques de sortie FACETS (log ratio, BAF)
- Comprendre la notion d'echantillon non-apparie (option `--unmatched`)
- Utiliser FiLT3r pour detecter une duplication interne en tandem
- Visualiser un variant structural dans IGV

---

## References

- FACETS : [github.com/mskcc/facets](https://github.com/mskcc/facets) — Shen & Seshan (2016) *Nucleic Acids Research*
- cnv_facets : [github.com/dariober/cnv_facets](https://github.com/dariober/cnv_facets)
- FiLT3r : [gitlab.univ-lille.fr/filt3r/filt3r](https://gitlab.univ-lille.fr/filt3r/filt3r)
- Samtools : [htslib.org](http://www.htslib.org/)

---

## Licence

Ce materiel pedagogique est distribue a des fins educatives dans le cadre des enseignements de bioinformatique de l'Universite Paris Cite.
