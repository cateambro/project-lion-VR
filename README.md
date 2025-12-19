# project-lion-VR
Codes for comparative analysis of metagenomic assembly - Lion VR thesis
# Lion Microbiome Assembly - Comparative Analysis Pipeline
Nextflow pipeline for comparative metagenomic assembly analysis of the gut microbiome of the African lion (*Panthera leo*).
## Description

This repository contains the codes used in the thesis “Lion VR” to compare three metagenomic assembly approaches:
- **metaFlye** v2.9 - long-read assembly
- **metaSPAdes** v4.0 - hybrid assembly
- **OPERA-MS** v0.9.0 - hybrid assembly with clustering

## Repository Structure
```
workflows/          Main Nextflow pipelines
  ├── scripttot.nf         Quality control and assembly (metaFlye, metaSPAdes, OPERA-MS)
  └── fullcomparison.nf    BLAST comparative analysis

modules/            Reusable Nextflow modules
  ├── blastdb.nf           BLAST database creation
  ├── blastcomparison.nf   BLAST sequence comparison
  └── overlapanalysis.nf   Overlap metric calculation

scripts/            Analysis scripts
  └── python_analysis.py   Quantitative overlap analysis
```
## Software Requirements

- Nextflow v25.04
- fastplong v0.2.2 (quality control long reads)
- fastp v0.24.1 (quality control short reads)
- metaFlye v2.9
- metaSPAdes v4.0
- OPERA-MS v0.9.0
- BLAST+ v2.12.0
- Python 3.9+ with standard libraries
- seqtk (for contig length extraction)

## Usage

### 1. Quality Control and Assembly
```bash
nextflow run workflows/scripttot.nf \
  --lr_input  \
  --sr_input  \
  --quality 13
```

### 2. Comparative Analysis
```bash
nextflow run workflows/fullcomparison.nf \
  --opera  \
  --flye  \
  --spades 
```
## Output

- **Quality Control**: clean reads in FASTQ format
- **Assembly**: assembled contigs for each method
- **BLAST Comparison**: overlap metrics (overlap_mb, ratio%, identity%)

## Citation

If you use this code, please cite:
```
Ambrosi, C. (2025). Lion VR - Comparative Metagenomic Assembly Analysis 
of African Lion Gut Microbiome. [Thesis].
```

## Author

**Caterina Ambrosi**  
University of Verona. 
