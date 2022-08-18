bedtools makewindows -b $1 -w 1000 | awk '{if($3-$2 <= 1000 && $3-$2 >= 500) print}' | shuf | head -n 1000
