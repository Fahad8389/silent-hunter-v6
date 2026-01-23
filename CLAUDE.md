# CLAUDE.md - Project Context for Silent Hunter v6.0

## Project Overview

**Goal:** Discover novel proteins from ISS metagenome data (NASA GLDS-69)
**Target:** bioRxiv preprint publication
**Approach:** 100% data processing with full audit trail

## CRITICAL RULES (FAHDYCONX)

```
1. NO FABRICATION, NO FAKE DATA - Every number must be real
2. DOCUMENT EVERY TRANSITION - Input → Process → Output + WHY
3. READ TOOL DOCS BEFORE USE - Understand before running
```

See `FAHDYCONX.md` for full documentation system.

## Current Status

**Date:** 2025-01-23

### Completed
- [x] Pipeline scripts created (01-07 + run_all.sh)
- [x] Configuration files (parameters.sh, parameters.yaml)
- [x] Documentation (README.md, METHODS.md, FAHDYCONX.md)
- [x] Google Colab notebook (SilentHunter_v6.ipynb)
- [x] GitHub repo created: https://github.com/Fahad8389/silent-hunter-v6

### Data Downloaded
- [x] SRR6356483 (ISS raw data) - 4.5 GB at `~/silent-hunter-downloads/`
- [x] uniref90.fasta.gz - 35 GB on Google Drive

### Pending Downloads (quick, do on Colab)
- [ ] SwissProt (~90 MB)
- [ ] Human proteome (~15 MB)
- [ ] Pfam-A.hmm (~300 MB)

### Next Steps
1. Upload SRR6356483 to Google Drive
2. Run Colab notebook
3. Fill in FAHDYCONX.md transition log as pipeline runs
4. Complete manual verification steps (HHblits, Foldseek)

## File Locations

### Local (Mac)
```
~/silent-hunter-v6/           # Pipeline code (GitHub repo)
~/silent-hunter-downloads/    # Downloaded data
  └── SRR6356483             # 4.5 GB ISS raw data
```

### Google Drive
```
MyDrive/SilentHunter_v6/
├── databases/
│   └── uniref90.fasta.gz    # 35 GB (already there)
├── data/                     # Upload SRR6356483 here
├── intermediate/             # Pipeline creates this
├── output/                   # Final results
└── audit/                    # Logs and checksums
```

## Pipeline Overview

```
Step 1: Download (SRA → FASTQ)
Step 2: QC (fastp)
Step 3: Assembly (MEGAHIT)
Step 4: ORF Prediction (Prodigal)
Step 5: Homology Search (DIAMOND vs UniRef90, SwissProt, Human)
Step 5B: Taxonomic Classification (Kraken2/CAT/DIAMOND-LCA)
Step 6: Quality Filter (Python)
Step 7: Verification (Python + Manual)
Step 8: Final Table (protein + organism + classification)
```

## Final Output Table Format

```
novel_proteins_annotated.tsv columns:
| protein_id | contig_id | organism | classification | length_aa | mw_kda | sequence |
```

Each protein tagged with:
- **Microbial source** (which organism it came from)
- **Classification** (Type A-E)
- **Properties** (length, molecular weight)

## Expected Results

| Metric | Expected |
|--------|----------|
| Total contigs | 80,000-120,000 |
| Total ORFs | 80,000-100,000 |
| Novel (pre-filter) | 20,000-25,000 |
| Truly novel | 2,500-3,500 |

## Novel Protein Classification

- **Type A:** Completely novel (no seq/struct match) - 10-20%
- **Type B:** Structure-known (Foldseek match) - 20-30%
- **Type C:** Remote homolog (HHblits match) - 30-40%
- **Type D:** Domain hybrid (Pfam domains) - 10-15%
- **Type E:** Artifact (remove) - 5-10%

## Key Files

| File | Purpose |
|------|---------|
| `FAHDYCONX.md` | Transition documentation log |
| `SilentHunter_v6.ipynb` | Main Colab notebook |
| `pipeline/run_all.sh` | Master pipeline script |
| `config/parameters.yaml` | All parameters documented |
| `METHODS.md` | Publication-ready methods |

## Commands Reference

```bash
# Run full pipeline (local)
cd ~/silent-hunter-v6
export BASE_DIR="/path/to/data"
./pipeline/run_all.sh

# Push updates to GitHub
cd ~/silent-hunter-v6
git add -A && git commit -m "message" && git push
```

## Notes

- User prefers to download data directly (not through Colab) for verification
- ISS organisms are mostly known Earth bacteria (Staphylococcus, Bacillus, etc.)
- "Novel" means not in databases, NOT alien proteins
- 25% identity threshold is the "twilight zone" - conservative definition of novelty
