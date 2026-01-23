# Methods

## Publication-Ready Methods Section

### Data acquisition

Metagenomic sequencing data from the International Space Station (ISS) environmental surfaces was obtained from NASA GeneLab (GLDS-69, accession SRR6356483). Raw paired-end reads totaling 6.24 GB were downloaded using SRA Toolkit v3.0. The ISS microbiome samples were collected from Node 1 and Node 3 surfaces and are dominated by human-associated bacteria (*Staphylococcus*, *Enterobacter*, *Bacillus*, *Pantoea*) and environmental fungi (*Aspergillus*, *Penicillium*, *Rhodotorula*).

### Quality control and assembly

Reads were quality-filtered using fastp v0.23 with parameters: automatic adapter detection for paired-end reads, sliding window quality trimming (window size=4, mean quality=20), and minimum length filtering (50 bp). Quality metrics including read survival rate, Q20/Q30 scores, and adapter content were recorded. Filtered reads were assembled using MEGAHIT v1.2.9 with k-mer range 21-141 (step size 12) and minimum contig length 500 bp. Assembly quality was assessed by N50, total assembly size, and contig count.

### Chimera detection

Chimeric sequences, which represent assembly artifacts from misjoined reads, were detected using VSEARCH v2.22 with the UCHIME de novo algorithm. Identified chimeras were flagged and removed from downstream analysis to prevent false positive novel protein predictions.

### Protein prediction

Open reading frames (ORFs) were predicted from assembled contigs using Prodigal v2.6.3 in metagenomic mode (-p meta). Both protein sequences (.faa) and nucleotide sequences (.fna) were generated, along with GFF annotations recording ORF completeness (partial/complete), strand, and coordinates.

### Multi-database homology search

Predicted proteins were searched against multiple reference databases using DIAMOND v2.1 blastp with 25% minimum identity threshold and e-value cutoff of 1e-5 in sensitive mode:

1. **UniRef90** (184 million clustered sequences) - Primary novelty filter
2. **SwissProt** (570,000 curated sequences) - High-quality functional annotations
3. **Human reference proteome** (UP000005640, ~20,000 proteins) - Contamination screening with relaxed thresholds (50% identity, e-value 1e-10)

The 25% identity threshold represents the "twilight zone" below which sequence similarity cannot be distinguished from random chance, providing a conservative definition of novelty.

### Domain identification

Predicted proteins were searched against the Pfam-A database using hmmscan (HMMER v3.3) to identify known protein domains. Proteins containing recognizable Pfam domains in novel arrangements were classified as Type D (domain hybrids) rather than completely novel.

### Quality filtering

Novel protein candidates (no significant matches in any database) were filtered based on the following quality criteria:
- Minimum length: 100 amino acids
- Start codon: Must begin with methionine (M)
- Internal stop codons: None permitted
- ORF completeness: Only complete ORFs (partial=00 in Prodigal output)

### Verification suite

Multi-level verification was performed to assess the validity of novel protein candidates:

1. **Human contamination screening**: Proteins matching the human proteome at ≥50% identity were flagged as potential contamination.

2. **Amino acid composition analysis**: Chi-squared test comparing observed amino acid frequencies to expected UniProt averages. Proteins with chi-squared >0.3 were flagged for abnormal composition.

3. **Sequence-based artifact detection**: Proteins were screened for:
   - Repetitive sequences (≥5 consecutive identical amino acids)
   - Extreme hydrophobicity (>60% hydrophobic residues)
   - Extreme charge (>40% charged residues)
   - Low complexity (any single amino acid >30% of sequence)

4. **Genomic context analysis**: ORFs isolated on very short contigs (<500 bp) or representing the only predicted gene on their contig were flagged as lower confidence.

5. **Remote homology sampling**: A random sample of 20 proteins was analyzed using HHpred (MPI Bioinformatics Toolkit) against PDB_mmCIF70 and UniRef30 databases to detect distant evolutionary relationships undetectable by DIAMOND.

6. **Structural similarity sampling**: A random sample of 10 proteins was analyzed by:
   - Structure prediction using ESMFold (Meta AI)
   - Structural similarity search using Foldseek against PDB and AlphaFold databases

   Proteins with structural matches but no sequence matches were classified as Type B (convergent evolution to known folds).

### Novel protein classification

Final novel proteins were classified into five categories based on verification results:

| Type | Definition | Criteria |
|------|------------|----------|
| Type A | Completely novel | No sequence OR structure homology detected |
| Type B | Structure-known | Novel sequence but structural match via Foldseek |
| Type C | Remote homolog | Detected by HHblits/HHpred but not DIAMOND |
| Type D | Domain hybrid | Contains known Pfam domains in novel arrangement |
| Type E | Possible artifact | Chimeric, low-complexity, isolated, or flagged by multiple tests |

### Audit trail

Complete reproducibility was ensured through:
- Logging of all commands with timestamps
- MD5 checksums for all input and output files
- Version recording for all software tools
- Parameter documentation in YAML format

### Software versions

- SRA Toolkit: 3.0
- fastp: 0.23
- MEGAHIT: 1.2.9
- Prodigal: 2.6.3
- DIAMOND: 2.1
- VSEARCH: 2.22
- HMMER: 3.3
- Python: 3.8+

### Data availability

Raw sequencing data is available from NCBI SRA (SRR6356483) and NASA GeneLab (GLDS-69). Analysis scripts and parameters are available at [GitHub repository URL]. Novel protein sequences are deposited at [repository/accession].
