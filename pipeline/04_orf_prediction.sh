#!/bin/bash
# Silent Hunter v6.0 - Step 4: ORF Prediction
# Gene prediction with Prodigal in metagenomic mode

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/parameters.sh"

echo "=============================================="
echo "STEP 4: ORF PREDICTION"
echo "=============================================="
echo "Start time: $(date -Iseconds)"

# Input
CONTIGS="${INTERMEDIATE_DIR}/assembly/final.contigs.fa"

# Output directory
ORF_DIR="${INTERMEDIATE_DIR}/orfs"
mkdir -p "$ORF_DIR"

# Output files
PROTEINS="${ORF_DIR}/proteins.faa"
GENES="${ORF_DIR}/genes.fna"
GFF="${ORF_DIR}/genes.gff"

echo "Input: $CONTIGS"
echo "Output: $ORF_DIR"
echo ""

# Run Prodigal
CMD="prodigal \
    -i ${CONTIGS} \
    -a ${PROTEINS} \
    -d ${GENES} \
    -o ${GFF} \
    -f gff \
    -p meta \
    -q"

log_command "$CMD"
eval "$CMD"

# Count ORFs
TOTAL_ORFS=$(grep -c ">" "$PROTEINS")
echo ""
echo "ORF Statistics:"
echo "Total proteins predicted: ${TOTAL_ORFS}"

# Length distribution
python3 << EOF
lengths = []
with open('${PROTEINS}') as f:
    seq = ''
    for line in f:
        if line.startswith('>'):
            if seq:
                lengths.append(len(seq))
            seq = ''
        else:
            seq += line.strip()
    if seq:
        lengths.append(len(seq))

lengths.sort()
print(f"Min length: {min(lengths)} aa")
print(f"Max length: {max(lengths)} aa")
print(f"Mean length: {sum(lengths)//len(lengths)} aa")
print(f"Median length: {lengths[len(lengths)//2]} aa")

# Count complete vs partial
complete = 0
partial = 0
with open('${PROTEINS}') as f:
    for line in f:
        if line.startswith('>'):
            if 'partial=00' in line:
                complete += 1
            else:
                partial += 1
print(f"Complete ORFs: {complete}")
print(f"Partial ORFs: {partial}")
EOF

# Calculate checksums
md5sum "$PROTEINS" "$GENES" "$GFF" >> "${AUDIT_DIR}/checksums.md5"

echo ""
echo "Step 4 complete: $(date -Iseconds)"
echo "Output: ${ORF_DIR}/"
log_command "Step 4 complete - ${TOTAL_ORFS} ORFs predicted"
