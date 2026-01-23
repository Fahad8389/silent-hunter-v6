# Database Information

## Overview

This document describes the databases used in the Silent Hunter v6.0 pipeline for homology searching and verification.

## Primary Databases

### UniRef90

- **Source**: UniProt Reference Clusters
- **URL**: https://www.uniprot.org/uniref/
- **Size**: ~184 million sequences, ~35GB compressed
- **Purpose**: Primary novelty filter
- **Update frequency**: Monthly

UniRef90 clusters UniProt sequences at 90% identity, providing comprehensive coverage while reducing redundancy.

**Download command:**
```bash
wget https://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
diamond makedb --in uniref90.fasta.gz -d uniref90
```

### SwissProt

- **Source**: UniProt/Swiss-Prot (curated)
- **URL**: https://www.uniprot.org/uniprotkb/
- **Size**: ~570,000 sequences, ~300MB
- **Purpose**: High-quality functional annotations
- **Update frequency**: Monthly

SwissProt contains manually curated protein sequences with high-quality annotations.

**Download command:**
```bash
wget https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/swissprot.gz
gunzip swissprot.gz
diamond makedb --in swissprot -d swissprot
```

### Human Reference Proteome

- **Source**: UniProt Reference Proteome
- **Accession**: UP000005640
- **Size**: ~20,000 proteins, ~50MB
- **Purpose**: Contamination screening
- **Update frequency**: Quarterly

Used to identify potential human protein contamination in metagenomic samples.

**Download command:**
```bash
wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz
gunzip UP000005640_9606.fasta.gz
diamond makedb --in UP000005640_9606.fasta -d human
```

## Domain Databases

### Pfam-A

- **Source**: European Bioinformatics Institute
- **URL**: https://www.ebi.ac.uk/interpro/
- **Size**: ~20,000 HMM profiles, ~300MB
- **Purpose**: Domain identification
- **Update frequency**: Annually

Pfam-A contains curated HMM profiles for known protein domain families.

**Download command:**
```bash
wget https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
gunzip Pfam-A.hmm.gz
hmmpress Pfam-A.hmm
```

### TIGRFAM (Optional)

- **Source**: JCVI
- **Size**: ~4,500 HMM profiles, ~50MB
- **Purpose**: Additional domain coverage

## Remote Homology Databases

### HHpred/HHblits Databases

Accessed via web interface at https://toolkit.tuebingen.mpg.de/tools/hhpred

- **PDB_mmCIF70**: Protein structures from PDB clustered at 70%
- **UniRef30**: UniRef clustered at 30% for deep homology detection

## Structural Databases

### Foldseek Databases

Accessed via web interface at https://search.foldseek.com/

- **PDB**: Experimental protein structures
- **AlphaFold DB**: Predicted structures for UniProt proteins
- **ESMAtlas**: ESMFold predictions

## NCBI nr (Spot Check Only)

- **Source**: NCBI
- **URL**: https://www.ncbi.nlm.nih.gov/protein/
- **Size**: ~600 million proteins, ~300GB
- **Purpose**: Final verification (manual spot check)

Too large for Colab; used via web BLAST for random sample verification.

**Web interface:** https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE=Proteins

## ISS Metagenome Organisms

### Expected Organisms in GLDS-69

The ISS metagenome (SRR6356483) contains primarily Earth-derived microorganisms:

| Category | Common Organisms | Relative Abundance |
|----------|------------------|-------------------|
| Bacteria | *Staphylococcus*, *Enterobacter*, *Bacillus*, *Pantoea* | ~80% |
| Fungi | *Aspergillus*, *Penicillium*, *Rhodotorula* | ~15% |
| Archaea | Rare methanogens | <5% |

### Why Novel Proteins from Known Organisms?

1. **Extreme Selection Pressure**: ISS conditions (radiation, microgravity, desiccation) drive rapid adaptation
2. **Horizontal Gene Transfer**: Confined environment promotes gene exchange
3. **Database Bias**: Most databases contain lab/clinical strains, not environmental stress variants
4. **Microbial Dark Matter**: 40-60% of metagenomic proteins have unknown function

## Database Storage Requirements

| Database | Compressed | Uncompressed | DIAMOND Index |
|----------|------------|--------------|---------------|
| UniRef90 | ~35 GB | ~100 GB | ~35 GB |
| SwissProt | ~90 MB | ~300 MB | ~150 MB |
| Human | ~15 MB | ~50 MB | ~30 MB |
| Pfam-A | ~100 MB | ~300 MB | N/A (HMM) |

**Total minimum storage**: ~70 GB for DIAMOND indexes

## Recommended Strategy for Limited Resources

### Colab Pro (100 GB disk)

Run all databases except NCBI nr:
1. UniRef90 (primary) ✅
2. SwissProt (curated) ✅
3. Human (contamination) ✅
4. Pfam (domains) ✅

### Manual Verification

For NCBI nr and structural databases:
1. NCBI BLAST web (10 samples)
2. HHpred web (20 samples)
3. Foldseek web (10 samples)
