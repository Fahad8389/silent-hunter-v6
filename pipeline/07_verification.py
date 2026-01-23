#!/usr/bin/env python3
"""
Silent Hunter v6.0 - Step 7: Verification Suite
Comprehensive verification of novel protein candidates
"""

import argparse
import datetime
import json
import os
import random
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

# Expected amino acid frequencies (UniProt average)
EXPECTED_AA_FREQ = {
    'A': 0.083, 'R': 0.055, 'N': 0.041, 'D': 0.055, 'C': 0.014,
    'Q': 0.039, 'E': 0.068, 'G': 0.071, 'H': 0.023, 'I': 0.060,
    'L': 0.097, 'K': 0.058, 'M': 0.024, 'F': 0.039, 'P': 0.047,
    'S': 0.066, 'T': 0.053, 'W': 0.011, 'Y': 0.029, 'V': 0.069
}

def parse_fasta(filepath):
    """Parse FASTA file and yield (header, sequence) tuples."""
    header = None
    sequence = []
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                if header:
                    yield header, ''.join(sequence)
                header = line[1:]
                sequence = []
            else:
                sequence.append(line)
        if header:
            yield header, ''.join(sequence)

def test_human_contamination(human_hits_file):
    """TEST 1: Check for human contamination."""
    print("\n--- TEST 1: Human Contamination ---")
    hit_count = 0
    if os.path.exists(human_hits_file):
        with open(human_hits_file) as f:
            hit_count = len(set(line.split('\t')[0] for line in f))

    verdict = "PASS" if hit_count == 0 else "FAIL"
    print(f"Human matches: {hit_count}")
    print(f"Verdict: {verdict}")
    return {'test': 'human_contamination', 'matches': hit_count, 'verdict': verdict}

def test_aa_composition(proteins):
    """TEST 2: Amino acid composition analysis."""
    print("\n--- TEST 2: Amino Acid Composition ---")

    # Combine all sequences
    all_aa = ''.join(seq for _, seq in proteins)
    counts = Counter(all_aa)

    # Only count standard amino acids
    total = sum(counts.get(aa, 0) for aa in EXPECTED_AA_FREQ.keys())

    # Calculate chi-squared
    chi_sq = 0
    print("\nAmino Acid Frequencies:")
    print(f"{'AA':<4} {'Expected':>10} {'Observed':>10} {'Diff':>10}")
    print("-" * 36)

    for aa in sorted(EXPECTED_AA_FREQ.keys()):
        expected = EXPECTED_AA_FREQ[aa]
        observed = counts.get(aa, 0) / total if total > 0 else 0
        diff = observed - expected
        chi_sq += ((observed - expected) ** 2) / expected
        print(f"{aa:<4} {expected:>10.4f} {observed:>10.4f} {diff:>+10.4f}")

    print(f"\nChi-squared: {chi_sq:.4f}")
    print("Interpretation: <0.3 = normal, 0.3-0.5 = unusual, >0.5 = suspicious")

    verdict = "PASS" if chi_sq < 0.3 else ("REVIEW" if chi_sq < 0.5 else "FAIL")
    print(f"Verdict: {verdict}")

    return {'test': 'aa_composition', 'chi_squared': chi_sq, 'verdict': verdict}

def classify_protein(seq):
    """TEST 4: Classify protein as likely real or possibly artifact."""
    issues = []

    # Check for repetitive sequences
    for aa in 'AGLPQRS':
        if aa * 5 in seq:
            issues.append('repetitive')
            break

    # Check hydrophobicity
    hydrophobic = sum(1 for a in seq if a in 'AILMFWV')
    if hydrophobic / len(seq) > 0.6:
        issues.append('too_hydrophobic')

    # Check charge
    charged = sum(1 for a in seq if a in 'DEKR')
    if charged / len(seq) > 0.4:
        issues.append('too_charged')

    # Check for low complexity (single AA > 30%)
    counts = Counter(seq)
    max_freq = max(counts.values()) / len(seq)
    if max_freq > 0.3:
        issues.append('low_complexity')

    return 'likely_real' if len(issues) == 0 else 'possibly_artifact', issues

def test_protein_classification(proteins):
    """TEST 4: Protein classification."""
    print("\n--- TEST 4: Protein Classification ---")

    real_count = 0
    artifact_count = 0
    issue_counts = defaultdict(int)

    for header, seq in proteins:
        classification, issues = classify_protein(seq)
        if classification == 'likely_real':
            real_count += 1
        else:
            artifact_count += 1
            for issue in issues:
                issue_counts[issue] += 1

    total = real_count + artifact_count
    real_pct = real_count / total * 100 if total > 0 else 0

    print(f"Likely real: {real_count} ({real_pct:.1f}%)")
    print(f"Possibly artifact: {artifact_count}")

    if issue_counts:
        print("\nArtifact reasons:")
        for issue, count in sorted(issue_counts.items(), key=lambda x: -x[1]):
            print(f"  {issue}: {count}")

    verdict = "PASS" if real_pct > 90 else ("REVIEW" if real_pct > 80 else "FAIL")
    print(f"Verdict: {verdict}")

    return {
        'test': 'protein_classification',
        'likely_real': real_count,
        'possibly_artifact': artifact_count,
        'real_percentage': real_pct,
        'verdict': verdict
    }

