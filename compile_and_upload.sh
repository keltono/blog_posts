#!/bin/bash
set -eu

outfile="$(echo $1 | sed 's/.*\///;s/\..*//').html"
./blogify.sh $1 ./output/$outfile
rsync -avzz ./output/$outfile cattown:/mnt/website/blog/$outfile
