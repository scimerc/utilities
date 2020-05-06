#!/bin/bash
opt_parser="/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.sh"
opt_list=("alpha" "o=" "d=")
get_opt ()
{
    case $1 in
        "alpha" )
            alpha="yes" ;;
        "d" )
            genodir=`echo "$2" | sed "s/^=\+//"` ;;
        "o" )
            outprefix=`echo "$2" | sed "s/^=\+//"` ;;
    esac
}
emscript='/cluster/projects/p33/groups/biostat/software/progs/extract_markers.sh'
esscript='/cluster/projects/p33/groups/biostat/software/progs/extract_samples.sh'
tpedscript='/cluster/projects/p33/groups/biostat/software/progs/maketped.sh'
tabsed='s/^[ \t]+//g; s/[ \t]+/\t/g;'
mrkfile=''
outprefix='out'
pnsfile=''
alpha='no'
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
myargs=( $( cat ${tmpargs} ) )
pnsfile=${myargs[0]}
mrkfile=${myargs[1]}
rm -f ${tmpargs}
if [[ "${pnsfile}" != "" && "${mrkfile}" != "" ]] ; then
    tmpfile=$( mktemp .tmp${k}XXXXXXX )
    mydosetmp=${outprefix}.dose.gz
    myinfotmp=${outprefix}.info.gz
    mypnstmp=${outprefix}.pns
    ${emscript} -h -d ${genodir} ${mrkfile} | gzip -c > ${mydosetmp}
    ( for ifile in ${genodir}/*.info.gz ; do
        zcat $ifile | head -n 1 ;
    done | sort -u
    join -t $'\t' -1 2 \
        <( zcat ${mydosetmp} | cut -f 1 | cat -n | sed -r "${tabsed}" | sort -k 2,2 ) \
        <( zcat ${genodir}/*.info.gz | sort -u -k 1,1 ) | sort -k 2,2n | cut -f 1,3-
    ) | gzip -c > ${myinfotmp}
    zcat ${mydosetmp} | cut -f 4- | head -n 1 | sed -r 's/\t/\n/g;' | cut -d ' ' -f 1 > ${mypnstmp}
    ${esscript} -d ${mydosetmp} -p ${mypnstmp} ${pnsfile} > ${tmpfile}
    if [[ "${alpha}" == "yes" ]] ; then ${tpedscript} -h ${tmpfile} | gzip -c > ${mydosetmp}
    else gzip -c ${tmpfile} > ${mydosetmp} ; fi
    rm -f ${tmpfile}
else
    echo -e "\n extract samples and markers from dosage files."
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) OPTIONS -d <genotype directory> <pns file> <marker file>"
    echo -e "\n     where <pns file> is the required list of samples in alphanumeric order and"
    echo -e "     <marker file> is the required list of markers in alphanumeric order."
    echo -e "     NOTE: $( basename $0 ) will extract genotypes from all pairs of matching files"
    echo -e "     in the specified <genotype directory> with extensions '.dose.gz' and '.info.gz'."
    echo -e "\n OPTIONS:"
    echo -e "     -alpha                  translate dosages into alphabetic genotypes;"
    echo -e "     -o <output file>        where to put the extracted dosages [default: 'out']."
    echo
fi
