#!/usr/bin/env python3
"""
Silent Hunter v6.0 - Step 8: Create Final Results Table
Creates a comprehensive table with protein info and microbial source
"""

import argparse
import csv
import os
import sys
from collections import defaultdict

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

def load_taxonomy(tax_file):
    """Load protein taxonomy mapping."""
    tax_map = {}
    if os.path.exists(tax_file):
        with open(tax_file) as f:
            reader = csv.DictReader(f, delimiter='\t')
            for row in reader:
                tax_map[row['protein_id']] = {
                    'contig': row['contig_id'],
                    'taxonomy': row['taxonomy']
                }
    return tax_map

def load_classifications(json_file):
    """Load protein classifications from verification."""
    import json
    if os.path.exists(json_file):
        with open(json_file) as f:
            data = json.load(f)
            return data.get('classifications', {})
    return {}

def get_protein_type(protein_id, classifications):
    """Get the classification type for a protein."""
    for type_name, ids in classifications.items():
        if protein_id in ids or any(protein_id in str(i) for i in ids):
            return type_name.replace('type_', 'Type ').replace('_', ' ').title()
    return "Type A Completely Novel"

def calculate_properties(sequence):
    """Calculate basic protein properties."""
    length = len(sequence)

    # Molecular weight (approximate)
    aa_weights = {
        'A': 89, 'R': 174, 'N': 132, 'D': 133, 'C': 121,
        'Q': 146, 'E': 147, 'G': 75, 'H': 155, 'I': 131,
        'L': 131, 'K': 146, 'M': 149, 'F': 165, 'P': 115,
        'S': 105, 'T': 119, 'W': 204, 'Y': 181, 'V': 117
    }
    mw = sum(aa_weights.get(aa, 110) for aa in sequence) - (length - 1) * 18
    mw_kda = mw / 1000

    # Hydrophobicity (Kyte-Doolittle)
    hydro = {'A': 1.8, 'R': -4.5, 'N': -3.5, 'D': -3.5, 'C': 2.5,
             'Q': -3.5, 'E': -3.5, 'G': -0.4, 'H': -3.2, 'I': 4.5,
             'L': 3.8, 'K': -3.9, 'M': 1.9, 'F': 2.8, 'P': -1.6,
             'S': -0.8, 'T': -0.7, 'W': -0.9, 'Y': -1.3, 'V': 4.2}
    gravy = sum(hydro.get(aa, 0) for aa in sequence) / length if length > 0 else 0

    # Charge at pH 7
    pos_charge = sequence.count('R') + sequence.count('K') + sequence.count('H') * 0.1
    neg_charge = sequence.count('D') + sequence.count('E')
    net_charge = pos_charge - neg_charge

    return {
        'length': length,
        'mw_kda': round(mw_kda, 2),
        'gravy': round(gravy, 3),
        'net_charge': round(net_charge, 1)
    }

