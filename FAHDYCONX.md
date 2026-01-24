# FAHDYCONX - Fahd's Context Documentation System

## RULE #1: NO FABRICATION, NO FAKE DATA

```
╔════════════════════════════════════════════════════════════════╗
║  ALL DATA MUST BE REAL, VERIFIED, AND TRACEABLE               ║
║  - No made-up numbers                                          ║
║  - No estimated results presented as actual                    ║
║  - Every number must come from an actual command output        ║
║  - If uncertain, mark as "TBD" or "PENDING"                   ║
╚════════════════════════════════════════════════════════════════╝
```

---

## RULE #2: DOCUMENT EVERY TRANSITION

Every time data moves from one step to another, record:
- **INPUT**: What went in (count, file, size)
- **PROCESS**: What was done (tool, parameters)
- **OUTPUT**: What came out (count, file, size)
- **REASON**: Why numbers changed

### Transition Log Template

```
═══════════════════════════════════════════════════════════════
TRANSITION: [Step N] → [Step N+1]
DATE: YYYY-MM-DD HH:MM
═══════════════════════════════════════════════════════════════

INPUT:
  - File: [filename]
  - Count: [number] proteins/reads/contigs
  - Size: [X] GB/MB

PROCESS:
  - Tool: [tool name + version]
  - Command: [exact command run]
  - Parameters: [key parameters and WHY chosen]

OUTPUT:
  - File: [filename]
  - Count: [number] proteins/reads/contigs
  - Size: [X] GB/MB

CHANGE:
  - Before: [X]
  - After: [Y]
  - Difference: [X - Y] removed
  - Reason: [WHY did numbers change?]

VERIFICATION:
  - [ ] Output file exists
  - [ ] Count verified with: [command used to verify]
  - [ ] Checksum recorded

═══════════════════════════════════════════════════════════════
```

---

## RULE #3: READ TOOL DOCUMENTATION BEFORE USE

Before running ANY tool, complete this checklist:

### Tool Documentation Checklist

```
TOOL: _______________
DATE REVIEWED: _______________

[ ] Read official documentation/manual
[ ] Understand what the tool does
[ ] Understand input format requirements
[ ] Understand output format
[ ] Understand key parameters:
    - Parameter 1: _______ means _______
    - Parameter 2: _______ means _______
[ ] Understand default values and if they're appropriate
[ ] Found example usage that matches our use case
[ ] Tested on small sample first (if applicable)

DOCUMENTATION LINKS:
- Official: [URL]
- Tutorial used: [URL]

NOTES:
_________________________________
_________________________________
```

---

## PIPELINE TRANSITION LOG

### Step 0 → Step 1: Raw Data Download

```
INPUT:
  - Source: NASA GeneLab GLDS-69 / NCBI SRA
  - Accession: SRR6356483

PROCESS:
  - Tool: curl (direct download)
  - Source URL: https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR6356483/SRR6356483

OUTPUT:
  - File: SRR6356483
  - Size: 4.5 GB
  - Location: ~/silent-hunter-downloads/

VERIFICATION:
  - [x] File downloaded: 2025-01-23
  - [ ] MD5 checksum verified
  - [ ] Converted to FASTQ
```

### Step 1 → Step 2: SRA to FASTQ Conversion

```
INPUT:
  - File: SRR6356483
  - Size: 4.5 GB

PROCESS:
  - Tool: fastq-dump (SRA Toolkit 3.0.0)
  - Command: /content/sratoolkit.3.0.0-ubuntu64/bin/fastq-dump --split-files SRR6356483
  - Note: pip install sra-tools DOES NOT WORK - must download binary!
  - Time: ~1 hour

OUTPUT:
  - Files: SRR6356483_1.fastq.gz (2.9 GB), SRR6356483_2.fastq.gz (3.4 GB)
  - Read count: 40,440,324 paired-end reads

VERIFICATION:
  - [x] Both files exist
  - [x] Read counts verified: 40,440,324 reads
```

### Step 2 → Step 3: Quality Control

```
INPUT:
  - Files: SRR6356483_1.fastq.gz, SRR6356483_2.fastq.gz
  - Read count: 80,880,648 reads (40.4M pairs)

PROCESS:
  - Tool: fastp v0.23
  - Command: fastp -i SRR6356483_1.fastq.gz -I SRR6356483_2.fastq.gz
             -o clean_1.fastq.gz -O clean_2.fastq.gz
             --detect_adapter_for_pe --cut_front --cut_tail
             --cut_window_size 4 --cut_mean_quality 20 --length_required 50
  - Time: ~15-20 minutes

OUTPUT:
  - Files: clean_1.fastq.gz, clean_2.fastq.gz
  - Read count: 79,292,500 reads

CHANGE:
  - Before: 80,880,648 reads
  - After: 79,292,500 reads
  - Removed: 1,588,148 reads (2%)
  - Survival rate: 98.0% - EXCELLENT
  - Reason: Low quality bases, short reads, adapters

VERIFICATION:
  - [x] fastp HTML report generated
  - [x] Survival rate 98% > 80% threshold
```

