#!/bin/bash
input_file='/home/saurabh/Work/Data/Bergenbrainlist.txt'
KGdir='/home/checco/work/data/1000G'
for chr in $( seq 22 ) X ; do
  bedtools intersect -a ${input_file} -b ${KGdir}/1000G.chr${chr}.bed | gawk '{ 
      print( $3, "1 1" );
  }' > 1000G.chr${chr}.sparse
done
