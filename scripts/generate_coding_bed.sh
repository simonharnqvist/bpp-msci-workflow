awk '$3="CDS"' $1 | awk '{{print $1, $4, $5}}' | awk '!visited[$0]++' | sed '/^#/d' | sed 's/ /\t/g'
