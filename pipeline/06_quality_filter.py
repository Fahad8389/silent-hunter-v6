#!/usr/bin/env python3
"""
Silent Hunter v6.0 - Step 6: Quality Filtering
Filters novel proteins based on quality criteria
"""

import argparse
import os
import sys
from collections import defaultdict
from pathlib import Path

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

def get_hit_ids(filepath):
    """Extract protein IDs from DIAMOND m8 output."""
    ids = set()
    if os.path.exists(filepath):
        with open(filepath) as f:
            for line in f:
                ids.add(line.split('\t')[0])
    return ids

def quality_filter(header, sequence, min_length=100):
    """
    Apply quality filters to a protein sequence.
    Returns (passed, reason) tuple.
    """
    # Filter 1: Minimum length
    if len(sequence) < min_length:
        return False, 'short'

    # Filter 2: Must start with Methionine
    if not sequence.startswith('M'):
        return False, 'no_start'

    # Filter 3: No internal stop codons
    if '*' in sequence[:-1]:
        return False, 'internal_stop'

    # Filter 4: Complete ORF (not partial)
    # Prodigal marks partial ORFs in header
    if 'partial=10' in header or 'partial=01' in header or 'partial=11' in header:
        return False, 'partial'

    return True, 'passed'

def main():
    parser = argparse.ArgumentParser(description='Quality filter novel proteins')
    parser.add_argument('--proteins', required=True, help='Input proteins FASTA')
    parser.add_argument('--uniref90-hits', required=True, help='UniRef90 hits m8 file')
    parser.add_argument('--swissprot-hits', required=True, help='SwissProt hits m8 file')
    parser.add_argument('--human-hits', required=True, help='Human hits m8 file')
    parser.add_argument('--output', required=True, help='Output filtered FASTA')
    parser.add_argument('--stats', required=True, help='Output statistics file')
    parser.add_argument('--min-length', type=int, default=100, help='Minimum protein length')
    args = parser.parse_args()

    print("=" * 60)
    print("STEP 6: QUALITY FILTERING")
    print("=" * 60)

    # Load all proteins
    print("\nLoading proteins...")
    all_proteins = dict(parse_fasta(args.proteins))
    print(f"Total proteins: {len(all_proteins):,}")

    # Load hit IDs from all databases
    print("\nLoading database hits...")
    uniref90_hits = get_hit_ids(args.uniref90_hits)
    swissprot_hits = get_hit_ids(args.swissprot_hits)
    human_hits = get_hit_ids(args.human_hits)

    print(f"UniRef90 hits: {len(uniref90_hits):,}")
    print(f"SwissProt hits: {len(swissprot_hits):,}")
    print(f"Human hits: {len(human_hits):,}")

    # Find novel proteins (no hits in ANY database)
    all_hits = uniref90_hits | swissprot_hits | human_hits
    novel_ids = set(all_proteins.keys()) - all_hits

    print(f"\nNovel proteins (no database hits): {len(novel_ids):,}")

    # Apply quality filters
    print("\nApplying quality filters...")
    filtered = []
    rejected = defaultdict(int)

    for pid in novel_ids:
        header = pid
        sequence = all_proteins[pid]
        passed, reason = quality_filter(header, sequence, args.min_length)

        if passed:
            filtered.append((header, sequence))
        else:
            rejected[reason] += 1

    # Write filtered proteins
    print(f"\nWriting {len(filtered):,} filtered proteins...")
    with open(args.output, 'w') as f:
        for header, seq in filtered:
            f.write(f'>{header}\n{seq}\n')

    # Print statistics
    print("\n" + "=" * 60)
    print("FILTERING STATISTICS")
    print("=" * 60)
    print(f"Input (novel): {len(novel_ids):,}")
    print(f"Output (filtered): {len(filtered):,}")
    print(f"Retention rate: {len(filtered)/len(novel_ids)*100:.1f}%")
    print("\nRejected by reason:")
    for reason, count in sorted(rejected.items(), key=lambda x: -x[1]):
        print(f"  {reason}: {count:,}")

    # Write statistics file
    with open(args.stats, 'w') as f:
        f.write("# Quality Filtering Statistics\n\n")
        f.write(f"Total proteins: {len(all_proteins):,}\n")
        f.write(f"UniRef90 hits: {len(uniref90_hits):,}\n")
        f.write(f"SwissProt hits: {len(swissprot_hits):,}\n")
        f.write(f"Human hits: {len(human_hits):,}\n")
        f.write(f"Novel (no hits): {len(novel_ids):,}\n")
        f.write(f"Quality filtered: {len(filtered):,}\n")
        f.write(f"Retention rate: {len(filtered)/len(novel_ids)*100:.1f}%\n\n")
        f.write("Rejected by reason:\n")
        for reason, count in sorted(rejected.items(), key=lambda x: -x[1]):
            f.write(f"  {reason}: {count:,}\n")

    print(f"\nStep 6 complete. Output: {args.output}")
    return 0

if __name__ == '__main__':
    sys.exit(main())
