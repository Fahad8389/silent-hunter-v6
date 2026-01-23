#!/bin/bash
# Silent Hunter v6.0 - Step 1: Data Download
# Downloads 100% of ISS metagenome data from SRA

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/parameters.sh"

echo "=============================================="
echo "STEP 1: DATA ACQUISITION"
echo "=============================================="
echo "Start time: $(date -Iseconds)"

# Create output directory
mkdir -p "${DATA_DIR}/raw"

# Log command
log_command "fastq-dump --split-files --gzip ${SRA_ACCESSION}"

# Download data
echo "Downloading ${SRA_ACCESSION}..."
fastq-dump --split-files --gzip \
    --outdir "${DATA_DIR}/raw" \
    "${SRA_ACCESSION}"

# Verify download
echo ""
echo "Verifying download..."
R1="${DATA_DIR}/raw/${SRA_ACCESSION}_1.fastq.gz"
R2="${DATA_DIR}/raw/${SRA_ACCESSION}_2.fastq.gz"

if [[ ! -f "$R1" ]] || [[ ! -f "$R2" ]]; then
    echo "ERROR: Downloaded files not found"
    exit 1
fi

# Calculate file sizes
echo "File sizes:"
ls -lh "${DATA_DIR}/raw/"*.fastq.gz

# Count reads
READ_COUNT=$(zcat "$R1" | wc -l | awk '{print $1/4}')
echo "Read count (R1): ${READ_COUNT}"

# Calculate checksums
echo "Calculating checksums..."
md5sum "${DATA_DIR}/raw/"*.fastq.gz > "${AUDIT_DIR}/raw_data.md5"

# Log completion
echo ""
echo "Step 1 complete: $(date -Iseconds)"
echo "Output: ${DATA_DIR}/raw/"
log_command "Step 1 complete - ${READ_COUNT} reads downloaded"
