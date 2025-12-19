#!/usr/bin/env python3
import sys
import subprocess

def get_lengths(fasta_file):
        """Get contig lengths using seqtk"""
        lengths = {}
        result = subprocess.run(['seqtk', 'comp', fasta_file], capture_output=True, text=True)
        for line in result.stdout.strip().split('\n'):
                if line:
                        fields = line.split('\t')
                        lengths[fields[0]] = int(fields[1])
        return lengths
def main():
        if len(sys.argv) != 4:
                sys.exit(1)

        blast_file, query_fasta, subject_fasta = sys.argv[1:4]

        query_lengths = get_lengths(query_fasta)
        subject_lengths = get_lengths(subject_fasta)

        matches = {}
        with open(blast_file) as f:
                for line in f:
                        vs = line.split()
                        if len(vs) >= 12:
                                pair = (vs[0], vs[1])
                                length = int(vs[3])
                                identity = float(vs[2])

                                if pair not in matches:
                                        matches[pair] = [length, identity]
                                else:
                                        curr_len, curr_id = matches[pair]
                                        if length > curr_len:
                                                matches[pair] = [length, identity]
                                        elif length == curr_len and identity > curr_id:
                                                matches[pair] = [length, identity]

        if not matches:
                sys.exit(1)

        biggest = max(matches, key=lambda x: matches[x][0])
        overlap, identity = matches[biggest]

        query_id, subject_id = biggest
        query_len = query_lengths.get(query_id, 0)
        subject_len = subject_lengths.get(subject_id, 0)
        max_len = max(query_len, subject_len)
        min_len = min(query_len, subject_len)
        ratio = min(overlap / max_len, 1.0) if max_len > 0 else 0


if __name__ == "__main__":
        main()
