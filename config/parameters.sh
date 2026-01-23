#!/bin/bash
# Silent Hunter v6.0 - Pipeline Parameters
# Source this file in pipeline scripts

# ============================================
# Directory Configuration
# ============================================

# Base directory (modify for your environment)
export BASE_DIR="${BASE_DIR:-/content/drive/MyDrive/SilentHunter_v6}"

# Subdirectories
export DATA_DIR="${BASE_DIR}/data"
export INTERMEDIATE_DIR="${BASE_DIR}/intermediate"
export DB_DIR="${BASE_DIR}/databases"
export OUTPUT_DIR="${BASE_DIR}/output"
export AUDIT_DIR="${BASE_DIR}/audit"

# Create directories if they don't exist
mkdir -p "$DATA_DIR" "$INTERMEDIATE_DIR" "$DB_DIR" "$OUTPUT_DIR" "$AUDIT_DIR"

# ============================================
# Data Configuration
# ============================================

# SRA Accession (ISS Metagenome GLDS-69)
export SRA_ACCESSION="SRR6356483"

# ============================================
# Tool Parameters
# ============================================

# General
export THREADS="${THREADS:-4}"

# fastp (QC)
export FASTP_WINDOW_SIZE=4
export FASTP_QUALITY=20
export FASTP_MIN_LENGTH=50

# MEGAHIT (Assembly)
export MEGAHIT_MIN_CONTIG=500
export MEGAHIT_K_MIN=21
export MEGAHIT_K_MAX=141
export MEGAHIT_K_STEP=12
export MEGAHIT_MEMORY="0.9"

# DIAMOND (Homology search)
export DIAMOND_IDENTITY=25
export DIAMOND_EVALUE="1e-5"

# Quality filtering
export MIN_PROTEIN_LENGTH=100

# ============================================
# Logging Functions
# ============================================

log_command() {
    local cmd="$1"
    local output="${2:-}"
    local timestamp=$(date -Iseconds)

    {
        echo ""
        echo "============================================================"
        echo "TIME: $timestamp"
        echo "CMD: $cmd"
        if [[ -n "$output" ]]; then
            echo "OUTPUT: ${output:0:500}..."
        fi
    } >> "${AUDIT_DIR}/commands.log"

    echo "[LOGGED] ${cmd:0:50}..."
}

# ============================================
# Validation
# ============================================

# Check required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "WARNING: $1 not found in PATH"
        return 1
    fi
    return 0
}

# Print configuration
print_config() {
    echo "Silent Hunter v6.0 Configuration"
    echo "================================="
    echo "BASE_DIR: $BASE_DIR"
    echo "SRA_ACCESSION: $SRA_ACCESSION"
    echo "THREADS: $THREADS"
    echo ""
    echo "fastp: window=$FASTP_WINDOW_SIZE, quality=$FASTP_QUALITY, min_len=$FASTP_MIN_LENGTH"
    echo "MEGAHIT: min_contig=$MEGAHIT_MIN_CONTIG, k=$MEGAHIT_K_MIN-$MEGAHIT_K_MAX"
    echo "DIAMOND: identity=$DIAMOND_IDENTITY%, evalue=$DIAMOND_EVALUE"
    echo "Filter: min_protein_length=$MIN_PROTEIN_LENGTH"
    echo ""
}
