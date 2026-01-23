#!/bin/bash
# Silent Hunter v6.0 - Master Pipeline Script
# Runs the complete pipeline from download to verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/parameters.sh"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    SILENT HUNTER v6.0 PIPELINE                    ║"
echo "║                    100% DATA - PUBLICATION READY                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Start time: $(date -Iseconds)"
echo ""

# Initialize audit log
mkdir -p "$AUDIT_DIR"
echo "Pipeline started: $(date -Iseconds)" > "${AUDIT_DIR}/timestamps.log"
echo "" > "${AUDIT_DIR}/commands.log"
touch "${AUDIT_DIR}/checksums.md5"

# Function to run a step with timing
run_step() {
    local step_name="$1"
    local script="$2"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: $step_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local start_time=$(date +%s)
    echo "$step_name started: $(date -Iseconds)" >> "${AUDIT_DIR}/timestamps.log"

    bash "$script"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "$step_name completed: $(date -Iseconds) (${duration}s)" >> "${AUDIT_DIR}/timestamps.log"
    echo "Completed in ${duration} seconds"
}

# Parse command line arguments
SKIP_DOWNLOAD=false
SKIP_QC=false
SKIP_ASSEMBLY=false
START_FROM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-download)
            SKIP_DOWNLOAD=true
            shift
            ;;
        --skip-qc)
            SKIP_QC=true
            shift
            ;;
        --skip-assembly)
            SKIP_ASSEMBLY=true
            shift
            ;;
        --start-from)
            START_FROM="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-download    Skip step 1 (data download)"
            echo "  --skip-qc          Skip step 2 (quality control)"
            echo "  --skip-assembly    Skip step 3 (assembly)"
            echo "  --start-from N     Start from step N (1-7)"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Determine which steps to run
run_step1=true
run_step2=true
run_step3=true
run_step4=true
run_step5=true
run_step6=true
run_step7=true

if [[ -n "$START_FROM" ]]; then
    case $START_FROM in
        2) run_step1=false ;;
        3) run_step1=false; run_step2=false ;;
        4) run_step1=false; run_step2=false; run_step3=false ;;
        5) run_step1=false; run_step2=false; run_step3=false; run_step4=false ;;
        6) run_step1=false; run_step2=false; run_step3=false; run_step4=false; run_step5=false ;;
        7) run_step1=false; run_step2=false; run_step3=false; run_step4=false; run_step5=false; run_step6=false ;;
    esac
fi

[[ "$SKIP_DOWNLOAD" == true ]] && run_step1=false
[[ "$SKIP_QC" == true ]] && run_step2=false
[[ "$SKIP_ASSEMBLY" == true ]] && run_step3=false

# Run pipeline steps
[[ "$run_step1" == true ]] && run_step "Step 1: Data Download" "${SCRIPT_DIR}/01_download.sh"
[[ "$run_step2" == true ]] && run_step "Step 2: Quality Control" "${SCRIPT_DIR}/02_qc.sh"
[[ "$run_step3" == true ]] && run_step "Step 3: Assembly" "${SCRIPT_DIR}/03_assembly.sh"
[[ "$run_step4" == true ]] && run_step "Step 4: ORF Prediction" "${SCRIPT_DIR}/04_orf_prediction.sh"
[[ "$run_step5" == true ]] && run_step "Step 5: Homology Search" "${SCRIPT_DIR}/05_homology_search.sh"

# Step 6: Quality Filtering (Python)
if [[ "$run_step6" == true ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: Step 6: Quality Filtering"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    python3 "${SCRIPT_DIR}/06_quality_filter.py" \
        --proteins "${INTERMEDIATE_DIR}/orfs/proteins.faa" \
        --uniref90-hits "${INTERMEDIATE_DIR}/diamond/uniref90_hits.m8" \
        --swissprot-hits "${INTERMEDIATE_DIR}/diamond/swissprot_hits.m8" \
        --human-hits "${INTERMEDIATE_DIR}/diamond/human_hits.m8" \
        --output "${OUTPUT_DIR}/truly_novel.faa" \
        --stats "${OUTPUT_DIR}/filtering_stats.txt" \
        --min-length "${MIN_PROTEIN_LENGTH}"
fi

# Step 7: Verification (Python)
if [[ "$run_step7" == true ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: Step 7: Verification Suite"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    python3 "${SCRIPT_DIR}/07_verification.py" \
        --proteins "${OUTPUT_DIR}/truly_novel.faa" \
        --human-hits "${INTERMEDIATE_DIR}/diamond/human_hits.m8" \
        --gff "${INTERMEDIATE_DIR}/orfs/genes.gff" \
        --output-report "${OUTPUT_DIR}/VERIFICATION_REPORT.md" \
        --output-json "${OUTPUT_DIR}/verification_results.json" \
        --generate-samples
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    PIPELINE COMPLETE                              ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "End time: $(date -Iseconds)"
echo "Pipeline completed: $(date -Iseconds)" >> "${AUDIT_DIR}/timestamps.log"
echo ""
echo "Output files:"
echo "  - Novel proteins: ${OUTPUT_DIR}/truly_novel.faa"
echo "  - Verification report: ${OUTPUT_DIR}/VERIFICATION_REPORT.md"
echo "  - Audit log: ${AUDIT_DIR}/commands.log"
echo ""
echo "Next steps:"
echo "  1. Run manual HHblits verification (see report)"
echo "  2. Run manual Foldseek verification (see report)"
echo "  3. Complete NCBI nr spot check"
echo "  4. Update verification report with results"
