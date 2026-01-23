# Pipeline Flowchart

## Silent Hunter v6.0 - Visual Overview

```
╔══════════════════════════════════════════════════════════════════╗
║                    SILENT HUNTER v6.0 PIPELINE                    ║
║                    100% DATA - PUBLICATION READY                  ║
╚══════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: DATA ACQUISITION                                        │
├─────────────────────────────────────────────────────────────────┤
│ Input:  SRR6356483 (GLDS-69)                                    │
│ Tool:   fastq-dump (SRA Toolkit)                                │
│ Output: Raw FASTQ files (~6.24 GB)                              │
│ Verify: MD5 checksum, read count                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: QUALITY CONTROL                                         │
├─────────────────────────────────────────────────────────────────┤
│ Input:  Raw FASTQ                                               │
│ Tool:   fastp v0.23+                                            │
│ Params: --detect_adapter_for_pe --cut_front --cut_tail          │
│         --cut_window_size 4 --cut_mean_quality 20               │
│         --length_required 50                                    │
│ Output: Clean FASTQ, HTML report                                │
│ Verify: Read survival rate, quality scores                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: METAGENOMIC ASSEMBLY                                    │
├─────────────────────────────────────────────────────────────────┤
│ Input:  Clean FASTQ                                             │
│ Tool:   MEGAHIT v1.2.9                                          │
│ Params: --min-contig-len 500 --k-min 21 --k-max 141             │
│ Output: Contigs FASTA                                           │
│ Verify: N50, total contigs, assembly size                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: ORF PREDICTION                                          │
├─────────────────────────────────────────────────────────────────┤
│ Input:  Contigs FASTA                                           │
│ Tool:   Prodigal v2.6.3 (meta mode)                             │
│ Params: -p meta                                                 │
│ Output: Protein FASTA, GFF annotations                          │
│ Verify: Total ORFs, length distribution                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: HOMOLOGY SEARCH (MULTI-DATABASE)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  UniRef90    │  │  SwissProt   │  │    Human     │          │
│  │  184M seqs   │  │   570K seqs  │  │   20K seqs   │          │
│  │  (primary)   │  │  (curated)   │  │  (contam)    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         └────────────┬────┴─────────────────┘                   │
│                      ▼                                          │
│              DIAMOND blastp                                     │
│              --id 25 --evalue 1e-5 --sensitive                  │
│                                                                 │
│  ┌──────────────┐                                               │
│  │   VSEARCH    │  Chimera detection (UCHIME)                   │
│  └──────────────┘                                               │
│                                                                 │
│ Output: Hit tables (.m8 format)                                 │
│ Verify: Hit counts per database                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: QUALITY FILTERING                                       │
├─────────────────────────────────────────────────────────────────┤
│ Filters:                                                        │
│   ├── Length ≥ 100 amino acids                                  │
│   ├── Starts with Methionine (M)                                │
│   ├── No internal stop codons                                   │
│   ├── Complete ORF (partial=00 in Prodigal)                     │
│   └── No match in ANY database at 25% identity                  │
│                                                                 │
│ Output: Filtered novel proteins                                 │
│ Verify: Filter statistics, retention rate                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 7: VERIFICATION SUITE                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ AUTOMATED TESTS                                          │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ • Human contamination check                              │   │
│  │ • Amino acid composition (chi-squared)                   │   │
│  │ • Protein classification (artifact detection)            │   │
│  │ • Genomic context analysis                               │   │
│  │ • Pfam domain search                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ MANUAL TESTS (Sampling)                                  │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ • HHblits/HHpred remote homology (n=20)                  │   │
│  │ • ESMFold + Foldseek structural search (n=10)            │   │
│  │ • NCBI nr spot check (n=10)                              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│ Output: Classification report                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 8: FINAL CLASSIFICATION                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Type A    │  │   Type B    │  │   Type C    │             │
│  │  Completely │  │  Structure  │  │   Remote    │             │
│  │    Novel    │  │    Known    │  │  Homolog    │             │
│  │   10-20%    │  │   20-30%    │  │   30-40%    │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐                              │
│  │   Type D    │  │   Type E    │                              │
│  │   Domain    │  │  Artifact   │                              │
│  │   Hybrid    │  │  (remove)   │                              │
│  │   10-15%    │  │    5-10%    │                              │
│  └─────────────┘  └─────────────┘                              │
│                                                                 │
│ Output: truly_novel.faa, VERIFICATION_REPORT.md                 │
└─────────────────────────────────────────────────────────────────┘
```

## Detailed Database Comparison

| Database | Size | Type | Purpose | Colab Feasible |
|----------|------|------|---------|----------------|
| UniRef90 | 184M proteins, ~35GB | Clustered | Primary novelty | ✅ Yes |
| SwissProt | 570K proteins, ~300MB | Curated | Annotations | ✅ Yes |
| Human | 20K proteins, ~50MB | Reference | Contamination | ✅ Yes |
| Pfam-A | 20K HMMs, ~300MB | Domains | Classification | ✅ Yes |
| NCBI nr | 600M+ proteins, ~300GB | Complete | Spot check | ⚠️ Manual only |

## Identity Threshold Explanation

```
Identity % = How similar two protein sequences are

Example:
Protein A: MVLSPADKTNVKAAWGKVGAHAGEYGAEALERM
Protein B: MVLSGEDKSNIKAAWGKIGGHGAEYGAEALERM
           *** * ** * ****** * ************
           25/33 = 75% identity (very similar)

Thresholds used in research:
├── >90% identity = Same protein (nearly identical)
├── >50% identity = Same family (clear homologs)
├── >25% identity = Distant relationship (may share function)
├── <25% identity = NO detectable relationship = NOVEL
└── Note: 25% is "twilight zone" - below this, random chance

WHY 25%?
- Below 25% identity, sequences are statistically indistinguishable from random
- If your protein has <25% match to ANY known protein → genuinely novel
- This is a CONSERVATIVE threshold (strict)
```
