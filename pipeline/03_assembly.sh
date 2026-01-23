#!/bin/bash
# Silent Hunter v6.0 - Step 3: Metagenomic Assembly
# Assembly with MEGAHIT

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/parameters.sh"

echo "=============================================="
echo "STEP 3: METAGENOMIC ASSEMBLY"
echo "=============================================="
echo "Start time: $(date -Iseconds)"

# Input files
CLEAN_R1="${DATA_DIR}/clean/clean_1.fastq.gz"
CLEAN_R2="${DATA_DIR}/clean/clean_2.fastq.gz"

# Output directory
ASSEMBLY_DIR="${INTERMEDIATE_DIR}/assembly"

# Remove existing assembly dir if exists (MEGAHIT requirement)
if [[ -d "$ASSEMBLY_DIR" ]]; then
    echo "Removing existing assembly directory..."
    rm -rf "$ASSEMBLY_DIR"
fi

echo "Input: $CLEAN_R1, $CLEAN_R2"
echo "Output: $ASSEMBLY_DIR"
echo ""

# Run MEGAHIT
CMD="megahit \
    -1 ${CLEAN_R1} \
    -2 ${CLEAN_R2} \
    -o ${ASSEMBLY_DIR} \
    --min-contig-len ${MEGAHIT_MIN_CONTIG} \
    --k-min ${MEGAHIT_K_MIN} \
    --k-max ${MEGAHIT_K_MAX} \
    --k-step ${MEGAHIT_K_STEP} \
    -t ${THREADS} \
    -m ${MEGAHIT_MEMORY}"

log_command "$CMD"
eval "$CMD"

# Calculate assembly statistics
echo ""
echo "Assembly Statistics:"
python3 - "${ASSEMBLY_DIR}/final.contigs.fa" << 'PYEOF'
import sys
seqs = []
with open(sys.argv[1]) as f:
    s = ''
    for line in f:
        if line.startswith('>'):
            if s:
                seqs.append(len(s))
            s = ''
        else:
            s += line.strip()
    if s:
        seqs.append(len(s))

seqs.sort(reverse=True)
total = sum(seqs)

# Calculate N50
n50_sum = 0
n50 = 0
for l in seqs:
    n50_sum += l
    if n50_sum >= total / 2:
        n50 = l
        break

# Calculate N90
n90_sum = 0
n90 = 0
for l in seqs:
    n90_sum += l
    if n90_sum >= total * 0.9:
        n90 = l
        break

print(f"Total contigs: {len(seqs):,}")
print(f"Total assembly size: {total:,} bp")
print(f"Largest contig: {seqs[0]:,} bp")
print(f"N50: {n50:,} bp")
print(f"N90: {n90:,} bp")
print(f"Mean contig length: {total//len(seqs):,} bp")
PYEOF

# Calculate checksum
md5sum "${ASSEMBLY_DIR}/final.contigs.fa" >> "${AUDIT_DIR}/checksums.md5"

echo ""
echo "Step 3 complete: $(date -Iseconds)"
echo "Output: ${ASSEMBLY_DIR}/final.contigs.fa"
log_command "Step 3 complete - Assembly finished"
