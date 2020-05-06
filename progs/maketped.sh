#!/bin/bash

trap 'exit' ERR

BASEDIR="$( cd "$( dirname $0 )" && cd .. && pwd )"

AWK_LOCAL_INCLUDE=$( printf -- '-f %s\n' $( echo ${AWK_INCLUDE} \
    ${BASEDIR}/lib/awk/abs.awk \
    ${BASEDIR}/lib/awk/nucleocode.awk \
    ${BASEDIR}/lib/awk/genotype.awk \
    ${BASEDIR}/lib/awk/gflip.awk \
    ${BASEDIR}/lib/awk/gflipper.awk \
    ${BASEDIR}/lib/awk/gmatch.awk \
    ${BASEDIR}/lib/awk/gmatcher.awk \
    ${BASEDIR}/lib/awk/round.awk \
) | sort -u )

opt_parser="${BASEDIR}/lib/sh/opt_parser.sh"
opt_list=("h" "n=" "v")
get_opt ()
{
    case $1 in
        "h" )
            head="yes" ;;
        "n" )
            nfield=`echo "$2" | sed "s/^=\+//"` ;;
        "v" )
            verbose="yes" ;;
    esac
}
head='no'
nfield=4
verbose='no'
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
dfiles=$( cat ${tmpargs} )
rm -f ${tmpargs}
for dfile in ${dfiles} ; do
    mycat=zcat
    gzip -t ${dfile} 2> /dev/null
    if [[ "$?" == 1 ]] ; then
        mycat=cat
    fi
	${mycat} ${dfile} | awk -F $'\t' $AWK_LOCAL_INCLUDE \
	-v head=${head} \
	-v n=${nfield} \
	--source '{
        OFS = "\t";
        if ( NR == 1 && head == "yes" ) {
            printf( "CHR\tMRK\tCM\tPOS" );
            for ( i = n; i <= NF; i++ ) printf( "\t%s", $i );
        }
        else {
            chr = $1;
            gsub( "[:].+$", "", chr );
            printf( "%s\t%s\t%d\t%d", chr, $1, 0, NR - 1 );
            for ( i = n; i <= NF; i++ ) {
                a1 = roundstd( $i - 1 );
                if ( a1 < 0 ) a1 = 0; \
                a2 = roundstd( $i - a1 );
                mygenotype = a1 + a2;
                if ( mygenotype == 0 ) printf( "\t%s %s", $3, $3 );
                else if ( mygenotype == 1 ) printf( "\t%s %s", $2, $3 );
                else if ( mygenotype == 2 ) printf( "\t%s %s", $2, $2 );
            }
        }
		printf( "\n" );
	}'
done

