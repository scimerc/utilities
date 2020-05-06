#!/bin/bash
opt_parser="/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.sh"
opt_list=("d=" "h" "r" "t" "v")
get_opt ()
{
	case $1 in
		"d" )
			ddir=`echo "$2" | sed "s/^=\+//"` ;;
		"h" )
			header="yes" ;;
        "r" )
            fcomp="no" ;;
		"t" )
			transpose="yes" ;;
		"v" )
			verbose="yes" ;;
	esac
}
ddir='.'
myext=''
cprog='cat'
fcomp='yes'
header='no'
transpose='no'
verbose='no'
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
mylists=$( cat ${tmpargs} )
rm -f ${tmpargs}
if [[ "${fcomp}" == "yes" ]] ; then
    cprog='zcat'
    myext='.gz'
fi
if [[ "${mylists}" != "" && "${ddir}" != "" ]] ; then
    mytmpfile=$( mktemp .tmpXXXXXXXX )
    if [[ "${transpose}" == "yes" ]] ; then
        if [[ "${verbose}" == "yes" ]] ; then
            echo 'transposing to sample-major format..'
        fi
        (
            if [[ "${header}" == "yes" ]] ; then
                echo -e -n "ID ID0\t"
                ( for dfile in ${ddir}/*.dose${myext} ; do
                    ${cprog} ${dfile} | head -n 1
                done ) | sort -u | cut -f 4-
            fi
            ( for slist in ${mylists} ; do
                if [[ "${verbose}" == "yes" ]] ; then
                    echo "extracting variants from '${slist}'.."
                fi
                for dfile in ${ddir}/*.dose${myext} ; do
                    ifile="${ddir}/$(basename $dfile .dose${myext}).info${myext}"
                    if [[ "${verbose}" == "yes" ]] ; then
                        echo "processing dosage info file '${ifile}'.."
                    fi
                    if [[ -f ${ifile} ]] ; then
                        if [[ "${verbose}" == "yes" ]] ; then
                            echo "extracting dosages from file '${dfile}'.."
                        fi
                        ${cprog} ${ifile} | cat -n | sort -k 2,2 | join -2 2 ${slist} - \
                            | sort -u > ${mytmpfile}_$(basename ${slist}).info
                        if [[ -s ${mytmpfile}_$(basename ${slist}).info ]] ; then
                            if [[ "${verbose}" == "yes" ]] ; then
                                echo "extracting dosages from ${dfile}.."
                            fi
                            ${cprog} ${dfile} | gawk ' \
                                ( NR == FNR ) { \
                                    filter[ $2 ] = 1; \
                                    next; \
                                }
                                ( NR != FNR && FNR in filter ) { \
                                    printf( "%s(%s/%s)", $1, $2, $3 ); \
                                    for ( i = 4; i <= NF; i++ ) printf( "\t%f", $i ); \
                                    printf( "\n" ); \
                                }' ${mytmpfile}_$(basename ${slist}).info /dev/stdin
                        fi
                    fi
                done
            done ) | sort -u -k 1,1
        ) | transpose.perl
    elif [[ "${transpose}" == "no" ]] ; then
        if [[ "${header}" == "yes" ]] ; then
            echo -e -n "MARKER\tA1\tA2\t"
            ( for dfile in ${ddir}/*.dose${myext} ; do
                ${cprog} ${dfile} | head -n 1
            done ) | sort -u | cut -f 4-
        fi
        for slist in ${mylists} ; do
            for dfile in ${ddir}/*.dose${myext} ; do
                ifile="${ddir}/$(basename $dfile .dose${myext}).info${myext}"
                if [[ -f ${ifile} ]] ; then
                    ${cprog} ${ifile} | cat -n | sort -k 2,2 | join -2 2 ${slist} - | sort -u \
                        > ${mytmpfile}_$(basename ${slist}).info
                    if [[ -s ${mytmpfile}_$(basename ${slist}).info ]] ; then
                        ${cprog} ${dfile} | gawk ' \
                            ( NR == FNR ) { filter[ $2 ] = 1; next; }
                            ( NR != FNR && FNR in filter )
                        ' ${mytmpfile}_$(basename ${slist}).info /dev/stdin
                    fi
                fi
            done
        done
    fi
    for mfile in ${mytmpfile}* ; do
        rm ${mfile}
    done
else
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) -d <dosage directory> [-h] [-r] [-t] [-v] <marker lists>\n"
    echo -e "     where <dosage directory> is the directory where all *.dose and *.info files are"
    echo -e "     and <marker lists> is the list of markers to extract, in alphanumeric order."
    echo -e "\n OPTIONS:"
    echo -e "     -h                        include header in output: the header is extracted from"
    echo -e "                               all dosage files as these are expected to contain"
    echo -e "                               dosages for the same samples; more header lines will be"
    echo -e "                               written if this isn't the case [default no header];"
    echo -e "     -r                        expect human readable text file;"
    echo -e "                               [default gzipped archive expected];"
    echo -e "     -t                        transpose output into sample major;"
    echo -e "                               [default no transpose]."
    echo -e "     -v                        verbose mode on."
    echo
fi

