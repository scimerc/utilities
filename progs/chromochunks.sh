#!/bin/bash

mydir=$1
declare -a chromochunks
unset chromochunks
if [[ "${mydir}" != "" ]] ; then
    if [[ -d ${mydir} ]] ; then
        for chr in $( ls ${mydir}/chunk*.dat.gz.snps | awk -F '/' '{ print $NF }' | cut -d "." -f 2 | sort -un ) ; do
            chromochunks[${chr}]="$( ls ${mydir}/chunk*.${chr}.dat.gz.snps | awk -F '/' '{ print $NF }' | cut -d "-" -f 1 \
                | sed 's|chunk||g;' | sort -n )"
        done
    else
        chromochunks=""
    fi
else
    chromochunks=""
fi


# chromochunks[1]="$( seq 9 )"
# chromochunks[2]="$( seq 9 )"
# chromochunks[3]="$( seq 8 )"
# chromochunks[4]="$( seq 7 )"
# chromochunks[5]="$( seq 7 )"
# chromochunks[6]="$( seq 8 )"
# chromochunks[7]="$( seq 6 )"
# chromochunks[8]="$( seq 6 )"
# chromochunks[9]="$( seq 5 )"
# chromochunks[10]="$( seq 6 )"
# chromochunks[11]="$( seq 6 )"
# chromochunks[12]="$( seq 6 )"
# chromochunks[13]="$( seq 4 )"
# chromochunks[14]="$( seq 4 )"
# chromochunks[15]="$( seq 3 )"
# chromochunks[16]="$( seq 3 )"
# chromochunks[17]="$( seq 3 )"
# chromochunks[18]="$( seq 3 )"
# chromochunks[19]="$( seq 2 )"
# chromochunks[20]="$( seq 2 )"
# chromochunks[21]="$( seq 1 )"
# chromochunks[22]="$( seq 1 )"
