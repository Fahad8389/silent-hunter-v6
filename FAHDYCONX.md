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
  - Tool: fastq-dump (SRA Toolkit)
  - Command: fastq-dump --split-files --gzip SRR6356483
  - Parameters:
    - --split-files: Separate paired-end reads into R1 and R2
    - --gzip: Compress output

OUTPUT:
  - Files: SRR6356483_1.fastq.gz, SRR6356483_2.fastq.gz
  - Read count: [TBD - fill after running]
  - Size: [TBD]

VERIFICATION:
  - [ ] Both files exist
  - [ ] Read counts match between R1 and R2
```

### Step 2 → Step 3: Quality Control

```
INPUT:
  - Files: SRR6356483_1.fastq.gz, SRR6356483_2.fastq.gz
  - Read count: [TBD]

PROCESS:
  - Tool: fastp v0.23
  - Command: [exact command]
  - Parameters:
    - --cut_mean_quality 20: Remove bases below Q20
    - --length_required 50: Remove reads < 50bp
    - WHY these values: Standard for Illumina metagenome data

OUTPUT:
  - Files: clean_1.fastq.gz, clean_2.fastq.gz
  - Read count: [TBD]

CHANGE:
  - Before: [X] reads
  - After: [Y] reads
  - Removed: [Z] reads ([%]%)
  - Reason: Low quality bases, short reads, adapters

VERIFICATION:
  - [ ] fastp HTML report reviewed
  - [ ] Survival rate > 80% (expected for good data)
```

### Step 3 → Step 4: Assembly

```
INPUT:
  - Files: clean_1.fastq.gz, clean_2.fastq.gz
  - Read count: [TBD]

PROCESS:
  - Tool: MEGAHIT v1.2.9
  - Command: [exact command]
  - Parameters:
    - --min-contig-len 500: Ignore contigs < 500bp
    - --k-min 21 --k-max 141: K-mer range for assembly
    - WHY: Standard for metagenome assembly

OUTPUT:
  - File: final.contigs.fa
  - Contig count: [TBD]
  - N50: [TBD]
  - Total size: [TBD]

VERIFICATION:
  - [ ] Assembly completed without errors
  - [ ] N50 reasonable (expect 700-1500 bp)
```

### Step 4 → Step 5: ORF Prediction

```
INPUT:
  - File: final.contigs.fa
  - Contig count: [TBD]

PROCESS:
  - Tool: Prodigal v2.6.3
  - Command: prodigal -i contigs.fa -a proteins.faa -p meta
  - Parameters:
    - -p meta: Metagenomic mode (handles mixed organisms)
    - WHY: Standard for metagenome ORF prediction

OUTPUT:
  - File: proteins.faa
  - Protein count: [TBD]
  - Complete ORFs: [TBD]
  - Partial ORFs: [TBD]

VERIFICATION:
  - [ ] Protein count reasonable (expect 1 ORF per ~1kb contig)
```

### Step 5 → Step 6: Homology Search (UniRef90)

```
INPUT:
  - File: proteins.faa
  - Protein count: [TBD]

PROCESS:
  - Tool: DIAMOND v2.1
  - Command: diamond blastp -q proteins.faa -d uniref90 --id 25 --evalue 1e-5
  - Parameters:
    - --id 25: Minimum 25% sequence identity
    - --evalue 1e-5: Statistical significance threshold
    - WHY 25%: Below this is "twilight zone" - can't distinguish from random

OUTPUT:
  - File: uniref90_hits.m8
  - Proteins WITH hits: [TBD]
  - Proteins WITHOUT hits: [TBD] ← These are NOVEL candidates

CHANGE:
  - Total proteins: [X]
  - With UniRef90 match: [Y]
  - Novel (no match): [Z]
  - Reason: Proteins with <25% identity to any known protein

VERIFICATION:
  - [ ] Hit count verified
  - [ ] Sample hits checked manually
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
