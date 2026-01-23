# Silent Hunter v6.0

**100% Data Publication Pipeline for ISS Metagenome Novel Protein Discovery**

---

## ⚠️ CORE RULES (FAHDYCONX)

```
╔════════════════════════════════════════════════════════════════╗
║  RULE #1: NO FABRICATION, NO FAKE DATA                         ║
║  - Every number must come from actual command output           ║
║  - No estimates presented as real data                         ║
║  - If uncertain, mark as "TBD"                                 ║
╠════════════════════════════════════════════════════════════════╣
║  RULE #2: DOCUMENT EVERY TRANSITION                            ║
║  - Record INPUT → PROCESS → OUTPUT for each step              ║
║  - Explain WHY numbers change between steps                    ║
║  - See FAHDYCONX.md for transition log template               ║
╠════════════════════════════════════════════════════════════════╣
║  RULE #3: READ TOOL DOCS BEFORE USE                           ║
║  - Understand what the tool does                               ║
║  - Understand parameters before running                        ║
║  - Document tool version and settings used                     ║
╚════════════════════════════════════════════════════════════════╝
```

See **[FAHDYCONX.md](FAHDYCONX.md)** for full documentation system.

---

## Overview

Silent Hunter v6.0 is a comprehensive bioinformatics pipeline for discovering novel proteins from the International Space Station (ISS) metagenome. This pipeline processes 100% of the data from NASA GeneLab GLDS-69 (SRR6356483) with publication-ready methodology and full audit trails.

## Key Features

- **Complete Data Processing**: Analyzes 100% of ISS metagenome data (no downsampling)
- **Multi-Database Search**: UniRef90, SwissProt, Human proteome
- **Novel Protein Classification**: Types A-E based on sequence and structural homology
- **Full Audit Trail**: Every command, timestamp, and checksum logged
- **NASA Recommendations**: Includes chimera detection, Pfam search, and structural validation

## Pipeline Steps

```
Step 1: Data Acquisition (fastq-dump)
    ↓
Step 2: Quality Control (fastp)
    ↓
Step 3: Metagenomic Assembly (MEGAHIT)
    ↓
Step 4: ORF Prediction (Prodigal)
    ↓
Step 5: Homology Search (DIAMOND + VSEARCH)
    ↓
Step 6: Quality Filtering (Python)
    ↓
Step 7: Verification Suite (Python + Manual)
    ↓
Output: Classified Novel Proteins
```

## Directory Structure

```
silent-hunter-v6/
├── README.md                    # This file
├── METHODS.md                   # Publication methods section
├── LICENSE
├── .gitignore
│
├── pipeline/                    # All scripts
│   ├── 01_download.sh
│   ├── 02_qc.sh
│   ├── 03_assembly.sh
│   ├── 04_orf_prediction.sh
│   ├── 05_homology_search.sh
│   ├── 06_quality_filter.py
│   ├── 07_verification.py
│   └── run_all.sh              # Master script
│
├── config/                      # Parameters
│   ├── parameters.sh           # Shell configuration
│   └── parameters.yaml         # YAML documentation
│
├── audit/                       # Full audit trail
│   ├── commands.log            # Every command run
│   ├── checksums.md5           # File integrity
│   └── timestamps.log          # When each step ran
│
├── results/                     # Final outputs
│   ├── novel_proteins.faa
│   ├── verification_report.md
│   └── figures/
│
└── docs/                        # Documentation
    ├── flowchart.md
    └── database_info.md
```

## Quick Start

### Prerequisites

- Python 3.8+
- SRA Toolkit (fastq-dump)
- fastp
- MEGAHIT
- Prodigal
- DIAMOND
- VSEARCH (optional, for chimera detection)

### Running the Pipeline

```bash
# Clone the repository
git clone https://github.com/yourusername/silent-hunter-v6.git
cd silent-hunter-v6

# Configure paths (edit config/parameters.sh)
export BASE_DIR="/path/to/your/data"

# Run the full pipeline
./pipeline/run_all.sh

# Or run from a specific step
./pipeline/run_all.sh --start-from 5
```

### Google Colab

For users without local compute resources, use the provided Colab notebook:

1. Open `SilentHunter_v6.ipynb` in Google Colab
2. Connect to a GPU runtime (Colab Pro recommended)
3. Mount Google Drive
4. Run cells sequentially

## Novel Protein Classification

Proteins are classified into five types based on verification results:

| Type | Description | Expected % |
|------|-------------|------------|
| **Type A** | Completely novel (no seq/struct match) | 10-20% |
| **Type B** | Structure-known (Foldseek match) | 20-30% |
| **Type C** | Remote homolog (HHblits match) | 30-40% |
| **Type D** | Domain hybrid (Pfam domains) | 10-15% |
| **Type E** | Possible artifact | 5-10% |

## Verification Tests

1. **Human Contamination**: Screen against human proteome
2. **AA Composition**: Chi-squared test vs expected frequencies
3. **Protein Classification**: Detect low-complexity and artifacts
4. **Chimera Detection**: VSEARCH UCHIME
5. **Pfam Domain Search**: hmmscan against Pfam-A
6. **Remote Homology**: HHblits/HHpred (manual sampling)
7. **Structural Similarity**: ESMFold + Foldseek (manual sampling)
8. **Genomic Context**: Check for isolated ORFs

## Expected Results

| Metric | 40% Data | 100% Data (Expected) |
|--------|----------|----------------------|
| Total contigs | 44,023 | 80,000-120,000 |
| N50 | 720 bp | 1,000-1,500 bp |
| Total ORFs | ~40,000 | ~80,000-100,000 |
| Novel (pre-filter) | 10,061 | ~20,000-25,000 |
| **Truly novel** | **1,161** | **~2,500-3,500** |

## Data Source

- **Dataset**: NASA GeneLab GLDS-69
- **Accession**: SRR6356483
- **Sample**: ISS environmental surfaces (Node 1, Node 3)
- **Dominant organisms**: *Staphylococcus*, *Enterobacter*, *Bacillus*, *Aspergillus*

## Citation

If you use this pipeline, please cite:

```
[Your paper citation here]
```

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- NASA GeneLab for providing ISS metagenome data
- UniProt for UniRef90 and SwissProt databases
- MEGAHIT, Prodigal, DIAMOND, and VSEARCH developers