### Step 3 → Step 4: Assembly

```
INPUT:
  - Files: clean_1.fastq.gz, clean_2.fastq.gz
  - Read count: 79,292,500 reads

PROCESS:
  - Tool: MEGAHIT v1.2.9
  - Command: megahit -1 clean_1.fastq.gz -2 clean_2.fastq.gz -o assembly
             --min-contig-len 500 --k-min 21 --k-max 141 --k-step 12 -t 4 -m 0.9
  - K-mer list: 21,33,45,57,69,81,93,105,117,129,141 (11 iterations)
  - Time: 28,755 seconds (~8 hours)

OUTPUT:
  - File: final.contigs.fa
  - Contig count: 312,709
  - N50: 1,733 bp (BETTER than expected 700-1500)
  - Total size: 432,707,043 bp
  - Largest contig: 72,044 bp

VERIFICATION:
  - [x] Assembly completed without errors
  - [x] N50 = 1,733 bp (above expected range - good quality)
```

### Step 4 → Step 5: ORF Prediction

```
INPUT:
  - File: final.contigs.fa
  - Contig count: 312,709

PROCESS:
  - Tool: Prodigal v2.6.3
  - Command: prodigal -i assembly/final.contigs.fa -a proteins.faa -d genes.fna
             -o genes.gff -f gff -p meta -q
  - Parameters:
    - -p meta: Metagenomic mode (required for mixed organisms)
  - Time: ~10-15 minutes

OUTPUT:
  - File: proteins.faa
  - Protein count: 448,015 (avg 1.4 per contig)
  - Complete ORFs: 208,489 (47%) - have START and STOP codons
  - Partial ORFs: 239,526 (53%) - cut off at contig edge

VERIFICATION:
  - [x] Protein count reasonable (448K from 312K contigs)
  - [x] ~47% complete ORFs (normal for metagenome)
```

### Step 5 → Step 6: Homology Search (UniRef90)

```
SESSION 1 - FAILED (Colab timeout before completion)

STEP 5A: Database Build
INPUT:
  - File: uniref90.fasta.gz (43 GB)

PROCESS:
  - Tool: DIAMOND v2.1.8
  - Command: diamond makedb --in uniref90.fasta.gz -d uniref90 --threads 4
  - Time: 2,541 seconds (~42 minutes)

OUTPUT:
  - File: uniref90.dmnd
  - Sequences: 184,146,434 (184 million proteins)
  - Letters: 64,621,732,275 (64.6 billion amino acids)
  - NOTE: File was 0 bytes on Drive - DID NOT SAVE PROPERLY

STEP 5B: Search - CRASHED
INPUT:
  - File: proteins.faa (448,015 proteins)

PROCESS:
  - Tool: DIAMOND blastp
  - Command: diamond blastp -q proteins.faa -d uniref90 --id 25 --evalue 1e-5
             --sensitive --threads 4 --max-target-seqs 1
  - CRASHED at: "Processing query block 1, reference block 18/33"
  - Time before crash: ~8 hours
  - Likely cause: Memory issue with --sensitive mode

LESSON LEARNED:
  - Use safer settings: --threads 2 --block-size 2 --index-chunks 4
  - Save database to Drive IMMEDIATELY after build
  - Consider --fast mode instead of --sensitive

OUTPUT:
  - File: uniref90_hits.m8 - NOT CREATED (search crashed)
  - Proteins WITH hits: [TBD - next session]
  - Proteins WITHOUT hits: [TBD - next session]
```

### Step 6 → Step 7: Quality Filtering

```
INPUT:
  - Novel proteins: [TBD]

PROCESS:
  - Tool: Custom Python script (06_quality_filter.py)
  - Filters applied:
    - Length ≥ 100 aa (WHY: shorter proteins unreliable)
    - Starts with M (WHY: proper start codon)
    - No internal stops (WHY: would be pseudogene)
    - Complete ORF (WHY: partial ORFs may be artifacts)

OUTPUT:
  - File: truly_novel.faa
  - Count: [TBD]

CHANGE:
  - Before filtering: [X]
  - After filtering: [Y]
  - Removed: [Z]
  - Breakdown:
    - Too short: [n]
    - No start codon: [n]
    - Internal stops: [n]
    - Partial ORFs: [n]

VERIFICATION:
  - [ ] All filters applied correctly
  - [ ] Sample sequences checked manually
```

### Step 5B: Taxonomic Classification

```
INPUT:
  - File: final.contigs.fa
  - Contig count: [TBD]

PROCESS:
  - Tool: Kraken2 / CAT / DIAMOND-LCA
  - Purpose: Assign microbial source to each contig

OUTPUT:
  - File: protein_taxonomy.tsv
  - Columns: protein_id, contig_id, taxonomy

TOP ORGANISMS:
  1. [Organism 1]: [count] proteins
  2. [Organism 2]: [count] proteins
  3. [Organism 3]: [count] proteins
  ...

VERIFICATION:
  - [ ] Organisms make sense for ISS (human-associated microbes expected)
  - [ ] No unexpected organisms (contamination check)
```

