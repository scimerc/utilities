#/bin/bash
nucleocoder='/cluster/projects/p33/groups/biostat/software/lib/awk/nucleocode.awk'
opt_parser="/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.sh"
opt_list=("d=" "h=" "m=" "n=" "t" "v")
get_opt ()
{
 case $1 in
  "d" )
     droot=`echo "$2" | sed "s/^=\+//"` ;;
  "h" )
     header=`echo "$2" | sed "s/^=\+//"` ;;
  "m" )
     mfile=`echo "$2" | sed "s/^=\+//"` ;;
  "n" )
     nprob=`echo "$2" | sed "s/^=\+//"` ;;
  "t" )
     fcomp='no' ;;
  "v" )
     verbose='yes' ;;
 esac
}
droot="dosages"
myext=''
cprog='cat'
fcomp='yes'
header=''
headerline='cat'
mfile="gwas.txt"
nprob=1
verbose='no'
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
mylists=$( cat ${tmpargs} )
tmpfile=$( mktemp .tmpXXXX )
if [ "${fcomp}" == "yes" ] ; then
    myext='.gz'
    cprog='zcat'
fi
if [ "${header}" != "" ] ; then
    headerline="paste ${header} -"
fi
if [ "${verbose}" == "yes" ] ; then
    echo -n "locale:  " >&2
    ls -la ${droot}
    locale >&2
fi
if [ "${mylists}" != "" ] ; then
    for snplist in ${mylists} ; do
        if [ "${verbose}" == "yes" ] ; then
            echo "writing risk scores for list '${snplist}'.." >&2
        fi
        loctmpmfile=$(mktemp .tmpXXXX)
        sort -u -k 1,1 ${mfile} | join ${snplist} - > ${loctmpmfile}
        if [ -s ${loctmpmfile} ] ; then
            for dfile in ${droot}/*.dose${myext} ; do
                if [ "${verbose}" == "yes" ] ; then
                    echo "processing file ${dfile}.." >&2
                fi
                ifile=${droot}/$(basename ${dfile} .dose${myext}).info${myext}
                loctmpfile=$(mktemp .tmpXXXX)
                ${cprog} ${ifile} | cat -n | \
                    perl -pe 's/^[ \t]+//g;' | sort -k 2,2 | join -2 2 ${loctmpmfile} - | \
                    gawk -f ${nucleocoder} --source '{ \
                        p = $5; \
                        z = $4; \
                        if ( \
                            nucleocode( $2 ) == nucleocode( $7 ) && nucleocode( $3 ) == nucleocode( $8 ) || \
                            comp_nucleocode( $2 ) == nucleocode( $7 ) && comp_nucleocode( $3 ) == nucleocode( $8 ) \
                        ) print( $6, p, z ); \
                        else if ( \
                            nucleocode( $2 ) == nucleocode( $8 ) && nucleocode( $3 ) == nucleocode( $7 ) || \
                            comp_nucleocode( $2 ) == nucleocode( $8 ) && comp_nucleocode( $3 ) == nucleocode( $7 ) \
                        ) print( $6, p, -z ); \
                    }' | sort -k 1,1n > ${loctmpfile}
                if [ -s ${loctmpfile} ] ; then
                    ${cprog} ${dfile} | gawk -v n=${nprob} '( NR == FNR ) { \
                        zscore[ $1 ] = $3; \
                        pvalue[ $1 ] = $2; \
                        next; \
                    } ( FNR in zscore ) { \
                        printf( "%s\t%s\t%s\t%f\t", $1, $2, $3, pvalue[ FNR ] ); \
                        for ( i = 4; i <= NF; i += n ) { \
                            if ( n == 1 ) printf( "%f\t", $i * zscore[ FNR ] ); \
                            else printf( "%f\t", ( 2*$i + $(i+1) ) * zscore[ FNR ] ); \
                        } \
                        printf( "\n" ); \
                    }' ${loctmpfile} /dev/stdin >> ${tmpfile}
                fi
                rm -f ${loctmpfile}
            done
            rm -f ${loctmpmfile}
        fi
        if [ "${verbose}" == "yes" ] ; then
            echo "computing polygenic risk scores.." >&2
        fi
        gawk '{ \
            if ( NR == 1 ) { \
                N = NF; count = 0; \
                for ( i = 5; i <= N; i++ ) \
                    sum[ i ] = 0; \
            } \
            count++; \
            for ( i = 5; i <= N; i++ ) \
                sum[ i ] += $i; \
        } END{ \
            for ( i = 5; i <= N; i++ ) \
                print( sum[ i ] / count ); \
        }' ${tmpfile} | ${headerline}
    done
else
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) [-d <dosage files root>] [-h <sample IDs>] [-m <GWAS file>]"
    echo -e "                      [-n <number of probabilities>] [-t] <SNP list>"
    echo -e " OPTIONS:"
    echo -e "     -d <dosage files root>    directory where all *.dose and *.info files are located"
    echo -e "                               [default is 'dosages']."
    echo -e "     -h <sample IDs>           include a column with sample IDs in the output"
    echo -e "                               [default no]."
    echo -e "     -m <GWAS file>            file with effect size estimates, with expected format:"
    echo -e "                               <SNP> <A1> <A2> <effect> <p>  -- [<p> is not used]"
    echo -e "                               [default 'gwas.txt']."
    echo -e "     -n <n. of probabilities>  number of genotype/dosage probabilities per sample"
    echo -e "                               [default 1]."
    echo -e "     -t                        expect clear text genotype/dosage files."
    echo -e "                               the script expects gzipped files by default.\n"
fi
rm -f ${tmpfile}
rm -f ${tmpargs}
