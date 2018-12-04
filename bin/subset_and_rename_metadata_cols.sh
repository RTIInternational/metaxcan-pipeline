#!/usr/bin/env bash

# Get input file
INPUT=$1

# Shift to be able to pass columns to cut function
shift

# Cut out the columns specified on the command line and replace certain words
cat $INPUT | cut -d$'\t' -f "$*" \
    | sed 's/Allele1/A1/g' \
    | sed 's/Allele2/A2/g' \
	| sed 's/Effect/BETA/g' \
	| sed 's/P.value/P/g'