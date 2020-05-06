#!/bin/bash
opt_parser="/cluster/projects/p33/software/lib/sh/opt_parser.sh"
opt_list=("d=" "o=" "p=" "r")
get_opt ()
{
	case $1 in
		"d" )
			dfile=`echo "$2" | sed "s/^=\+//"` ;;
		"p" )
			pnfile=`echo "$2" | sed "s/^=\+//"` ;;
        "r" )
            fcomp="no" ;;
		"o" )
			outfile=`echo "$2" | sed "s/^=\+//"` ;;
	esac
}
dfile=''
myext=''
cprog='cat'
fcomp='yes'
outfile='/dev/stdout'
pnfile=''
verbose='no'
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
mylists=$( cat ${tmpargs} )
rm -f ${tmpargs}
if [[ "${mylists}" != "" && "${dfile}" != "" ]] ; then
    if [ "${fcomp}" == "yes" ] ; then
        cprog='zcat'
        myext='.gz'
    fi
    for pnlist in ${mylists} ; do
        if [[ "${pnfile}" != "" ]] ; then
            mypns=$( cat -n ${pnfile} | perl -p -e 's/^[ \t]+//g; s/[ \t]+/\t/g;' | sort -k 2,2 \
            | join -t $'\t' -1 2 - ${pnlist} | cut -f 2 | sort -n | awk '{ printf(",%d", $1 + 3); }' )
        else
            mypns=$( ${cprog} ${dfile} | head -n 1 | cut -f 4- | perl -p -e 's/\t/\n/g;' | cut -d ' ' -f 1 | cat -n \
            | perl -p -e 's/^[ \t]+//g; s/[ \t]+/\t/g;' | sort -k 2,2 | join -t $'\t' -1 2 - ${pnlist} | cut -f 2 \
            | sort -n | awk '{ printf(",%d", $1 + 3); }' )
        fi
        ${cprog} ${dfile} | cut -f 1,2,3${mypns} > ${outfile}
    done
else
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) OPTIONS -d <dosage file> <pn lists>"
    echo -e "\n     where <pn lists> are the required lists of samples in alphanumeric order."
    echo -e "\n OPTIONS:"
    echo -e "     -d <dosage file>      dosage file in variant-major format (obligatory option);"
    echo -e "     -o <output file>      where to put the extracted dosages [default: /dev/stdout];"
    echo -e "     -p <pn file>          list of IDs, in the order they appear, in the dosage file:"
    echo -e "                           this must be provided if the dosage file has no header;"
    echo -e "     -r                    expect human readable text file [default: gzip]."
    echo
fi
