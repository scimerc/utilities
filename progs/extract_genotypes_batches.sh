#!/bin/bash
mydatadir='/tsd/p33/data/durable/vault/genetics/imputation'
opt_parser="/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.sh"
opt_list=("alpha" "cbatch=" "o=" "m=" "v")
get_opt ()
{
    case $1 in
        "alpha" )
            alpha="yes" ;;
        "cbatch" )
            cbatch=`echo "$2" | sed "s/^=\+//"` ;;
        "o" )
            outprefix=`echo "$2" | sed "s/^=\+//"` ;;
        "m" )
            mrkfile=`echo "$2" | sed "s/^=\+//"` ;;
        "v" )
            verbose="yes" ;;
    esac
}

batches=( Feb17 Jun16 Jul15 Jan15 Apr16 )
mrkfile=''
outprefix='out'
pnsfile=''
alpha='no'
verbose='no'
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
pnsfile=$( cat ${tmpargs} )
rm -f ${tmpargs}
if [[ "${pnsfile}" != "" && "${mrkfile}" != "" ]] ; then
    batches=( ${cbatch//,/ } )
    allpnsfile=$( mktemp .tmpXXXXXXX )
    for k in ${batches[*]} ; do
        tmpfile=$( mktemp .tmp${k}XXXXXXX )
        dirtmp=${mydatadir}/Imputation_ENIGMA2_protocol_${k}/Imputed/plink
        pnstmp=${mydatadir}/Imputation_ENIGMA2_protocol_${k}/Imputed/NORMENT_${k}.pns
        mydosetmp=${outprefix}_${k}.dose.gz
        mypnstmp=${outprefix}_${k}.pns
        while [[ -e ${mypnstmp} ]] ; do
            echo "warning: output sample file exists; adding suffix 'Z'.."
            mypnstmp=$( basename ${mypnstmp} .pns )Z.pns
        done
        while [[ -e ${mydosetmp} ]] ; do
            echo "warning: output dosage file exists; adding suffix 'Z'.."
            mydosetmp=$( basename ${mydosetmp} .dose.gz )Z.dose.gz
        done
        sort -u ${pnstmp} | join ${pnsfile} - > ${mypnstmp}
        sort -u ${allpnsfile} | join -v1 ${mypnstmp} - > ${tmpfile}
        cat ${tmpfile} >> ${allpnsfile}
        mv ${tmpfile} ${mypnstmp}
        extract_markers.sh -h -d ${dirtmp} ${mrkfile} | gzip -c > ${mydosetmp}
        extract_samples.sh -d ${mydosetmp} -p ${pnstmp} ${mypnstmp} > ${tmpfile}
        if [[ "${alpha}" == "yes" ]] ; then maketped.sh -h ${tmpfile} | gzip -c > ${mydosetmp}
        else gzip -c ${tmpfile} > ${mydosetmp} ; fi
        rm -f ${tmpfile}
    done
    rm ${allpnsfile}
else
    echo -e "\n extract samples and markers from dosage files."
    echo -e " this script is still somewhat hard-coded with respect to filenames and options."
    echo -e " use specialized extract_markers.sh and extract_samples.sh for more options."
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) OPTIONS -m <marker file> <pns file>"
    echo -e "\n     where <pns file> is the required list of samples in alphanumeric order"
    echo -e "     and <marker file> is the required list of markers in alphanumeric order."
    echo -e "\n OPTIONS:"
    echo -e "     -alpha                  translate dosages into alphabetic genotypes;"
    echo -e "     -cbatch <b1,b2,b3...>   comma-separated list of batches (e.g.: Apr16,Jun16);"
    echo -e "     -o <output file>        where to put the extracted dosages [default: 'out']."
    echo
fi
