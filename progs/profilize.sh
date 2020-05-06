#!/bin/bash
mapfile=/tsd/p33/data/durable/vault/genetics/all_samples_wGTstatus_05122017_simple_IID_CLmapped.txt
for sfile in $* ; do
    unset cnt
    unset pheno
    ( echo -e "FID\tIID\tSCORE"
        sort -k 1,1 $sfile | sed -r 's/[ \t]+/\t/g;' | join -a2 -t $'\t' <( sort -t $'\t' -k 1,1 ${mapfile} ) - \
        | awk -F $'\t' '{
            OFS="\t"
            $1=$1";"
            if ( NF > 4 ) {
                $1 = $1 $3;
                $2 = $4;
                $3 = $5;
            }
            print( $1, $2, $3 );
        }'
    ) | while read fid iid score ; do
        printf "%32s %16s %6s %6s %6s %12s\n" $fid $iid "${pheno:-PHENO}" ${cnt:-CNT} ${cnt:-CNT2} $score
        cnt=0; pheno="-9"
    done
done
