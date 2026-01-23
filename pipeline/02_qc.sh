#!/bin/bash
# Silent Hunter v6.0 - Step 2: Quality Control
# Quality filtering with fastp

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/parameters.sh"

echo "=============================================="
echo "STEP 2: QUALITY CONTROL"
echo "=============================================="
echo "Start time: $(date -Iseconds)"

# Input files
R1="${DATA_DIR}/raw/${SRA_ACCESSION}_1.fastq.gz"
R2="${DATA_DIR}/raw/${SRA_ACCESSION}_2.fastq.gz"

# Output directory
mkdir -p "${DATA_DIR}/clean"

# Output files
CLEAN_R1="${DATA_DIR}/clean/clean_1.fastq.gz"
CLEAN_R2="${DATA_DIR}/clean/clean_2.fastq.gz"

echo "Input: $R1, $R2"
echo "Output: $CLEAN_R1, $CLEAN_R2"
echo ""

# Run fastp
CMD="fastp \
    -i ${R1} \
    -I ${R2} \
    -o ${CLEAN_R1} \
    -O ${CLEAN_R2} \
    --detect_adapter_for_pe \
    --cut_front --cut_tail \
    --cut_window_size ${FASTP_WINDOW_SIZE} \
    --cut_mean_quality ${FASTP_QUALITY} \
    --length_required ${FASTP_MIN_LENGTH} \
    --html ${AUDIT_DIR}/fastp_report.html \
    --json ${AUDIT_DIR}/fastp_report.json \
    --thread ${THREADS}"

log_command "$CMD"
eval "$CMD"

# Extract stats from JSON report
echo ""
echo "QC Statistics:"
python3 -c "
import json
with open('${AUDIT_DIR}/fastp_report.json') as f:
    data = json.load(f)
    before = data['summary']['before_filtering']
    after = data['summary']['after_filtering']
    print(f\"Reads before: {before['total_reads']:,}\")
    print(f\"Reads after: {after['total_reads']:,}\")
    print(f\"Survival rate: {after['total_reads']/before['total_reads']*100:.1f}%\")
    print(f\"Q20 rate after: {after['q20_rate']*100:.1f}%\")
    print(f\"Q30 rate after: {after['q30_rate']*100:.1f}%\")
"

echo ""
echo "Step 2 complete: $(date -Iseconds)"
echo "Output: ${DATA_DIR}/clean/"
log_command "Step 2 complete - QC finished"
