#!/bin/bash
# Silent Hunter v6.0 - Step 5: Homology Search
# Multi-database search with DIAMOND

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/parameters.sh"

echo "=============================================="
echo "STEP 5: HOMOLOGY SEARCH (MULTI-DATABASE)"
echo "=============================================="
echo "Start time: $(date -Iseconds)"

# Input
PROTEINS="${INTERMEDIATE_DIR}/orfs/proteins.faa"
GENES="${INTERMEDIATE_DIR}/orfs/genes.fna"

# Output directory
DIAMOND_DIR="${INTERMEDIATE_DIR}/diamond"
mkdir -p "$DIAMOND_DIR"

echo "Input: $PROTEINS"
echo "Output: $DIAMOND_DIR"
echo ""

# ============================================
# 5A: UniRef90 Search (Primary)
# ============================================
echo "--- 5A: UniRef90 Search ---"

UNIREF90_DB="${DB_DIR}/uniref90.dmnd"
UNIREF90_OUT="${DIAMOND_DIR}/uniref90_hits.m8"

if [[ ! -f "$UNIREF90_DB" ]]; then
    echo "ERROR: UniRef90 database not found at $UNIREF90_DB"
    echo "Please download and build with:"
    echo "  wget https://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz"
    echo "  diamond makedb --in uniref90.fasta.gz -d uniref90"
    exit 1
fi

CMD="diamond blastp \
    -q ${PROTEINS} \
    -d ${UNIREF90_DB} \
    -o ${UNIREF90_OUT} \
    --id ${DIAMOND_IDENTITY} \
    --evalue ${DIAMOND_EVALUE} \
    --sensitive \
    --threads ${THREADS} \
    --max-target-seqs 1"

log_command "$CMD"
eval "$CMD"

UNIREF90_HITS=$(cut -f1 "$UNIREF90_OUT" | sort -u | wc -l)
echo "UniRef90 hits: $UNIREF90_HITS"

# ============================================
# 5B: SwissProt Search (Curated)
# ============================================
echo ""
echo "--- 5B: SwissProt Search ---"

SWISSPROT_DB="${DB_DIR}/swissprot.dmnd"
SWISSPROT_OUT="${DIAMOND_DIR}/swissprot_hits.m8"

if [[ ! -f "$SWISSPROT_DB" ]]; then
    echo "SwissProt database not found. Downloading..."
    wget -q -O "${DB_DIR}/swissprot.gz" https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/swissprot.gz
    gunzip -f "${DB_DIR}/swissprot.gz"
    diamond makedb --in "${DB_DIR}/swissprot" -d "${DB_DIR}/swissprot" --quiet
fi

CMD="diamond blastp \
    -q ${PROTEINS} \
    -d ${SWISSPROT_DB} \
    -o ${SWISSPROT_OUT} \
    --id ${DIAMOND_IDENTITY} \
    --evalue ${DIAMOND_EVALUE} \
    --sensitive \
    --threads ${THREADS}"

log_command "$CMD"
eval "$CMD"

SWISSPROT_HITS=$(cut -f1 "$SWISSPROT_OUT" | sort -u | wc -l)
echo "SwissProt hits: $SWISSPROT_HITS"

# ============================================
# 5C: Human Proteome (Contamination Check)
# ============================================
echo ""
echo "--- 5C: Human Contamination Check ---"

HUMAN_DB="${DB_DIR}/human.dmnd"
HUMAN_OUT="${DIAMOND_DIR}/human_hits.m8"

if [[ ! -f "$HUMAN_DB" ]]; then
    echo "Human proteome database not found. Downloading..."
    wget -q -O "${DB_DIR}/human.fasta.gz" \
        https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz
    gunzip -f "${DB_DIR}/human.fasta.gz"
    diamond makedb --in "${DB_DIR}/human.fasta" -d "${DB_DIR}/human" --quiet
fi

CMD="diamond blastp \
    -q ${PROTEINS} \
    -d ${HUMAN_DB} \
    -o ${HUMAN_OUT} \
    --id 50 \
    --evalue 1e-10 \
    --threads ${THREADS}"

log_command "$CMD"
eval "$CMD"

HUMAN_HITS=$(cut -f1 "$HUMAN_OUT" | sort -u | wc -l)
echo "Human contamination: $HUMAN_HITS proteins"

if [[ "$HUMAN_HITS" -gt 0 ]]; then
    echo "WARNING: Human contamination detected!"
fi

# ============================================
# 5D: Chimera Detection (VSEARCH UCHIME)
# ============================================
echo ""
echo "--- 5D: Chimera Detection ---"

CHIMERAS_OUT="${DIAMOND_DIR}/chimeras.fna"
CLEAN_GENES="${DIAMOND_DIR}/clean_genes.fna"

# De novo chimera detection on nucleotide sequences
CMD="vsearch \
    --uchime_denovo ${GENES} \
    --chimeras ${CHIMERAS_OUT} \
    --nonchimeras ${CLEAN_GENES} \
    --quiet"

log_command "$CMD"
if command -v vsearch &> /dev/null; then
    eval "$CMD"
    CHIMERA_COUNT=$(grep -c ">" "$CHIMERAS_OUT" 2>/dev/null || echo "0")
    echo "Potential chimeras detected: $CHIMERA_COUNT"
else
    echo "VSEARCH not installed. Skipping chimera detection."
    CHIMERA_COUNT=0
fi

# ============================================
# Summary
# ============================================
echo ""
echo "=============================================="
echo "HOMOLOGY SEARCH SUMMARY"
echo "=============================================="
TOTAL_PROTEINS=$(grep -c ">" "$PROTEINS")
echo "Total proteins: $TOTAL_PROTEINS"
echo "UniRef90 hits: $UNIREF90_HITS"
echo "SwissProt hits: $SWISSPROT_HITS"
echo "Human contamination: $HUMAN_HITS"
echo "Chimeras detected: $CHIMERA_COUNT"

# Calculate checksums
md5sum "${DIAMOND_DIR}"/*.m8 >> "${AUDIT_DIR}/checksums.md5" 2>/dev/null || true

echo ""
echo "Step 5 complete: $(date -Iseconds)"
log_command "Step 5 complete - Homology search finished"
