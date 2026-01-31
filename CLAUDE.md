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

**Date:** 2026-01-31

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

### Session 4 (2026-01-31)
- Database build completed successfully: 184,146,434 sequences, 84GB, 65 min
- **BUT database saved to LOCAL Colab storage, not Drive** - lost on disconnect
- Drive still shows 0-byte uniref90.dmnd from Jan 28
- **Root cause:** Previous cell used path that defaulted to local, not Drive path
- **Solution:** New 3-cell format ensures output goes DIRECTLY to Drive
- Installed 471 bioinformatics skills for Claude Code (bioSkills + claude-scientific-skills)
- **Status:** Must rebuild database with corrected cells, currently in progress

### Data on Google Drive (VERIFIED 2026-01-31)
```
MyDrive/SilentHunter_v6/
├── uniref90.fasta.gz              # 43 GB ✅
├── SRR6356483                     # 4.5 GB ✅
├── databases/
│   └── uniref90.dmnd              # 0 bytes ❌ MUST REBUILD (Session 4 in progress)
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
10. **USE 3 SEPARATE CELLS** - Setup, Build, Search - so failures don't require full restart
11. **Add anti-disconnect JavaScript** - prevents Colab timeout during long operations
12. **VERIFY output path includes full Drive path** - not just relative path that saves locally

### Next Session Plan (RESUME FROM STEP 5A)
1. Run **Cell 1** (Setup) - mounts Drive, installs DIAMOND, adds anti-disconnect
2. Run **Cell 2** (Build) - builds database DIRECTLY on Drive (~65 min)
3. **VERIFY** database is ~84GB, NOT 0 bytes
4. Run **Cell 3** (Search) - DIAMOND blastp with --fast mode (~1-2 hours)
5. Extract novel candidates (proteins with NO UniRef90 hits)
6. Continue with Steps 5B, 5C, 5D, 5E, 6, 7, 8, 9

**Keep Colab tab active throughout!**

### Step 5A Colab Cells (NEW 3-CELL FORMAT)

**Why 3 cells instead of 1:**
- If search fails, you don't have to rebuild the 65-min database
- Each long operation is isolated
- Easier to verify intermediate outputs

---

**CELL 1: Setup (~30 sec)**
```python
# STEP 5A - CELL 1: Setup
from google.colab import drive
import IPython

drive.mount('/content/drive')

# Anti-disconnect - keeps session alive
display(IPython.display.Javascript('''
function ClickConnect(){
  console.log("Keeping alive...");
  document.querySelector("colab-connect-button").click()
}
setInterval(ClickConnect, 60000)
'''))

# Install DIAMOND
!wget -q https://github.com/bbuchfink/diamond/releases/download/v2.1.8/diamond-linux64.tar.gz
!tar -xzf diamond-linux64.tar.gz
!mv diamond /usr/local/bin/

BASE_DIR = "/content/drive/MyDrive/SilentHunter_v6"
!rm -f {BASE_DIR}/databases/uniref90.dmnd

print("✅ Setup complete. Run Cell 2.")
```

---

**CELL 2: Build Database (~65 min)**
```python
# STEP 5A - CELL 2: Build database DIRECTLY to Drive
BASE_DIR = "/content/drive/MyDrive/SilentHunter_v6"

!diamond makedb \
    --in "{BASE_DIR}/uniref90.fasta.gz" \
    -d "{BASE_DIR}/databases/uniref90" \
    --threads 4

!echo "=== VERIFY: Must show ~84GB ==="
!ls -lh {BASE_DIR}/databases/uniref90.dmnd
```

---

**CELL 3: Search (~1-2 hours)**
```python
# STEP 5A - CELL 3: DIAMOND search
BASE_DIR = "/content/drive/MyDrive/SilentHunter_v6"

!diamond blastp \
    -q "{BASE_DIR}/intermediate/proteins.faa" \
    -d "{BASE_DIR}/databases/uniref90" \
    -o "{BASE_DIR}/intermediate/uniref90_hits.m8" \
    --id 25 --evalue 1e-5 --fast --threads 4

