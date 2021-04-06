#!/bin/bash
set -eu

pandoc  $1 -s --highlight-style breezedark -o $2.temp.html
sed '1s/^/<h2><a href="\/articles\.html">Back to index<\/a><\/h2>/' $2.temp.html > $2.temp
sed 's/^<\/head>.*/<link rel="stylesheet" href="https:\/\/latex.now.sh\/style.css">\n<link rel="stylesheet" href="\/styles\/blagstyle.css"><\/head>/g' $2.temp > $2
rm $2.temp $2.temp.html