def test_genomic_context(gff_file, novel_ids):
    """TEST 9: Genomic context analysis."""
    print("\n--- TEST 9: Genomic Context ---")

    if not os.path.exists(gff_file):
        print(f"GFF file not found: {gff_file}")
        return {'test': 'genomic_context', 'verdict': 'SKIPPED'}

    # Parse GFF to get ORF positions
    contig_orfs = defaultdict(list)
    with open(gff_file) as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
            parts = line.strip().split('\t')
            if len(parts) >= 9 and parts[2] == 'CDS':
                contig = parts[0]
                start, end = int(parts[3]), int(parts[4])
                # Extract ID from attributes
                attrs = parts[8]
                match = re.search(r'ID=([^;]+)', attrs)
                if match:
                    pid = match.group(1)
                    contig_orfs[contig].append((start, end, pid))

    # Find isolated ORFs
    isolated = []
    contextual = []

    for contig, orfs in contig_orfs.items():
        for start, end, pid in orfs:
            if pid not in novel_ids:
                continue

            # Check if only ORF on contig
            if len(orfs) == 1:
                isolated.append((pid, 'only_orf_on_contig'))
            # Check if contig is very short
            elif max(e for s, e, p in orfs) - min(s for s, e, p in orfs) < 500:
                isolated.append((pid, 'very_short_contig'))
            else:
                contextual.append(pid)

    isolated_pct = len(isolated) / (len(isolated) + len(contextual)) * 100 if (len(isolated) + len(contextual)) > 0 else 0

    print(f"Isolated ORFs (lower confidence): {len(isolated)}")
    print(f"Contextual ORFs (higher confidence): {len(contextual)}")
    print(f"Isolated percentage: {isolated_pct:.1f}%")

    verdict = "PASS" if isolated_pct < 30 else ("REVIEW" if isolated_pct < 50 else "FAIL")
    print(f"Verdict: {verdict}")

    return {
        'test': 'genomic_context',
        'isolated': len(isolated),
        'contextual': len(contextual),
        'isolated_percentage': isolated_pct,
        'verdict': verdict
    }

def generate_manual_samples(proteins, n_hhblits=20, n_foldseek=10, seed=42):
    """Generate samples for manual HHblits and Foldseek verification."""
    print("\n" + "=" * 60)
    print("MANUAL VERIFICATION SAMPLES")
    print("=" * 60)

    random.seed(seed)
    protein_list = list(proteins)

    # HHblits samples
    print(f"\n--- HHblits Remote Homology Samples (n={n_hhblits}) ---")
    print("Instructions:")
    print("1. Go to: https://toolkit.tuebingen.mpg.de/tools/hhpred")
    print("2. Database: PDB_mmCIF70, UniRef30")
    print("3. Record: Match found (Type C) or No match (potentially Type A)")
    print()

    hhblits_samples = random.sample(protein_list, min(n_hhblits, len(protein_list)))
    for i, (header, seq) in enumerate(hhblits_samples, 1):
        pid = header.split()[0]
        print(f"=== HHblits Sample {i}/{n_hhblits} ===")
        print(f"ID: {pid}")
        print(f"Length: {len(seq)} aa")
        print(f"Sequence:")
        # Print in 60-char lines
        for j in range(0, len(seq), 60):
            print(seq[j:j+60])
        print()

    # Foldseek samples
    print(f"\n--- Foldseek Structural Samples (n={n_foldseek}) ---")
    print("Instructions:")
    print("1. Predict structure: https://esmatlas.com/resources?action=fold")
    print("2. Search: https://search.foldseek.com/search")
    print("3. Record: Structure match (Type B) or No match (potentially Type A)")
    print()

    foldseek_samples = random.sample(protein_list, min(n_foldseek, len(protein_list)))
    for i, (header, seq) in enumerate(foldseek_samples, 1):
        pid = header.split()[0]
        print(f"=== Foldseek Sample {i}/{n_foldseek} ===")
        print(f"ID: {pid}")
        print(f"Length: {len(seq)} aa")
        if len(seq) > 400:
            print("WARNING: >400aa, may need to truncate for ESMFold")
        print(f"Sequence:")
        for j in range(0, len(seq), 60):
            print(seq[j:j+60])
        print()

    return {
        'hhblits_samples': [h.split()[0] for h, s in hhblits_samples],
        'foldseek_samples': [h.split()[0] for h, s in foldseek_samples]
    }

