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

**Date:** 2025-01-24

### Session 1 Results (Lost due to Colab timeout)
- Step 1: 40,440,324 paired-end reads extracted
- Step 2: 79,292,500 reads after QC (98% survival)
- Step 3: 312,709 contigs assembled (N50=1,733 bp) - took 8 hours
- Step 4: 448,015 proteins predicted (208,489 complete ORFs)
- Step 5A: UniRef90 database built (184M proteins) - took 42 min
- Step 5B: CRASHED at block 18/33 after 8 hours (memory/timeout issue)

**ALL INTERMEDIATE FILES LOST** - Colab session timed out before saving to Drive

### Data on Google Drive (SAFE)
- [x] SRR6356483 (ISS raw data) - 4.5 GB
- [x] uniref90.fasta.gz - 43 GB

### Lessons Learned
1. **SAVE TO DRIVE AFTER EVERY STEP** - Colab local storage is temporary!
2. SRA Toolkit needs manual binary install (not pip)
3. MEGAHIT takes ~8 hours for 40M reads
4. DIAMOND --sensitive mode may cause memory issues
5. Use safer DIAMOND settings: --threads 2 --block-size 2 --index-chunks 4

### Next Session Plan
1. Start from Step 1 (data already on Drive)
2. Save to Drive after EACH step completes
3. Use safer DIAMOND settings for Step 5B
4. Expected total time: ~15 hours (split over 2 days)

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