!echo "=== Results ==="
!wc -l {BASE_DIR}/intermediate/uniref90_hits.m8
!ls -lh {BASE_DIR}/intermediate/uniref90_hits.m8
print("✅ Step 5A complete")
```

---

**IMPORTANT:** Keep Colab tab active during Cell 2 and Cell 3!

### Paper Limitation Note
> Homology searches were performed using DIAMOND in fast mode rather than sensitive mode due to computational constraints. This may result in a small number of additional false novel proteins, though the 25% identity threshold provides a conservative baseline.

### Paper Strength Note (FoldMason)
> To validate proteins classified as truly novel (Type A), we performed structural alignment using FoldMason (Gilchrist et al., Science 2026), which enables phylogenetic analysis beyond the sequence twilight zone. This multi-tier approach—combining sequence homology (DIAMOND), remote homology (HHblits), and structural alignment (Foldseek/FoldMason)—provides robust classification of novel proteins.

## File Locations

### Local (Mac)
```
~/silent-hunter-v6/           # Pipeline code (GitHub repo)
~/silent-hunter-downloads/    # Downloaded data
  └── SRR6356483             # 4.5 GB ISS raw data
```

### Google Drive (verified 2026-01-31)
```
MyDrive/SilentHunter_v6/
├── uniref90.fasta.gz         # 43 GB (raw sequences)
├── SRR6356483                # 4.5 GB (raw SRA)
├── databases/
│   └── uniref90.dmnd         # 0 bytes - rebuild in progress (Session 4)
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
Step 1:  Download (SRA → FASTQ)
Step 2:  QC (fastp)
Step 3:  Assembly (MEGAHIT)
Step 4:  ORF Prediction (Prodigal)
Step 5A: DIAMOND vs UniRef90 (primary homology, 25% identity cutoff)
Step 5B: DIAMOND vs SwissProt + Human proteome (exclude matches)
Step 5C: Taxonomy assignment (CAT for contig-level)
Step 5D: HHblits remote homology (detect Type C proteins)
Step 5E: Pfam/InterProScan domains (detect Type D proteins)
Step 6:  Quality Filter (length ≥50 aa, completeness)
Step 7:  FoldMason Structural Validation (validate Type A candidates)
Step 8:  Functional Annotation (eggNOG-mapper)
Step 9:  Final Table + Comparison to Cell 2025 ISS MAGs
```

---

### Step 5A: DIAMOND vs UniRef90

**Purpose:** Primary homology search to identify known proteins

**Command:**
```bash
diamond blastp -q proteins.faa -d uniref90 -o uniref90_hits.m8 \
  --id 25 --evalue 1e-5 --fast --threads 4 --outfmt 6
```

**Output:** Proteins with NO hits at 25% identity → candidate novel proteins

---

### Step 5B: SwissProt + Human Exclusion

**Purpose:** Exclude any matches to curated proteins or human contamination

**Databases:**
- SwissProt: `ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz`
- Human proteome: `ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/`

**Command:**
```bash
diamond blastp -q novel_candidates.faa -d swissprot -o swissprot_hits.m8 --id 25 --evalue 1e-5
diamond blastp -q novel_candidates.faa -d human -o human_hits.m8 --id 25 --evalue 1e-5
```

**Output:** Remove any proteins matching SwissProt or Human → refined novel candidates

---

### Step 5C: Taxonomy Assignment (CAT)

**Purpose:** Assign taxonomic origin to contigs/proteins

**Tool:** CAT (Contig Annotation Tool) - https://github.com/dutilh/CAT

**Why CAT over alternatives:**
- Kraken2: optimized for reads, not contigs
- DIAMOND-LCA: less accurate for metagenome contigs
- CAT: specifically designed for contig-level taxonomy

**Command:**
```bash
CAT contigs -c contigs.fasta -d CAT_database -t CAT_taxonomy -o CAT_output
CAT add_names -i CAT_output.contig2classification.txt -o CAT_output.named.txt -t CAT_taxonomy
```

**Output:** Each contig → taxonomic assignment (phylum, genus, species)

---

### Step 5D: HHblits Remote Homology

**Purpose:** Detect distant homologs missed by DIAMOND (Type C proteins)

**Tool:** HHblits from HH-suite3 - https://github.com/soedinglab/hh-suite

**Database:** Uniclust30 or BFD

**Command:**
```bash
hhblits -i query.faa -d uniclust30 -o results.hhr -n 3 -e 1e-3
```

**Threshold:** E-value < 1e-3 AND probability > 50%

**Output:**
- Match found → Type C (remote homolog)
- No match → remains Type A candidate

---

### Step 5E: Pfam/InterProScan Domains

**Purpose:** Detect known protein domains (Type D - domain hybrids)

**Tool:** InterProScan - https://www.ebi.ac.uk/interpro/download/

**Command:**
```bash
interproscan.sh -i novel_candidates.faa -o interpro_results.tsv -f tsv -appl Pfam,TIGRFAM,SUPERFAMILY
```

**Output:**
- Has known domains but novel arrangement → Type D
- No domains detected → remains Type A candidate

---

### Step 7: FoldMason Structural Validation (KEY STEP)

**Purpose:** Validate "truly novel" (Type A) proteins using structural alignment beyond sequence twilight zone.

**Reference:** Gilchrist et al. (2026). FoldMason: Fast and accurate multiple structural alignment. *Science*. DOI: [10.1126/science.ads6733](https://www.science.org/doi/10.1126/science.ads6733)

**Rationale:** "Protein structure is conserved beyond sequence, making multiple structural alignment essential for analyzing distantly related proteins" - proteins that appear novel by sequence (<25% identity) may have structural homologs.

**Process:**
1. Predict structures for Type A candidates using ESMFold (fast) or AlphaFold2 (accurate)
2. Run Foldseek against PDB + AlphaFold DB to find structural matches
3. For proteins with structural hits: use FoldMason for multiple structural alignment
4. Reclassify: structural match → Type B, no match → confirmed Type A

**Commands:**
```bash
# Structure prediction (ESMFold - can run on Colab with GPU)
python esm_fold.py --fasta type_a_candidates.faa --output structures/