### Step 7 → Step 8: Verification & Classification

```
INPUT:
  - File: truly_novel.faa
  - Count: [TBD]

PROCESS:
  - Multiple verification tests (see VERIFICATION_REPORT.md)

OUTPUT:
  - Classified proteins:
    - Type A (Completely novel): [TBD]
    - Type B (Structure known): [TBD]
    - Type C (Remote homolog): [TBD]
    - Type D (Domain hybrid): [TBD]
    - Type E (Artifact): [TBD]

FINAL COUNT: [TBD] verified novel proteins
```

### Step 8: Final Results Table

```
INPUT:
  - truly_novel.faa (proteins)
  - protein_taxonomy.tsv (organism assignments)
  - verification_results.json (classifications)

PROCESS:
  - Tool: 08_create_final_table.py
  - Merges all data into annotated table

OUTPUT:
  - File: novel_proteins_annotated.tsv

TABLE COLUMNS:
  | protein_id | contig_id | organism | classification | length_aa | mw_kda | sequence |

SUMMARY BY ORGANISM:
  | Organism | Count | % |
  |----------|-------|---|
  | [TBD]    | [TBD] | [TBD] |

SUMMARY BY TYPE:
  | Type | Count | % |
  |------|-------|---|
  | Type A (Completely novel) | [TBD] | [TBD] |
  | Type B (Structure known)  | [TBD] | [TBD] |
  | ...  | ... | ... |
```

---

## TOOL DOCUMENTATION LOG

### Tool: SRA Toolkit (fastq-dump)

```
DATE REVIEWED: [TBD]
VERSION: 3.0+

PURPOSE: Convert SRA format to FASTQ

KEY PARAMETERS:
- --split-files: Separates paired-end reads
- --gzip: Compresses output

DOCUMENTATION:
- https://github.com/ncbi/sra-tools/wiki

NOTES:
- Must use --split-files for paired-end data
- Output naming: [accession]_1.fastq.gz, [accession]_2.fastq.gz
```

### Tool: fastp

```
DATE REVIEWED: [TBD]
VERSION: 0.23+

PURPOSE: Quality control and filtering of FASTQ reads

KEY PARAMETERS:
- --cut_mean_quality: Sliding window quality threshold
- --length_required: Minimum read length
- --detect_adapter_for_pe: Auto-detect adapters

DOCUMENTATION:
- https://github.com/OpenGene/fastp

NOTES:
- Generates HTML report - ALWAYS review this
- Default quality threshold is reasonable for most data
```

### Tool: MEGAHIT

```
DATE REVIEWED: [TBD]
VERSION: 1.2.9

PURPOSE: Metagenome assembly

KEY PARAMETERS:
- --min-contig-len: Minimum output contig length
- --k-min/--k-max: K-mer range
- -m: Memory limit (fraction)

DOCUMENTATION:
- https://github.com/voutcn/megahit

NOTES:
- Cannot resume - if interrupted, must restart
- Memory intensive - use -m 0.9 for 90% of available RAM
```

### Tool: Prodigal

```
DATE REVIEWED: [TBD]
VERSION: 2.6.3

PURPOSE: Prokaryotic gene/ORF prediction

KEY PARAMETERS:
- -p meta: Metagenomic mode (REQUIRED for metagenomes)
- -a: Output protein sequences
- -d: Output nucleotide sequences

DOCUMENTATION:
- https://github.com/hyattpd/Prodigal

NOTES:
- MUST use -p meta for metagenomes
- Header contains partial=XX flag (00=complete, others=partial)
```

### Tool: DIAMOND

```
DATE REVIEWED: [TBD]
VERSION: 2.1+

PURPOSE: Fast protein alignment (alternative to BLAST)

KEY PARAMETERS:
- --id: Minimum identity threshold (we use 25%)
- --evalue: E-value threshold (we use 1e-5)
- --sensitive: More sensitive (slower) search

DOCUMENTATION:
- https://github.com/bbuchfink/diamond

NOTES:
- 25% identity is "twilight zone" - conservative threshold
- Output format 6 (m8) is tab-separated
```

---

## VERIFICATION CHECKLIST

Before marking ANY step complete:

```
[ ] Command ran without errors
[ ] Output file exists and has expected size
[ ] Count/statistics recorded in this document
[ ] Numbers make sense (not obviously wrong)
[ ] Checksum recorded in audit/checksums.md5
[ ] Transition documented above
```

---

## REMEMBER

```
╔════════════════════════════════════════════════════════════════╗
║  "If it's not documented, it didn't happen"                    ║
║                                                                 ║
║  Every number in the final paper must trace back to:           ║
║  1. A specific command that was run                            ║
║  2. A specific output file                                     ║
║  3. A verification step                                        ║
╚════════════════════════════════════════════════════════════════╝
```