def classify_novels(proteins, isolated_ids, pfam_hits=None, hhblits_results=None, foldseek_results=None):
    """Classify novel proteins into Types A-E."""
    print("\n" + "=" * 60)
    print("NOVEL PROTEIN CLASSIFICATION")
    print("=" * 60)

    classifications = {
        'type_a_completely_novel': [],
        'type_b_structure_known': [],
        'type_c_remote_homolog': [],
        'type_d_domain_hybrid': [],
        'type_e_artifact': []
    }

    # Type E: Artifacts (isolated ORFs)
    artifact_ids = set(isolated_ids)
    for pid in artifact_ids:
        classifications['type_e_artifact'].append(pid)

    # Type D: Domain hybrids (Pfam hits)
    if pfam_hits:
        for pid in pfam_hits:
            if pid not in artifact_ids:
                classifications['type_d_domain_hybrid'].append(pid)

    # Type C: Remote homologs (HHblits hits)
    if hhblits_results:
        for pid in hhblits_results:
            if pid not in artifact_ids and pid not in (pfam_hits or []):
                classifications['type_c_remote_homolog'].append(pid)

    # Type B: Structure known (Foldseek hits)
    if foldseek_results:
        for pid in foldseek_results:
            if pid not in artifact_ids:
                classifications['type_b_structure_known'].append(pid)

    # Type A: Everything else
    classified_ids = set()
    for type_list in classifications.values():
        classified_ids.update(type_list)

    for header, seq in proteins:
        pid = header.split()[0]
        if pid not in classified_ids:
            classifications['type_a_completely_novel'].append(pid)

    print("\nClassification Results:")
    print("-" * 40)
    for type_name, ids in classifications.items():
        print(f"{type_name}: {len(ids)}")

    return classifications

def generate_report(results, proteins, output_file):
    """Generate verification report."""
    now = datetime.datetime.now().isoformat()

    report = f"""# Verification Report - Silent Hunter v6.0

Generated: {now}

## Summary

| Metric | Value |
|--------|-------|
| Total novel proteins | {len(list(proteins)):,} |

## Verification Tests

| Test | Result | Verdict |
|------|--------|---------|
"""

    for test_name, test_result in results.items():
        if isinstance(test_result, dict) and 'verdict' in test_result:
            verdict = test_result['verdict']
            # Format result based on test type
            if test_name == 'human_contamination':
                result_str = f"{test_result['matches']} matches"
            elif test_name == 'aa_composition':
                result_str = f"Chi-sq = {test_result['chi_squared']:.3f}"
            elif test_name == 'protein_classification':
                result_str = f"{test_result['real_percentage']:.1f}% likely real"
            elif test_name == 'genomic_context':
                result_str = f"{test_result.get('isolated', 0)} isolated"
            else:
                result_str = str(test_result)

            report += f"| {test_name} | {result_str} | {verdict} |\n"

    report += """
## Classification (Preliminary)

| Type | Description | Count |
|------|-------------|-------|
"""

    if 'classifications' in results:
        for type_name, ids in results['classifications'].items():
            desc = {
                'type_a_completely_novel': 'No seq/struct match',
                'type_b_structure_known': 'Foldseek match',
                'type_c_remote_homolog': 'HHblits match',
                'type_d_domain_hybrid': 'Pfam domains',
                'type_e_artifact': 'Possible artifact'
            }.get(type_name, type_name)
            report += f"| {type_name} | {desc} | {len(ids)} |\n"

    report += """
## Manual Verification Required

- [ ] HHblits remote homology (20 samples)
- [ ] Foldseek structural similarity (10 samples)
- [ ] NCBI nr spot check (10 samples)
- [ ] Pfam domain search (full dataset)

## Notes

Update this report after completing manual verification steps.
"""

    with open(output_file, 'w') as f:
        f.write(report)

    print(f"\nReport written to: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='Verify novel protein candidates')
    parser.add_argument('--proteins', required=True, help='Novel proteins FASTA')
    parser.add_argument('--human-hits', help='Human hits m8 file')
    parser.add_argument('--gff', help='Prodigal GFF file')
    parser.add_argument('--output-report', required=True, help='Output report file')
    parser.add_argument('--output-json', help='Output JSON results')
    parser.add_argument('--generate-samples', action='store_true', help='Generate manual verification samples')
    args = parser.parse_args()

    print("=" * 60)
    print("STEP 7: VERIFICATION SUITE")
    print("=" * 60)

    # Load proteins
    proteins = list(parse_fasta(args.proteins))
    novel_ids = set(h.split()[0] for h, s in proteins)
    print(f"Loaded {len(proteins)} novel proteins")

    results = {}

    # Test 1: Human contamination
    if args.human_hits:
        results['human_contamination'] = test_human_contamination(args.human_hits)

    # Test 2: AA composition
    results['aa_composition'] = test_aa_composition(proteins)

    # Test 4: Protein classification
    results['protein_classification'] = test_protein_classification(proteins)

    # Test 9: Genomic context
    isolated_ids = []
    if args.gff:
        context_result = test_genomic_context(args.gff, novel_ids)
        results['genomic_context'] = context_result

    # Classification
    results['classifications'] = classify_novels(proteins, isolated_ids)

    # Generate manual samples if requested
    if args.generate_samples:
        samples = generate_manual_samples(proteins)
        results['manual_samples'] = samples

    # Generate report
    generate_report(results, proteins, args.output_report)

    # Save JSON results
    if args.output_json:
        with open(args.output_json, 'w') as f:
            json.dump(results, f, indent=2, default=str)
        print(f"JSON results written to: {args.output_json}")

    print("\nStep 7 complete.")
    return 0

if __name__ == '__main__':
    sys.exit(main())
