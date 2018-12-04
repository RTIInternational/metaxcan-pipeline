#!/usr/bin/env bash

# Get input file
INPUT=$1

# Echo header to stdout
echo "variant_id"

# Output unique entries to stdout
grep -v "chromosome" $INPUT | sort | uniq