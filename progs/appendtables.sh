#!/usr/bin/env bash

# exit on error
set -ETeuo pipefail

n=0
debug=0
cfile=$( mktemp .tmpXXXX )

for tmpfile in "$@" ; do
    ifiles[$n]="${tmpfile}"
    afiles[$n]="$( mktemp .tmpXXXXX )"
    head -n 1 "${tmpfile}" | sed -r 's/\r//g;s/;+$//g;' | tr ';' '\t' | sed -r 's/[ \t]+$//g;' \
    | tr '[:lower:]' '[:upper:]' | sed 's/\t/\n/g;' | cat -n | sed -r 's/^[ \t]+//g;' \
    | sort -t $'\t' -u -k 2,2 > "${afiles[$n]}"
    n=$(( n + 1 ))
done

# the field number in cfile is only for sorting purposes
sort -t $'\t' -u -k 2,2 "${afiles[@]}" | sort -t $'\t' -k 1,1n | awk '{
  OFS=FS="\t"; print( $2, $1 );
}' > ${cfile}

if [[ -s ${cfile} ]] ; then

    sort -k 2,2n $cfile | cut -f 1 | transpose.perl | awk -F $'\t' '{ OFS = "\t"; print; }'

    if (( ${debug} )) ; then echo "============================================================="; fi

    n=0
    for afile in "${afiles[@]}" ; do

        m=0
        for cf in $( sort -k 2,2n $cfile | cut -f 1 ) ; do
            fnum=$( grep -m1 -i -w "${cf}" $afile | cut -f 1 || true )
            tmpfields[$m]="${fnum}"
            m=$((m + 1))
        done

        if (( ${debug} )) ; then
            echo "${ifiles[$n]} + + + + + + + + + + + + + + + + + + + + + + + +"
            printf "%d\t" "${tmpfields[@]}"
            printf "\n"
        fi

        printf "%d\n" "${tmpfields[@]}" | awk -F '[;\t]' -v debug=${debug} \
            --source '{
            OFS = "\t";
            if ( FNR == NR ) {
                fnum[NR] = $0; # the field numbers are read from tmpfields
            }
            else {
                if ( FNR == 1 ) {
                    for ( k = 1; k <= NF; k++ ) {
                        fieldnames[k] = $k
                    }
                }
                if ( debug == 0 && FNR > 1 || debug == 1 && FNR == 1 ) {
                    for ( k = 1; k <= length(fnum); k++ ) {
                        if ( fnum[k] == 0 )
                          printf( "__NA__" )
                        else {
                          gsub( "\r", "", $(fnum[k]) )
                          gsub( "^[ ]+", "", $(fnum[k]) )
                          gsub( "[ ]+$", "", $(fnum[k]) )
                          printf( "%s", $(fnum[k]) )
                        }
                        if ( k == length(fnum) ) printf("\n");
                        else printf("\t");
                    }
                }
            }
        }' /dev/stdin "${ifiles[$n]}" | perl -p -e 's/\r//g; s/^[ ]+//g; s/[ ]+$//g;' | awk -F '[;\t]' '{
            OFS = "\t";
            myflag = 0;
            for ( k = 1; k <= NF; k++ )
                if ( $k != "" ) myflag = 1;
            if ( myflag ) print;
        }'

        n=$((n + 1))

    done

else

    echo "no matching header items."

fi

rm $cfile
for afile in "${afiles[@]}" ; do
    rm $afile
done

