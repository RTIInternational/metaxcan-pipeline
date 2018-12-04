#!/usr/bin/env bash

# Input file from cmd line
INPUT=$1

# Chromosome
CHROM=$2

# Send header to stdout
grep "chromosome" $INPUT

# Loop through and send lines matching chromosome to stdout
perl -lane 'if ($F[0] == '$CHROM') { print; }' $INPUT