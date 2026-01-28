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

**Date:** 2026-01-28

### Session 1 (Lost - Colab timeout)
- Completed Steps 1-5A but all local files lost

### Session 2 (2026-01-27)
- Step 1: 40,440,324 paired-end reads (downloaded FASTQ from ENA - bypassed SRA Toolkit)
- Step 2: 79,292,500 reads after QC (98% survival)
- Step 3: 312,714 contigs assembled (N50=1,731 bp)
- Step 4: 447,912 proteins predicted (208,501 complete ORFs)
- Step 5A: UniRef90 database built (184M proteins) - BUT .dmnd saved as 0 bytes on Drive AGAIN
- Step 5B: DIAMOND search ran ~10/33 blocks (--sensitive mode), then cell crashed due to log_command() NameError, output file lost
- **Intermediate files for Steps 1-4 saved to Drive successfully**

### Session 3 (2026-01-28)
- Attempted to resume Step 5B but uniref90.dmnd was 0 bytes on Drive
- Started rebuilding database DIRECTLY on Drive (to avoid 0-byte copy issue)
- Session ended before completion (compute units running low)

### Data on Google Drive (VERIFIED 2026-01-28)
```
MyDrive/SilentHunter_v6/
├── uniref90.fasta.gz              # 43 GB ✅
├── SRR6356483                     # 4.5 GB ✅
├── databases/
│   └── uniref90.dmnd              # 0 bytes ❌ BROKEN - MUST REBUILD
├── intermediate/
│   ├── assembly/                  # ✅ saved
│   ├── clean_1.fastq.gz           # 2.8 GB ✅
│   ├── clean_2.fastq.gz           # 3.3 GB ✅
│   ├── orfs/                      # ✅ saved
│   └── proteins.faa               # 94 MB ✅
├── output/                        # empty
└── audit/                         # empty
```

### Lessons Learned
1. **SAVE TO DRIVE AFTER EVERY STEP** - Colab local storage is temporary!
2. SRA Toolkit is unreliable in Colab - download FASTQ directly from ENA instead
3. **Copying large files (84GB .dmnd) to Drive with !cp FAILS silently** - always verify size after copy
4. **BUILD DATABASE DIRECTLY ON DRIVE** - use `-d /content/drive/.../uniref90` to avoid copy failures
5. DIAMOND --sensitive mode is very slow; --fast is acceptable with limitation noted in paper
6. **Keep DIAMOND command in its own cell** - no Python logging code after it that can crash
7. Colab Pro gives limited compute units (~15.82 units, ~1.95/hr = ~8 hours)
8. Use CPU + High-RAM (not GPU) for bioinformatics tools
9. Always verify file sizes on Drive: `!ls -lh {path}` after every save

### Next Session Plan (RESUME FROM STEP 5)
1. Mount Drive
2. Install DIAMOND: `wget + tar + mv to /usr/local/bin/`
3. **Rebuild database DIRECTLY on Drive:** `diamond makedb --in {BASE_DIR}/uniref90.fasta.gz -d {BASE_DIR}/databases/uniref90 --threads 4`
4. **VERIFY .dmnd file is NOT 0 bytes**
5. Copy proteins.faa locally: `cp {BASE_DIR}/intermediate/proteins.faa .`
6. Run search with --fast mode, output directly to Drive:
   `diamond blastp -q proteins.faa -d {BASE_DIR}/databases/uniref90 -o {BASE_DIR}/intermediate/uniref90_hits.m8 --id 25 --evalue 1e-5 --fast --threads 4 --block-size 4 --index-chunks 2`
7. Continue with Steps 5C, 5D, 6, 7, 8

### Resume Cell (copy-paste into first Colab cell)
```python
# RESUME - Install DIAMOND + Rebuild DB + Run Search
from google.colab import drive
drive.mount('/content/drive')

# Install DIAMOND
!wget -q https://github.com/bbuchfink/diamond/releases/download/v2.1.8/diamond-linux64.tar.gz
!tar -xzf diamond-linux64.tar.gz
!mv diamond /usr/local/bin/

BASE_DIR = "/content/drive/MyDrive/SilentHunter_v6"

# Build database DIRECTLY on Drive
print("Building database directly on Drive...")
!diamond makedb --in {BASE_DIR}/uniref90.fasta.gz -d {BASE_DIR}/databases/uniref90 --threads 4

# VERIFY - must NOT be 0 bytes
!ls -lh {BASE_DIR}/databases/uniref90.dmnd

# Copy proteins locally for speed
!cp {BASE_DIR}/intermediate/proteins.faa .

# Run DIAMOND search - output directly to Drive
print("Running DIAMOND search...")
!diamond blastp -q proteins.faa -d {BASE_DIR}/databases/uniref90 -o {BASE_DIR}/intermediate/uniref90_hits.m8 --id 25 --evalue 1e-5 --fast --threads 4 --block-size 4 --index-chunks 2

# Verify
!ls -lh {BASE_DIR}/intermediate/uniref90_hits.m8
print("Step 5B complete and saved to Drive")
```

### Paper Limitation Note
> Homology searches were performed using DIAMOND in fast mode rather than sensitive mode due to computational constraints. This may result in a small number of additional false novel proteins, though the 25% identity threshold provides a conservative baseline.

## File Locations

### Local (Mac)
```
~/silent-hunter-v6/           # Pipeline code (GitHub repo)
~/silent-hunter-downloads/    # Downloaded data
  └── SRR6356483             # 4.5 GB ISS raw data
```

### Google Drive (verified 2026-01-28)
```
MyDrive/SilentHunter_v6/
├── uniref90.fasta.gz         # 43 GB (raw sequences)
├── SRR6356483                # 4.5 GB (raw SRA)
├── databases/
│   └── uniref90.dmnd         # BROKEN (0 bytes) - must rebuild
├── intermediate/
│   ├── assembly/             # Step 3 output
│   ├── clean_1.fastq.gz      # 2.8 GB
│   ├── clean_2.fastq.gz      # 3.3 GB
│   ├── orfs/                 # Step 4 output
│   └── proteins.faa          # 94 MB
├── output/                   # Empty - final results go here
└── audit/                    # Empty
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