def main():
    parser = argparse.ArgumentParser(description='Create final results table')
    parser.add_argument('--proteins', required=True, help='Novel proteins FASTA')
    parser.add_argument('--taxonomy', required=True, help='Protein taxonomy TSV')
    parser.add_argument('--classifications', help='Verification JSON file')
    parser.add_argument('--output-tsv', required=True, help='Output TSV file')
    parser.add_argument('--output-summary', required=True, help='Output summary markdown')
    args = parser.parse_args()

    print("=" * 60)
    print("STEP 8: CREATE FINAL RESULTS TABLE")
    print("=" * 60)

    # Load data
    print("\nLoading proteins...")
    proteins = list(parse_fasta(args.proteins))
    print(f"Loaded {len(proteins)} proteins")

    print("\nLoading taxonomy...")
    taxonomy = load_taxonomy(args.taxonomy)
    print(f"Loaded taxonomy for {len(taxonomy)} proteins")

    print("\nLoading classifications...")
    classifications = {}
    if args.classifications:
        classifications = load_classifications(args.classifications)

    # Build table
    print("\nBuilding results table...")
    rows = []

    for header, sequence in proteins:
        protein_id = header.split()[0]

        # Get taxonomy
        tax_info = taxonomy.get(protein_id, {'contig': 'Unknown', 'taxonomy': 'Unclassified'})

        # Get classification
        protein_type = get_protein_type(protein_id, classifications)

        # Calculate properties
        props = calculate_properties(sequence)

        rows.append({
            'protein_id': protein_id,
            'contig_id': tax_info['contig'],
            'organism': tax_info['taxonomy'],
            'classification': protein_type,
            'length_aa': props['length'],
            'mw_kda': props['mw_kda'],
            'gravy': props['gravy'],
            'net_charge': props['net_charge'],
            'sequence': sequence
        })

    # Write TSV
    print(f"\nWriting {len(rows)} proteins to {args.output_tsv}")
    with open(args.output_tsv, 'w', newline='') as f:
        fieldnames = ['protein_id', 'contig_id', 'organism', 'classification',
                      'length_aa', 'mw_kda', 'gravy', 'net_charge', 'sequence']
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter='\t')
        writer.writeheader()
        writer.writerows(rows)

    # Generate summary
    print(f"\nGenerating summary...")

    # Count by organism
    org_counts = defaultdict(int)
    for row in rows:
        org_counts[row['organism']] += 1

    # Count by classification
    class_counts = defaultdict(int)
    for row in rows:
        class_counts[row['classification']] += 1

    # Write summary markdown
    summary = f"""# Silent Hunter v6.0 - Final Results Summary

Generated: {os.popen('date -Iseconds').read().strip()}

## Overview

| Metric | Value |
|--------|-------|
| Total Novel Proteins | {len(rows):,} |
| Unique Organisms | {len(org_counts):,} |

## Proteins by Microbial Source

| Organism | Novel Proteins | % of Total |
|----------|---------------|------------|
"""
    for org, count in sorted(org_counts.items(), key=lambda x: -x[1])[:20]:
        pct = count / len(rows) * 100
        summary += f"| {org} | {count:,} | {pct:.1f}% |\n"

    if len(org_counts) > 20:
        other_count = sum(c for o, c in org_counts.items()
                         if o not in dict(sorted(org_counts.items(), key=lambda x: -x[1])[:20]))
        summary += f"| *Other ({len(org_counts)-20} organisms)* | {other_count:,} | {other_count/len(rows)*100:.1f}% |\n"

    summary += f"""
## Proteins by Classification Type

| Type | Description | Count | % |
|------|-------------|-------|---|
"""
    type_descriptions = {
        'Type A Completely Novel': 'No sequence or structure homology',
        'Type B Structure Known': 'Novel sequence, known fold',
        'Type C Remote Homolog': 'Detected by HHblits',
        'Type D Domain Hybrid': 'Known Pfam domains',
        'Type E Artifact': 'Possible assembly artifact'
    }

    for cls, count in sorted(class_counts.items()):
        desc = type_descriptions.get(cls, '')
        pct = count / len(rows) * 100
        summary += f"| {cls} | {desc} | {count:,} | {pct:.1f}% |\n"

    summary += f"""
## Length Distribution

| Range | Count | % |
|-------|-------|---|
"""
    length_bins = [(100, 200), (200, 300), (300, 500), (500, 1000), (1000, float('inf'))]
    for low, high in length_bins:
        count = sum(1 for r in rows if low <= r['length_aa'] < high)
        label = f"{low}-{high-1} aa" if high != float('inf') else f"≥{low} aa"
        summary += f"| {label} | {count:,} | {count/len(rows)*100:.1f}% |\n"

    summary += f"""
## Top 10 Novel Proteins (by length)

| Protein ID | Organism | Length | Classification |
|------------|----------|--------|----------------|
"""
    for row in sorted(rows, key=lambda x: -x['length_aa'])[:10]:
        summary += f"| {row['protein_id']} | {row['organism'][:30]} | {row['length_aa']} aa | {row['classification']} |\n"

    summary += """
## Files Generated

| File | Description |
|------|-------------|
| `novel_proteins_annotated.tsv` | Full table with all proteins and metadata |
| `truly_novel.faa` | FASTA sequences |
| `VERIFICATION_REPORT.md` | Verification test results |

## Next Steps

1. Review proteins by organism - are sources expected for ISS?
2. Prioritize Type A proteins for experimental validation
3. Check longest proteins - may be most interesting
4. Submit to NCBI/EBI for accession numbers
"""

    with open(args.output_summary, 'w') as f:
        f.write(summary)

    print(summary)
    print(f"\nStep 8 complete.")
    print(f"  Table: {args.output_tsv}")
    print(f"  Summary: {args.output_summary}")

if __name__ == '__main__':
    main()