# Foldseek search against AlphaFold DB
foldseek easy-search structures/ afdb foldseek_results.m8 tmp --format-output query,target,evalue,alntmscore

# Threshold: TM-score > 0.5 indicates structural similarity
```

**Tools:**
- ESMFold: https://github.com/facebookresearch/esm
- Foldseek: https://github.com/steineggerlab/foldseek
- FoldMason: https://github.com/steineggerlab/foldmason

**Expected outcome:** ~20-30% of initial Type A candidates reclassified to Type B (structure-known)

---

### Step 8: Functional Annotation (eggNOG-mapper)

**Purpose:** Predict function for novel proteins (reviewers WILL ask "what do they do?")

**Tool:** eggNOG-mapper - http://eggnog-mapper.embl.de/

**Command:**
```bash
emapper.py -i novel_proteins.faa -o eggnog_results --cpu 4 -m diamond
```

**Output columns:**
- COG category (e.g., J = Translation, K = Transcription)
- KEGG pathway
- GO terms
- Predicted function description

**For truly novel (Type A):** May have no functional annotation → report as "function unknown, potentially novel function"

---

### Step 9: Final Table + Comparison to Cell 2025 Study

**Purpose:** Generate publication-ready output and contextualize findings

**Comparison dataset:** Singh et al. (2025). Cell. "The International Space Station has a unique and extreme microbial and chemical environment"
- 34 high-quality MAGs from ISS
- Compare your novel proteins to proteins from these MAGs

**Comparison analysis:**
```python
# Check if novel proteins match Cell 2025 MAGs
diamond blastp -q novel_proteins.faa -d cell_2025_mags_proteins.faa -o cell2025_comparison.m8 --id 50
```

**Questions to answer:**
1. How many novel proteins come from organisms in the Cell 2025 MAGs?
2. Are there novel proteins from organisms NOT in the Cell 2025 study?
3. What functions are enriched in ISS novel proteins?

**Final output file:** `novel_proteins_final.tsv`

## Final Output Table Format

```
novel_proteins_final.tsv columns:
| protein_id | contig_id | organism | classification | length_aa | mw_kda | cog_category | kegg_pathway | go_terms | function | in_cell2025 | sequence |
```

Each protein tagged with:
- **Microbial source** (which organism it came from - from CAT)
- **Classification** (Type A-E)
- **Properties** (length, molecular weight)
- **Function** (from eggNOG-mapper)
- **Comparison** (found in Cell 2025 MAGs? yes/no)

## Expected Results

| Step | Metric | Expected Count |
|------|--------|----------------|
| Step 3 | Total contigs | 300,000-350,000 |
| Step 4 | Total ORFs | 400,000-500,000 |
| Step 4 | Complete ORFs | 200,000-250,000 |
| Step 5A | No UniRef90 hit | 40,000-60,000 |
| Step 5B | After SwissProt/Human exclusion | 35,000-50,000 |
| Step 5D | Type C (HHblits remote homolog) | 12,000-18,000 |
| Step 5E | Type D (domain hybrid) | 4,000-6,000 |
| Step 6 | After quality filter (≥50 aa) | 25,000-35,000 |
| Step 7 | Type B (structural match) | 5,000-8,000 |
| **Final** | **Type A (truly novel)** | **2,000-4,000** |

## Validation Metrics (for paper)

| Metric | Target | Purpose |
|--------|--------|---------|
| Negative control | <5% false novel | Run 1000 known UniRef proteins through pipeline |
| Structural validation rate | 20-30% | Type A → Type B reclassification |
| Taxonomy assignment rate | >80% | Contigs assigned to genus level |
| Functional annotation rate | 40-60% | eggNOG assignments for novel proteins |

## Novel Protein Classification

| Type | Definition | Detection Method | Expected % |
|------|------------|------------------|------------|
| **Type A** | Completely novel (no seq/struct match) | Passes all filters | 10-15% |
| **Type B** | Structure-known (no sequence homolog) | Foldseek TM-score > 0.5 | 20-25% |
| **Type C** | Remote homolog (distant sequence match) | HHblits E < 1e-3, prob > 50% | 35-40% |
| **Type D** | Domain hybrid (novel domain arrangement) | Pfam domains in novel combination | 10-15% |
| **Type E** | Artifact (low quality, too short) | Length < 50 aa, incomplete ORF | 5-10% |

## Negative Control Protocol

**Purpose:** Validate that our pipeline correctly identifies known proteins as "not novel"

**Method:**
1. Select 1,000 random proteins from UniRef90 (known proteins)
2. Run through full pipeline (Steps 5A-7)
3. Count how many are incorrectly classified as "novel"

**Expected:** <5% false positive rate (i.e., <50 of 1000 known proteins called novel)

**Command:**
```bash
# Sample 1000 sequences from UniRef90
seqtk sample uniref90.fasta.gz 1000 > negative_control.faa
# Run through pipeline and check results
```

If false positive rate > 5%, investigate and adjust thresholds.

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

## Paper Outline (bioRxiv Preprint)

### Title
"Discovery of Novel Proteins from International Space Station Metagenome Using Multi-Tier Homology and Structural Validation"

### Abstract Structure
1. Background: ISS microbiome is unique environment
2. Methods: Multi-tier pipeline (sequence → structure → function)
3. Results: X truly novel proteins (Type A), Y with structural matches only (Type B)
4. Conclusion: Resource for astrobiology and protein engineering

### Figures
1. **Fig 1:** Pipeline flowchart (Steps 1-9)
2. **Fig 2:** Funnel diagram (447K ORFs → 2-4K novel proteins)
3. **Fig 3:** Classification breakdown (Types A-E pie chart)
4. **Fig 4:** Taxonomy distribution of novel proteins
5. **Fig 5:** Comparison to Cell 2025 MAGs (Venn diagram)
6. **Fig 6:** Example Type A protein structure (ESMFold prediction)

### Tables
1. **Table 1:** Pipeline statistics (reads → contigs → ORFs → novel)
2. **Table 2:** Top 20 novel proteins with predicted functions
3. **Table 3:** Taxonomy of source organisms

### Supplementary
- **Table S1:** Complete list of all novel proteins
- **Table S2:** eggNOG annotations
- **Data availability:** All sequences deposited in Zenodo

---

## Claude Code Skills (Installed 2026-01-31)

**471 bioinformatics skills installed** for specialized guidance:

| Source | Skills | Repository |
|--------|--------|------------|
| bioSkills | 330 | https://github.com/GPTomics/bioSkills |
| claude-scientific-skills | 141 | https://github.com/K-Dense-AI/claude-scientific-skills |

**Key skills for this project:**
- `bio-metagenomics-*` - Metagenome assembly, profiling, AMR detection
- `bio-proteomics-*` - Protein identification, quantification
- `bio-structural-biology-*` - AlphaFold predictions, structure analysis
- `bio-pathway-analysis-*` - GO enrichment, KEGG pathways
- `bio-phylogenetics-*` - Tree inference, distance calculations
- `scanpy`, `anndata` - Single-cell analysis tools
- `biopython` - Sequence manipulation
- `scientific-writing` - Publication assistance

**Usage:** Skills are invoked with `/skill-name` or automatically when relevant context is detected.

---

## Key References

| Citation | Relevance |
|----------|-----------|
| Gilchrist et al. (2026). FoldMason. *Science*. DOI: 10.1126/science.ads6733 | Structural alignment beyond twilight zone - validates Type A/B classification |
| [Singh et al. Cell 2025](https://www.cell.com/cell/fulltext/S0092-8674(25)00108-4) | 34 MAGs from ISS, primary comparison dataset |
| [Urbaniak et al. Microbiome 2022](https://microbiomejournal.biomedcentral.com/articles/10.1186/s40168-022-01293-0) | Microbial Tracking-2, ISS metagenomics |
| [Sishc et al. Microbiome 2023](https://link.springer.com/article/10.1186/s40168-023-01545-7) | ISS MAGs characterization |
| [Bijlani et al. Microbiome 2024](https://link.springer.com/article/10.1186/s40168-024-01916-8) | Novel ISS bacteria adaptation |
| NASA GeneLab GLDS-69 | Primary data source |
