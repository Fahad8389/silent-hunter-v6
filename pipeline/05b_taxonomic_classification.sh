#!/bin/bash
# Silent Hunter v6.0 - Step 5B: Taxonomic Classification
# Assigns microbial source to each contig/protein

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/parameters.sh"

echo "=============================================="
echo "STEP 5B: TAXONOMIC CLASSIFICATION"
echo "=============================================="
echo "Start time: $(date -Iseconds)"

# Input
CONTIGS="${INTERMEDIATE_DIR}/assembly/final.contigs.fa"
PROTEINS="${INTERMEDIATE_DIR}/orfs/proteins.faa"

# Output directory
TAX_DIR="${INTERMEDIATE_DIR}/taxonomy"
mkdir -p "$TAX_DIR"

echo "Input: $CONTIGS"
echo "Output: $TAX_DIR"
echo ""

# ============================================
# Option 1: Kraken2 (if database available)
# ============================================
if command -v kraken2 &> /dev/null && [[ -d "${DB_DIR}/kraken2_db" ]]; then
    echo "--- Running Kraken2 ---"

    CMD="kraken2 \
        --db ${DB_DIR}/kraken2_db \
        --threads ${THREADS} \
        --output ${TAX_DIR}/kraken2_output.txt \
        --report ${TAX_DIR}/kraken2_report.txt \
        ${CONTIGS}"

    log_command "$CMD"
    eval "$CMD"

    echo "Kraken2 classification complete"

# ============================================
# Option 2: CAT (Contig Annotation Tool)
# ============================================
elif command -v CAT &> /dev/null; then
    echo "--- Running CAT ---"

    CMD="CAT contigs \
        -c ${CONTIGS} \
        -d ${DB_DIR}/CAT_database \
        -t ${DB_DIR}/CAT_taxonomy \
        -o ${TAX_DIR}/CAT_output \
        --nproc ${THREADS}"

    log_command "$CMD"
    eval "$CMD"

    # Add names to classification
    CAT add_names \
        -i ${TAX_DIR}/CAT_output.contig2classification.txt \
        -o ${TAX_DIR}/CAT_named.txt \
        -t ${DB_DIR}/CAT_taxonomy \
        --only_official

    echo "CAT classification complete"

# ============================================
# Option 3: DIAMOND + LCA (Lightweight)
# ============================================
else
    echo "--- Running DIAMOND + LCA classification ---"
    echo "(Kraken2/CAT not found, using lightweight method)"

    # Use DIAMOND taxonomy mode
    CMD="diamond blastp \
        -q ${PROTEINS} \
        -d ${DB_DIR}/uniref90 \
        -o ${TAX_DIR}/diamond_tax.m8 \
        --outfmt 6 qseqid sseqid pident length evalue staxids sscinames \
        --id 50 \
        --evalue 1e-10 \
        --max-target-seqs 1 \
        --threads ${THREADS}"

    log_command "$CMD"
    eval "$CMD" 2>/dev/null || echo "Note: Taxonomy fields require taxonmap database"
fi

# ============================================
# Create Protein-to-Organism Mapping
# ============================================
echo ""
echo "--- Creating protein-to-organism mapping ---"

python3 << 'PYEOF'
import os
import re
from collections import defaultdict

tax_dir = os.environ.get('TAX_DIR', 'taxonomy')
proteins_file = os.environ.get('PROTEINS', 'proteins.faa')
output_file = os.path.join(tax_dir, 'protein_taxonomy.tsv')

# Parse contig taxonomy (from Kraken2 or CAT)
contig_tax = {}

# Try Kraken2 output
kraken_file = os.path.join(tax_dir, 'kraken2_output.txt')
if os.path.exists(kraken_file):
    with open(kraken_file) as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 3:
                contig_id = parts[1]
                tax_id = parts[2]
                contig_tax[contig_id] = tax_id
    print(f"Loaded {len(contig_tax)} contig classifications from Kraken2")

# Try CAT output
cat_file = os.path.join(tax_dir, 'CAT_named.txt')
if os.path.exists(cat_file) and not contig_tax:
    with open(cat_file) as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 2:
                contig_id = parts[0]
                taxonomy = parts[-1] if len(parts) > 5 else "Unknown"
                contig_tax[contig_id] = taxonomy
    print(f"Loaded {len(contig_tax)} contig classifications from CAT")

# Map proteins to contigs
protein_tax = {}
with open(proteins_file) as f:
    for line in f:
        if line.startswith('>'):
            # Prodigal format: >contig_orfnum # start # end # strand # info
            protein_id = line[1:].split()[0]
            # Extract contig name (everything before last _)
            contig_id = '_'.join(protein_id.rsplit('_', 1)[:-1])

            if contig_id in contig_tax:
                protein_tax[protein_id] = contig_tax[contig_id]
            else:
                protein_tax[protein_id] = "Unclassified"

# Write output
with open(output_file, 'w') as f:
    f.write("protein_id\tcontig_id\ttaxonomy\n")
    for protein_id, tax in protein_tax.items():
        contig_id = '_'.join(protein_id.rsplit('_', 1)[:-1])
        f.write(f"{protein_id}\t{contig_id}\t{tax}\n")

print(f"Wrote {len(protein_tax)} protein taxonomies to {output_file}")

# Summary stats
tax_counts = defaultdict(int)
for tax in protein_tax.values():
    tax_counts[tax] += 1

print("\nTop organisms:")
for tax, count in sorted(tax_counts.items(), key=lambda x: -x[1])[:10]:
    print(f"  {tax}: {count}")

PYEOF

echo ""
echo "Step 5B complete: $(date -Iseconds)"
echo "Output: ${TAX_DIR}/protein_taxonomy.tsv"
log_command "Step 5B complete - Taxonomic classification finished"
